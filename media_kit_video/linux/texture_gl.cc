// This file is a part of media_kit
// (https://github.com/media-kit/media-kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#include "include/media_kit_video/texture_gl.h"
#include "include/media_kit_video/thread_pool.h"

#include <epoxy/gl.h>
#include <epoxy/egl.h>

// EGLImage extension function pointers
typedef EGLImageKHR (*PFNEGLCREATEIMAGEKHRPROC)(EGLDisplay dpy, EGLContext ctx, EGLenum target, EGLClientBuffer buffer, const EGLint *attrib_list);
typedef EGLBoolean (*PFNEGLDESTROYIMAGEKHRPROC)(EGLDisplay dpy, EGLImageKHR image);
typedef void (*PFNGLEGLIMAGETARGETTEXTURE2DOESPROC)(GLenum target, GLeglImageOES image);

// Define the extension functions
#ifndef eglCreateImageKHR
static PFNEGLCREATEIMAGEKHRPROC eglCreateImageKHR = NULL;
#endif
#ifndef eglDestroyImageKHR
static PFNEGLDESTROYIMAGEKHRPROC eglDestroyImageKHR = NULL;
#endif
#ifndef glEGLImageTargetTexture2DOES
static PFNGLEGLIMAGETARGETTEXTURE2DOESPROC glEGLImageTargetTexture2DOES = NULL;
#endif

static void init_egl_image_extensions() {
  static gboolean initialized = FALSE;
  if (!initialized) {
    eglCreateImageKHR = (PFNEGLCREATEIMAGEKHRPROC)eglGetProcAddress("eglCreateImageKHR");
    eglDestroyImageKHR = (PFNEGLDESTROYIMAGEKHRPROC)eglGetProcAddress("eglDestroyImageKHR");
    glEGLImageTargetTexture2DOES = (PFNGLEGLIMAGETARGETTEXTURE2DOESPROC)eglGetProcAddress("glEGLImageTargetTexture2DOES");
    initialized = TRUE;
  }
}

struct _TextureGL {
  FlTextureGL parent_instance;
  guint32 name;              // Flutter's texture name
  guint32 fbo;               // mpv's FBO
  guint32 mpv_texture;       // mpv's texture
  EGLImageKHR egl_image;     // EGLImage for sharing between contexts
  guint32 current_width;
  guint32 current_height;
  gboolean needs_texture_update;  // Flag to update Flutter texture
  gboolean initialization_posted;  // Flag to avoid duplicate initialization
  VideoOutput* video_output;
};

G_DEFINE_TYPE(TextureGL, texture_gl, fl_texture_gl_get_type())

static void texture_gl_init(TextureGL* self) {
  self->name = 0;
  self->fbo = 0;
  self->mpv_texture = 0;
  self->egl_image = EGL_NO_IMAGE_KHR;
  self->current_width = 1;
  self->current_height = 1;
  self->needs_texture_update = FALSE;
  self->initialization_posted = FALSE;
  self->video_output = NULL;
}

static void texture_gl_dispose(GObject* object) {
  TextureGL* self = TEXTURE_GL(object);
  
  VideoOutput* video_output = self->video_output;
  
  g_print("[TextureGL %p] Disposing: name=%u, mpv_texture=%u, fbo=%u, egl_image=%p\n",
          self, self->name, self->mpv_texture, self->fbo, self->egl_image);
  
  // Handle early dispose (video_output may be NULL)
  if (video_output == NULL) {
    g_printerr("[TextureGL %p] WARNING: Disposed before video_output was set\n", self);
    G_OBJECT_CLASS(texture_gl_parent_class)->dispose(object);
    return;
  }
  
  ThreadPool* thread_pool = video_output_get_thread_pool(video_output);
  
  // Clean up Flutter's texture (in Flutter's context)
  if (self->name != 0) {
    g_print("[TextureGL %p] Deleting Flutter texture %u\n", self, self->name);
    glDeleteTextures(1, &self->name);
    self->name = 0;
  }
  
  // Clean up EGLImage and mpv's OpenGL resources in dedicated thread
  // video_output_dispose ensures EGL context is still valid when this runs
  if (thread_pool != NULL) {
    // Capture everything by value to avoid dangling pointers
    EGLDisplay egl_display = video_output_get_egl_display(video_output);
    EGLContext egl_context = video_output_get_egl_context(video_output);
    EGLImageKHR egl_image = self->egl_image;
    guint32 mpv_texture = self->mpv_texture;
    guint32 fbo = self->fbo;
    void* self_ptr = self;  // For logging only
    
    auto future = thread_pool->Post([self_ptr, egl_display, egl_context, egl_image, mpv_texture, fbo]() {
      // Clean up in correct order to prevent leaks
      if (egl_context == EGL_NO_CONTEXT || egl_display == EGL_NO_DISPLAY) {
        g_printerr("[TextureGL %p] ERROR: EGL context already destroyed, resources leaked\n", self_ptr);
        return;
      }
      
      if (!eglMakeCurrent(egl_display, EGL_NO_SURFACE, EGL_NO_SURFACE, egl_context)) {
        g_printerr("[TextureGL %p] ERROR: Failed to make EGL context current (error: 0x%x) - resources leaked\n", 
                   self_ptr, eglGetError());
        return;
      }
      
      // 1. First destroy EGLImage (it references the texture)
      if (egl_image != EGL_NO_IMAGE_KHR) {
        eglDestroyImageKHR(egl_display, egl_image);
      }
      
      // 2. Then delete GL texture and FBO
      if (mpv_texture != 0) {
        glDeleteTextures(1, &mpv_texture);
      }
      if (fbo != 0) {
        glDeleteFramebuffers(1, &fbo);
      }
      
      // 3. Flush to ensure cleanup is complete
      glFlush();
      
      g_print("[TextureGL %p] Cleaned mpv resources in thread pool\n", self_ptr);
    });
    future.wait();
    
    g_print("[TextureGL %p] mpv resources cleanup completed\n", self);
    
    // Clear after cleanup
    self->egl_image = EGL_NO_IMAGE_KHR;
    self->mpv_texture = 0;
    self->fbo = 0;
  } else {
    g_printerr("[TextureGL %p] WARNING: thread_pool is NULL, cannot cleanup GL resources\n", self);
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
  init_egl_image_extensions();
  TextureGL* self = TEXTURE_GL(g_object_new(texture_gl_get_type(), NULL));
  self->video_output = video_output;
  return self;
}

void texture_gl_check_and_resize(TextureGL* self, gint64 required_width, gint64 required_height) {
  VideoOutput* video_output = self->video_output;
  
  if (required_width < 1 || required_height < 1) {
    return;
  }
  
  // Only check mpv-owned resources (fbo, mpv_texture) for first_frame detection
  // self->name is created in Flutter's context and shouldn't be used here
  gboolean first_frame = self->fbo == 0 || self->mpv_texture == 0;
  gboolean resize = self->current_width != required_width ||
                    self->current_height != required_height;
  
  if (!first_frame && !resize) {
    return;  // No resize needed
  }
  
  EGLDisplay egl_display = video_output_get_egl_display(video_output);
  EGLContext egl_context = video_output_get_egl_context(video_output);
  
  if (egl_display == EGL_NO_DISPLAY || egl_context == EGL_NO_CONTEXT) {
    g_printerr("[TextureGL %p] ERROR: Invalid EGL display/context during resize\n", self);
    return;
  }
  
  // This function is called from the dedicated rendering thread
  // So we can directly perform OpenGL operations (no need to Post)
  
  // Switch to mpv's isolated context
  if (!eglMakeCurrent(egl_display, EGL_NO_SURFACE, EGL_NO_SURFACE, egl_context)) {
    g_printerr("[TextureGL %p] ERROR: Failed to make EGL context current (error: 0x%x)\n", 
               self, eglGetError());
    return;
  }
  
  // Free previous resources in mpv's context BEFORE creating new ones
  if (!first_frame) {
    g_print("[TextureGL %p] Resize detected, cleaning old resources (egl_image=%p, mpv_texture=%u, fbo=%u)\n",
            self, self->egl_image, self->mpv_texture, self->fbo);
    
    // Clean up in correct order to prevent leaks
    // First destroy EGLImage (it references the texture)
    if (self->egl_image != EGL_NO_IMAGE_KHR) {
      eglDestroyImageKHR(egl_display, self->egl_image);
      self->egl_image = EGL_NO_IMAGE_KHR;
    }
    // Then delete GL texture and FBO
    if (self->mpv_texture != 0) {
      glDeleteTextures(1, &self->mpv_texture);
      self->mpv_texture = 0;
    }
    if (self->fbo != 0) {
      glDeleteFramebuffers(1, &self->fbo);
      self->fbo = 0;
    }
    
    g_print("[TextureGL %p] Old resources cleaned\n", self);
  }
  
  // Create mpv's FBO and texture
  glGenFramebuffers(1, &self->fbo);
  glBindFramebuffer(GL_FRAMEBUFFER, self->fbo);
  
  glGenTextures(1, &self->mpv_texture);
  glBindTexture(GL_TEXTURE_2D, self->mpv_texture);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, required_width, required_height,
               0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
  
  // Attach mpv's texture to FBO
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                         GL_TEXTURE_2D, self->mpv_texture, 0);
  
  // Create EGLImage from mpv's texture
  EGLint egl_image_attribs[] = { EGL_NONE };
  self->egl_image = eglCreateImageKHR(
      egl_display,
      egl_context,
      EGL_GL_TEXTURE_2D_KHR,
      (EGLClientBuffer)(guintptr)self->mpv_texture,
      egl_image_attribs);
  
  if (self->egl_image == EGL_NO_IMAGE_KHR) {
    g_printerr("[TextureGL %p] ERROR: Failed to create EGLImage (error: 0x%x)\n", 
               self, eglGetError());
  } else {
    g_print("[TextureGL %p] Created resources: egl_image=%p, mpv_texture=%u, fbo=%u, size=%ldx%ld\n",
            self, self->egl_image, self->mpv_texture, self->fbo, required_width, required_height);
  }
  
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  glBindTexture(GL_TEXTURE_2D, 0);
  
  // Mark that Flutter texture needs update
  self->current_width = required_width;
  self->current_height = required_height;
  self->needs_texture_update = TRUE;
  
  // Flush to ensure all GL commands are executed (resource creation/deletion)
  glFlush();
}

void texture_gl_render(TextureGL* self) {
  VideoOutput* video_output = self->video_output;
  EGLDisplay egl_display = video_output_get_egl_display(video_output);
  EGLContext egl_context = video_output_get_egl_context(video_output);
  mpv_render_context* render_context = video_output_get_render_context(video_output);
  
  if (!render_context || self->fbo == 0) {
    return;
  }
  
  gint32 required_width = self->current_width;
  gint32 required_height = self->current_height;
  
  // Switch to mpv's isolated context for rendering
  eglMakeCurrent(egl_display, EGL_NO_SURFACE, EGL_NO_SURFACE, egl_context);
  
  // Bind mpv's FBO
  glBindFramebuffer(GL_FRAMEBUFFER, self->fbo);
  
  // Render mpv frame to mpv's texture
  mpv_opengl_fbo fbo{(gint32)self->fbo, required_width, required_height, 0};
  int flip_y = 0;
  mpv_render_param params[] = {
      {MPV_RENDER_PARAM_OPENGL_FBO, &fbo},
      {MPV_RENDER_PARAM_FLIP_Y, &flip_y},
      {MPV_RENDER_PARAM_INVALID, NULL},
  };
  mpv_render_context_render(render_context, params);
  
  // Unbind FBO
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  
  // Flush to ensure rendering is complete
  glFlush();
}

gboolean texture_gl_populate_texture(FlTextureGL* texture,
                                     guint32* target,
                                     guint32* name,
                                     guint32* width,
                                     guint32* height,
                                     GError** error) {
  TextureGL* self = TEXTURE_GL(texture);
  VideoOutput* video_output = self->video_output;
  ThreadPool* thread_pool = video_output_get_thread_pool(video_output);
  
  // Asynchronously trigger initialization on first call (non-blocking)
  // video_output_notify_render already checks destroyed flag, so safe to call
  if (!self->initialization_posted && (self->name == 0 || self->fbo == 0)) {
    gint64 required_width = video_output_get_width(video_output);
    gint64 required_height = video_output_get_height(video_output);
    
    if (required_width > 0 && required_height > 0 && thread_pool) {
      self->initialization_posted = TRUE;
      
      // Post initialization task asynchronously (don't wait)
      thread_pool->Post([self, required_width, required_height, video_output]() {
        texture_gl_check_and_resize(self, required_width, required_height);
        
        // After initialization, trigger a render to populate the texture
        if (self->egl_image != EGL_NO_IMAGE_KHR) {
          video_output_notify_render(video_output);
        } else {
          // Initialization failed, reset flag to allow retry
          self->initialization_posted = FALSE;
        }
      });
    }
  }
  
  // Update Flutter's texture from EGLImage if resize happened
  if (self->needs_texture_update && self->egl_image != EGL_NO_IMAGE_KHR) {
    g_print("[TextureGL %p] Updating Flutter texture (old name=%u)\n", self, self->name);
    
    // Free previous Flutter texture to prevent leak
    if (self->name != 0) {
      glDeleteTextures(1, &self->name);
      self->name = 0;
    }
    
    // Create Flutter's texture from EGLImage (in Flutter's GL context)
    glGenTextures(1, &self->name);
    glBindTexture(GL_TEXTURE_2D, self->name);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glEGLImageTargetTexture2DOES(GL_TEXTURE_2D, self->egl_image);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    g_print("[TextureGL %p] Flutter texture updated: name=%u, size=%ux%u\n",
            self, self->name, self->current_width, self->current_height);
    
    self->needs_texture_update = FALSE;
    
    // Notify Flutter about dimension change
    video_output_notify_texture_update(video_output);
  }
  
  *target = GL_TEXTURE_2D;
  *name = self->name;
  *width = self->current_width;
  *height = self->current_height;
  
  // Create dummy texture ONLY if name is still 0 (first call before initialization)
  if (self->name == 0) {
    g_print("[TextureGL %p] Creating dummy texture (first frame not yet available)\n", self);
    glGenTextures(1, &self->name);
    glBindTexture(GL_TEXTURE_2D, self->name);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glBindTexture(GL_TEXTURE_2D, 0);
    *name = self->name;
    *width = 1;
    *height = 1;
    g_print("[TextureGL %p] Dummy texture created: name=%u\n", self, self->name);
  }
  
  return TRUE;
}
