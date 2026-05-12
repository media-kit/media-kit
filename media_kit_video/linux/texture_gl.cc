// This file is a part of media_kit
// (https://github.com/media-kit/media-kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

// The file is moded for the purpose of triple buffering using mailbox model.
// Copyright © 2025 Predidit
// All rights reserved.

#include "include/media_kit_video/texture_gl.h"
#include "include/media_kit_video/gl_render_thread.h"

#include <epoxy/gl.h>
#include <epoxy/egl.h>
#include <atomic>

// Number of buffers for mailbox triple buffering
#define NUM_BUFFERS 3

// Buffer structure for mailbox triple buffering
// Each buffer has its own GPU resources
typedef struct {
  guint32 fbo;              // FBO for mpv rendering
  guint32 texture;          // Texture attached to FBO (mpv side)
  EGLImageKHR egl_image;    // EGLImage for sharing between contexts
  guint32 flutter_texture;  // Flutter's texture bound to EGLImage
  gboolean flutter_texture_valid;  // Whether Flutter texture is valid
  std::atomic<EGLSyncKHR> render_sync;  // Sync created after mpv render (atomic for cross-thread access)
} RenderBuffer;

/**
 * Mailbox Triple Buffering Model with Drain-Only Consumer:
 * 
 * Three buffers with fixed roles that rotate via atomic pointer swaps:
 * - back:    Producer (GL thread) renders to this buffer
 * - mailbox: Holds the latest complete frame with dirty flag
 * - front:   Consumer (Flutter main thread) reads from this buffer
 * 
 * Key design: mailbox_state combines index and dirty flag in ONE atomic:
 *   mailbox_state = (dirty << 8) | index
 * This eliminates race conditions between checking dirty and swapping.
 * 
 * Producer workflow (GL thread):
 *   1. Render frame to back buffer
 *   2. Atomic exchange: put (dirty=1, back_index) into mailbox, get old index
 *   3. Old mailbox index becomes new back buffer
 * 
 * Consumer workflow (Flutter main thread) - DRAIN-ONLY:
 *   1. Atomic CAS: if dirty=1, swap (dirty=0, front_index) with mailbox
 *   2. If CAS succeeds: got new frame, update front_index
 *   3. If dirty=0: no new frame, keep current front buffer
 *   4. Display front buffer
 * 
 * Drain-only semantics ensures:
 * - Consumer only swaps when mailbox has NEW content (dirty=1)
 * - Consumer never puts its displayed frame back unless getting new one
 * - Producer can always safely overwrite mailbox content
 * - Single atomic operation prevents dirty/index race condition
 */
struct _TextureGL {
  FlTextureGL parent_instance;
  
  // The three buffers for mailbox model
  RenderBuffer buffers[NUM_BUFFERS];
  
  // Mailbox model: atomic indices for lock-free buffer swapping
  // Producer (GL thread) owns back_index exclusively
  // Consumer (main thread) owns front_index exclusively
  // mailbox uses a combined atomic to avoid race between index and dirty flag
  int back_index;                      // Producer's current buffer (GL thread only)
  int front_index;                     // Consumer's current buffer (main thread only)
  // Combined mailbox state: index in lower bits, dirty flag in upper bit
  // This ensures atomic swap of both index and dirty flag together
  // Encoding: (dirty << 8) | index, where dirty is 0 or 1, index is 0-2
  std::atomic<int> mailbox_state;      // Combined: dirty flag (bit 8) + buffer index (bits 0-7)
  
  guint32 current_width;
  guint32 current_height;
  gboolean buffers_initialized;
  gboolean initialization_posted;
  std::atomic<gboolean> resizing;      // Flag to indicate resize in progress
  
  VideoOutput* video_output;
};

G_DEFINE_TYPE(TextureGL, texture_gl, fl_texture_gl_get_type())

static void texture_gl_init(TextureGL* self) {
  for (int i = 0; i < NUM_BUFFERS; i++) {
    self->buffers[i].fbo = 0;
    self->buffers[i].texture = 0;
    self->buffers[i].egl_image = EGL_NO_IMAGE_KHR;
    self->buffers[i].flutter_texture = 0;
    self->buffers[i].flutter_texture_valid = FALSE;
    self->buffers[i].render_sync.store(EGL_NO_SYNC_KHR, std::memory_order_relaxed);
  }
  
  // Initialize mailbox model indices
  // back=0 for producer, front=1 for consumer, mailbox=2 initially (not dirty)
  self->back_index = 0;
  self->front_index = 1;
  // mailbox_state = (dirty << 8) | index = (0 << 8) | 2 = 2
  self->mailbox_state.store(2, std::memory_order_relaxed);
  
  self->current_width = 1;
  self->current_height = 1;
  self->buffers_initialized = FALSE;
  self->initialization_posted = FALSE;
  self->resizing.store(FALSE, std::memory_order_relaxed);
  self->video_output = NULL;
}

static void texture_gl_dispose(GObject* object) {
  TextureGL* self = TEXTURE_GL(object);
  VideoOutput* video_output = self->video_output;
  GLRenderThread* gl_thread = video_output_get_gl_render_thread(video_output);
  
  // Clean up Flutter's textures (main thread)
  for (int i = 0; i < NUM_BUFFERS; i++) {
    if (self->buffers[i].flutter_texture != 0) {
      glDeleteTextures(1, &self->buffers[i].flutter_texture);
      self->buffers[i].flutter_texture = 0;
    }
  }
  
  // Clean up GPU resources in dedicated GL thread
  if (video_output != NULL && gl_thread != NULL) {
    gl_thread->PostAndWait([self, video_output]() {
      EGLDisplay egl_display = video_output_get_egl_display(video_output);
      EGLContext egl_context = video_output_get_egl_context(video_output);
      
      // Clean up all buffers
      for (int i = 0; i < NUM_BUFFERS; i++) {
        RenderBuffer* buf = &self->buffers[i];
        
        // Clean up EGLSyncKHR
        EGLSyncKHR sync = buf->render_sync.load(std::memory_order_acquire);
        if (sync != EGL_NO_SYNC_KHR) {
          eglDestroySyncKHR(egl_display, sync);
          buf->render_sync.store(EGL_NO_SYNC_KHR, std::memory_order_release);
        }
        
        // Clean up EGLImage
        if (buf->egl_image != EGL_NO_IMAGE_KHR) {
          eglDestroyImageKHR(egl_display, buf->egl_image);
          buf->egl_image = EGL_NO_IMAGE_KHR;
        }
      }
      
      // Clean up mpv's OpenGL resources (in mpv's isolated context)
      if (egl_context != EGL_NO_CONTEXT) {
        eglMakeCurrent(egl_display, EGL_NO_SURFACE, EGL_NO_SURFACE, egl_context);
        
        for (int i = 0; i < NUM_BUFFERS; i++) {
          RenderBuffer* buf = &self->buffers[i];
          
          if (buf->texture != 0) {
            glDeleteTextures(1, &buf->texture);
            buf->texture = 0;
          }
          if (buf->fbo != 0) {
            glDeleteFramebuffers(1, &buf->fbo);
            buf->fbo = 0;
          }
        }
      }
    });
  }
  
  self->current_width = 1;
  self->current_height = 1;
  self->video_output = NULL;
  G_OBJECT_CLASS(texture_gl_parent_class)->dispose(object);
}

static void texture_gl_class_init(TextureGLClass* klass) {
  FL_TEXTURE_GL_CLASS(klass)->populate = texture_gl_populate_texture;
  G_OBJECT_CLASS(klass)->dispose = texture_gl_dispose;
}

TextureGL* texture_gl_new(VideoOutput* video_output) {
  TextureGL* self = TEXTURE_GL(g_object_new(texture_gl_get_type(), NULL));
  self->video_output = video_output;
  return self;
}

/**
 * Called from the dedicated GL rendering thread.
 * Creates or resizes all three buffers for the mailbox model.
 */
void texture_gl_check_and_resize(TextureGL* self, gint64 required_width, gint64 required_height) {
  VideoOutput* video_output = self->video_output;
  
  if (required_width < 1 || required_height < 1) {
    return;
  }
  
  gboolean first_frame = !self->buffers_initialized;
  gboolean resize = self->current_width != (guint32)required_width ||
                    self->current_height != (guint32)required_height;
  
  if (!first_frame && !resize) {
    return;
  }
  
  EGLDisplay egl_display = video_output_get_egl_display(video_output);
  EGLContext egl_context = video_output_get_egl_context(video_output);
  
  // Switch to mpv's isolated context
  eglMakeCurrent(egl_display, EGL_NO_SURFACE, EGL_NO_SURFACE, egl_context);
  
  // Mark as resizing to prevent consumer from accessing buffers
  self->resizing.store(TRUE, std::memory_order_release);
  
  // Free previous resources for all buffers
  for (int i = 0; i < NUM_BUFFERS; i++) {
    RenderBuffer* buf = &self->buffers[i];
    
    if (!first_frame) {
      // Wait for any pending GPU work before destroying resources
      EGLSyncKHR sync = buf->render_sync.load(std::memory_order_acquire);
      if (sync != EGL_NO_SYNC_KHR) {
        eglClientWaitSyncKHR(egl_display, sync, 
                              EGL_SYNC_FLUSH_COMMANDS_BIT_KHR, EGL_FOREVER_KHR);
        eglDestroySyncKHR(egl_display, sync);
        buf->render_sync.store(EGL_NO_SYNC_KHR, std::memory_order_release);
      }
      
      if (buf->egl_image != EGL_NO_IMAGE_KHR) {
        eglDestroyImageKHR(egl_display, buf->egl_image);
        buf->egl_image = EGL_NO_IMAGE_KHR;
      }
      
      glDeleteTextures(1, &buf->texture);
      glDeleteFramebuffers(1, &buf->fbo);
    }
    
    // Create FBO and texture for this buffer
    glGenFramebuffers(1, &buf->fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, buf->fbo);
    
    glGenTextures(1, &buf->texture);
    glBindTexture(GL_TEXTURE_2D, buf->texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, required_width, required_height,
                 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    
    // Attach texture to FBO
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                           GL_TEXTURE_2D, buf->texture, 0);
    
    // Create EGLImage from texture for sharing between contexts
    EGLint egl_image_attribs[] = { EGL_NONE };
    buf->egl_image = eglCreateImageKHR(
        egl_display,
        egl_context,
        EGL_GL_TEXTURE_2D_KHR,
        (EGLClientBuffer)(guintptr)buf->texture,
        egl_image_attribs);
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    // Mark Flutter texture as invalid (needs recreation)
    buf->flutter_texture_valid = FALSE;
    buf->render_sync.store(EGL_NO_SYNC_KHR, std::memory_order_release);
  }
  
  // Flush to ensure textures are ready
  glFlush();
  
  // Reset mailbox model indices
  self->back_index = 0;
  self->front_index = 1;
  // mailbox_state = (dirty << 8) | index = (0 << 8) | 2 = 2
  self->mailbox_state.store(2, std::memory_order_release);
  
  // Mark buffers as initialized and update dimensions
  self->buffers_initialized = TRUE;
  self->current_width = required_width;
  self->current_height = required_height;
  
  self->resizing.store(FALSE, std::memory_order_release);
}

/**
 * Renders mpv frame to the back buffer.
 * Called from the dedicated GL rendering thread.
 */
gboolean texture_gl_render(TextureGL* self) {
  VideoOutput* video_output = self->video_output;
  EGLDisplay egl_display = video_output_get_egl_display(video_output);
  EGLContext egl_context = video_output_get_egl_context(video_output);
  mpv_render_context* render_context = video_output_get_render_context(video_output);
  
  if (!render_context || !self->buffers_initialized) {
    return FALSE;
  }
  
  // Get the back buffer (producer's exclusive buffer)
  int back_idx = self->back_index;
  RenderBuffer* back_buf = &self->buffers[back_idx];
  
  if (back_buf->fbo == 0) {
    return FALSE;
  }
  
  // Before reusing this buffer, wait for any previous render to complete
  // This ensures GPU has finished with this buffer before we overwrite it
  EGLSyncKHR old_sync = back_buf->render_sync.exchange(EGL_NO_SYNC_KHR, std::memory_order_acq_rel);
  if (old_sync != EGL_NO_SYNC_KHR) {
    // Wait for previous GPU work to complete, then destroy the sync
    eglClientWaitSyncKHR(egl_display, old_sync, EGL_SYNC_FLUSH_COMMANDS_BIT_KHR, EGL_FOREVER_KHR);
    eglDestroySyncKHR(egl_display, old_sync);
  }
  
  gint32 required_width = self->current_width;
  gint32 required_height = self->current_height;
  
  // Switch to mpv's isolated context for rendering
  eglMakeCurrent(egl_display, EGL_NO_SURFACE, EGL_NO_SURFACE, egl_context);
  
  // Bind back buffer's FBO
  glBindFramebuffer(GL_FRAMEBUFFER, back_buf->fbo);
  
  // Render mpv frame to back buffer's texture
  mpv_opengl_fbo fbo{(gint32)back_buf->fbo, required_width, required_height, 0};
  int flip_y = 0;
  mpv_render_param params[] = {
      {MPV_RENDER_PARAM_OPENGL_FBO, &fbo},
      {MPV_RENDER_PARAM_FLIP_Y, &flip_y},
      {MPV_RENDER_PARAM_INVALID, NULL},
  };
  mpv_render_context_render(render_context, params);
  
  // Unbind FBO
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  
  // Flush to ensure rendering commands are submitted to GPU
  glFlush();
  
  // Create sync fence to mark render completion
  // Consumer will use this for GPU-side synchronization
  EGLSyncKHR new_sync = eglCreateSyncKHR(egl_display, EGL_SYNC_FENCE_KHR, NULL);
  back_buf->render_sync.store(new_sync, std::memory_order_release);
  
  return TRUE;
}

/**
 * Publishes the rendered frame using mailbox swap.
 * Atomically swaps back buffer with mailbox and sets dirty flag in ONE operation.
 * Called from dedicated GL thread after render finishes.
 */
void texture_gl_swap_buffers(TextureGL* self) {
  // Atomic swap with dirty flag set:
  // We put our back_index into mailbox with dirty=1
  // We get back the old mailbox index (ignore its dirty flag)
  int new_state = (1 << 8) | self->back_index;  // dirty=1, index=back_index
  int old_state = self->mailbox_state.exchange(new_state, std::memory_order_acq_rel);
  // Extract just the index from old state (ignore dirty flag)
  self->back_index = old_state & 0xFF;
}

/**
 * Populates texture with video frame using mailbox model.
 * Called from Flutter's main thread.
 */
gboolean texture_gl_populate_texture(FlTextureGL* texture,
                                     guint32* target,
                                     guint32* name,
                                     guint32* width,
                                     guint32* height,
                                     GError** error) {
  TextureGL* self = TEXTURE_GL(texture);
  VideoOutput* video_output = self->video_output;
  GLRenderThread* gl_thread = video_output_get_gl_render_thread(video_output);
  EGLDisplay egl_display = video_output_get_egl_display(video_output);
  
  // Trigger initialization on first call
  if (!self->initialization_posted && !self->buffers_initialized) {
    gint64 required_width = video_output_get_width(video_output);
    gint64 required_height = video_output_get_height(video_output);
    
    if (required_width > 0 && required_height > 0 && gl_thread) {
      self->initialization_posted = TRUE;
      video_output_notify_render(video_output);
    }
  }
  
  // If resize is in progress, return dummy texture
  if (self->resizing.load(std::memory_order_acquire)) {
    *target = GL_TEXTURE_2D;
    static guint32 dummy_texture = 0;
    if (dummy_texture == 0) {
      glGenTextures(1, &dummy_texture);
      glBindTexture(GL_TEXTURE_2D, dummy_texture);
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
      glBindTexture(GL_TEXTURE_2D, 0);
    }
    *name = dummy_texture;
    *width = 1;
    *height = 1;
    return TRUE;
  }
  
  // Drain-only consumer: only swap if mailbox has new content (dirty flag set)
  // Use CAS loop to atomically check dirty and swap in one operation
  int current_state = self->mailbox_state.load(std::memory_order_acquire);
  while (current_state & 0x100) {  // Check dirty flag (bit 8)
    // Mailbox has new frame - try to swap
    // New state: dirty=0, index=our front_index
    int new_state = self->front_index;  // dirty=0, index=front_index
    if (self->mailbox_state.compare_exchange_weak(current_state, new_state,
                                                   std::memory_order_acq_rel,
                                                   std::memory_order_acquire)) {
      // Swap succeeded - extract the index we got
      self->front_index = current_state & 0xFF;
      break;
    }
    // CAS failed, current_state has been updated, retry
  }
  // If dirty was not set, we keep using current front buffer
  
  // front_index points to the frame we should display
  int front_idx = self->front_index;
  RenderBuffer* front_buf = &self->buffers[front_idx];
  
  // GPU synchronization: ensure producer's rendering is complete before we use the texture
  // Take ownership of the sync object atomically
  EGLSyncKHR sync = front_buf->render_sync.exchange(EGL_NO_SYNC_KHR, std::memory_order_acq_rel);
  if (sync != EGL_NO_SYNC_KHR) {
    // Use GPU-side wait for better performance (doesn't block CPU)
    // This inserts a wait into Flutter's GL command stream
    if (epoxy_has_egl_extension(egl_display, "EGL_KHR_wait_sync")) {
      eglWaitSyncKHR(egl_display, sync, 0);
    } else {
      // Fallback to CPU wait if eglWaitSyncKHR not available
      eglClientWaitSyncKHR(egl_display, sync, EGL_SYNC_FLUSH_COMMANDS_BIT_KHR, EGL_FOREVER_KHR);
    }
    // Destroy the sync after use (we own it now)
    eglDestroySyncKHR(egl_display, sync);
  }
  
  // Check if we need to create/recreate Flutter texture for this buffer
  if (!front_buf->flutter_texture_valid && front_buf->egl_image != EGL_NO_IMAGE_KHR) {
    // Delete old texture if exists
    if (front_buf->flutter_texture != 0) {
      glDeleteTextures(1, &front_buf->flutter_texture);
    }
    
    // Create Flutter's texture from this buffer's EGLImage
    glGenTextures(1, &front_buf->flutter_texture);
    glBindTexture(GL_TEXTURE_2D, front_buf->flutter_texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glEGLImageTargetTexture2DOES(GL_TEXTURE_2D, front_buf->egl_image);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    front_buf->flutter_texture_valid = TRUE;
    
    // Notify Flutter about texture availability
    video_output_notify_texture_update(video_output);
  }
  
  *target = GL_TEXTURE_2D;
  *name = front_buf->flutter_texture;
  *width = self->current_width;
  *height = self->current_height;
  
  // If texture is not valid yet, return dummy texture
  if (!front_buf->flutter_texture_valid || front_buf->flutter_texture == 0) {
    static guint32 dummy_texture = 0;
    if (dummy_texture == 0) {
      glGenTextures(1, &dummy_texture);
      glBindTexture(GL_TEXTURE_2D, dummy_texture);
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
      glBindTexture(GL_TEXTURE_2D, 0);
    }
    *name = dummy_texture;
    *width = 1;
    *height = 1;
  }
  
  return TRUE;
}
