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
#include <atomic>

// Reference counting for leak detection
static std::atomic<int> g_texture_gl_instance_count{0};
static std::atomic<int> g_egl_image_count{0};
static std::atomic<int> g_mpv_texture_count{0};
static std::atomic<int> g_fbo_count{0};
static std::atomic<int> g_flutter_texture_count{0};

static void print_resource_stats(const char* context) {
  g_print("[ResourceStats - %s] TextureGL instances: %d, EGLImages: %d, mpv_textures: %d, FBOs: %d, Flutter_textures: %d\n",
          context,
          g_texture_gl_instance_count.load(),
          g_egl_image_count.load(),
          g_mpv_texture_count.load(),
          g_fbo_count.load(),
          g_flutter_texture_count.load());
}

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
  
  int count = ++g_texture_gl_instance_count;
  g_print("[TextureGL %p] Instance created (total instances: %d)\n", self, count);
  print_resource_stats("texture_gl_init");
}

static void texture_gl_dispose(GObject* object) {
  TextureGL* self = TEXTURE_GL(object);
  
  VideoOutput* video_output = self->video_output;
  
  int count = --g_texture_gl_instance_count;
  g_print("[TextureGL %p] ========== DISPOSE START (remaining instances: %d) ==========\n", self, count);
  g_print("[TextureGL %p] Current state: name=%u, mpv_texture=%u, fbo=%u, egl_image=%p\n",
          self, self->name, self->mpv_texture, self->fbo, self->egl_image);
  print_resource_stats("texture_gl_dispose_start");
  
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
    --g_flutter_texture_count;
    g_print("[TextureGL %p] Flutter texture deleted (remaining: %d)\n", self, g_flutter_texture_count.load());
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
        --g_egl_image_count;
        g_print("[TextureGL %p] EGLImage destroyed (remaining: %d)\n", self_ptr, g_egl_image_count.load());
      }
      
      // 2. Then delete GL texture and FBO
      if (mpv_texture != 0) {
        glDeleteTextures(1, &mpv_texture);
        --g_mpv_texture_count;
        g_print("[TextureGL %p] mpv_texture deleted (remaining: %d)\n", self_ptr, g_mpv_texture_count.load());
      }
      if (fbo != 0) {
        glDeleteFramebuffers(1, &fbo);
        --g_fbo_count;
        g_print("[TextureGL %p] FBO deleted (remaining: %d)\n", self_ptr, g_fbo_count.load());
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
  
  // Reset flags
  self->initialization_posted = FALSE;
  self->needs_texture_update = FALSE;
  self->current_width = 1;
  self->current_height = 1;
  self->video_output = NULL;
  
  // Final verification: ensure all resources are cleared
  if (self->name != 0) {
    g_printerr("[TextureGL %p] ERROR: Flutter texture name still set after dispose: %u\n", self, self->name);
  }
  if (self->mpv_texture != 0) {
    g_printerr("[TextureGL %p] ERROR: mpv_texture still set after dispose: %u\n", self, self->mpv_texture);
  }
  if (self->fbo != 0) {
    g_printerr("[TextureGL %p] ERROR: fbo still set after dispose: %u\n", self, self->fbo);
  }
  if (self->egl_image != EGL_NO_IMAGE_KHR) {
    g_printerr("[TextureGL %p] ERROR: egl_image still set after dispose: %p\n", self, self->egl_image);
  }
  
  print_resource_stats("texture_gl_dispose_end");
  g_print("[TextureGL %p] ========== DISPOSE COMPLETE ==========\n", self);
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
    EGLint egl_error = eglGetError();
    g_printerr("[TextureGL %p] ERROR: Failed to make EGL context current (error: 0x%x)\n", 
               self, egl_error);
    g_printerr("[TextureGL %p] Context state: egl_display=%p, egl_context=%p\n", 
               self, egl_display, egl_context);
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
      --g_egl_image_count;
      g_print("[TextureGL %p] Resize: EGLImage destroyed (remaining: %d)\n", self, g_egl_image_count.load());
    }
    // Then delete GL texture and FBO
    if (self->mpv_texture != 0) {
      glDeleteTextures(1, &self->mpv_texture);
      self->mpv_texture = 0;
      --g_mpv_texture_count;
      g_print("[TextureGL %p] Resize: mpv_texture deleted (remaining: %d)\n", self, g_mpv_texture_count.load());
    }
    if (self->fbo != 0) {
      glDeleteFramebuffers(1, &self->fbo);
      self->fbo = 0;
      --g_fbo_count;
      g_print("[TextureGL %p] Resize: FBO deleted (remaining: %d)\n", self, g_fbo_count.load());
    }
    
    g_print("[TextureGL %p] Old resources cleaned\n", self);
    print_resource_stats("texture_gl_resize_cleanup");
  }
  
  // Create mpv's FBO and texture
  glGenFramebuffers(1, &self->fbo);
  GLenum gl_error = glGetError();
  if (gl_error != GL_NO_ERROR) {
    g_printerr("[TextureGL %p] ERROR: GL error after glGenFramebuffers: 0x%x\n", self, gl_error);
    print_resource_stats("texture_gl_fbo_creation_failed");
    return;
  }
  ++g_fbo_count;
  g_print("[TextureGL %p] FBO created: %u (total: %d)\n", self, self->fbo, g_fbo_count.load());
  glBindFramebuffer(GL_FRAMEBUFFER, self->fbo);
  
  glGenTextures(1, &self->mpv_texture);
  gl_error = glGetError();
  if (gl_error != GL_NO_ERROR) {
    g_printerr("[TextureGL %p] ERROR: GL error after glGenTextures: 0x%x\n", self, gl_error);
    // Cleanup FBO before returning
    glDeleteFramebuffers(1, &self->fbo);
    --g_fbo_count;
    self->fbo = 0;
    print_resource_stats("texture_gl_texture_creation_failed");
    return;
  }
  ++g_mpv_texture_count;
  g_print("[TextureGL %p] mpv_texture created: %u (total: %d)\n", self, self->mpv_texture, g_mpv_texture_count.load());
  glBindTexture(GL_TEXTURE_2D, self->mpv_texture);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, required_width, required_height,
               0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
  
  // Check for GL errors after texture creation
  gl_error = glGetError();
  if (gl_error != GL_NO_ERROR) {
    g_printerr("[TextureGL %p] ERROR: GL error after glTexImage2D: 0x%x\n", self, gl_error);
    // Cleanup texture and FBO before returning
    glDeleteTextures(1, &self->mpv_texture);
    --g_mpv_texture_count;
    self->mpv_texture = 0;
    glDeleteFramebuffers(1, &self->fbo);
    --g_fbo_count;
    self->fbo = 0;
    print_resource_stats("texture_gl_teximage2d_failed");
    return;
  }
  
  // Attach mpv's texture to FBO
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                         GL_TEXTURE_2D, self->mpv_texture, 0);
  
  gl_error = glGetError();
  if (gl_error != GL_NO_ERROR) {
    g_printerr("[TextureGL %p] ERROR: GL error after glFramebufferTexture2D: 0x%x\n", self, gl_error);
  }
  
  // Check FBO completeness
  GLenum fbo_status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
  if (fbo_status != GL_FRAMEBUFFER_COMPLETE) {
    g_printerr("[TextureGL %p] ERROR: FBO incomplete, status=0x%x\n", self, fbo_status);
    // Cleanup resources before returning
    glDeleteTextures(1, &self->mpv_texture);
    --g_mpv_texture_count;
    self->mpv_texture = 0;
    glDeleteFramebuffers(1, &self->fbo);
    --g_fbo_count;
    self->fbo = 0;
    print_resource_stats("texture_gl_fbo_incomplete");
    return;
  }
  
  // Create EGLImage from mpv's texture
  EGLint egl_image_attribs[] = { EGL_NONE };
  self->egl_image = eglCreateImageKHR(
      egl_display,
      egl_context,
      EGL_GL_TEXTURE_2D_KHR,
      (EGLClientBuffer)(guintptr)self->mpv_texture,
      egl_image_attribs);
  
  if (self->egl_image == EGL_NO_IMAGE_KHR) {
    EGLint egl_error = eglGetError();
    g_printerr("[TextureGL %p] ERROR: Failed to create EGLImage (error: 0x%x)\n", 
               self, egl_error);
    // Cleanup GL resources before returning
    glDeleteTextures(1, &self->mpv_texture);
    --g_mpv_texture_count;
    self->mpv_texture = 0;
    glDeleteFramebuffers(1, &self->fbo);
    --g_fbo_count;
    self->fbo = 0;
    print_resource_stats("texture_gl_eglimage_creation_failed");
  } else {
    ++g_egl_image_count;
    g_print("[TextureGL %p] Created resources: egl_image=%p, mpv_texture=%u, fbo=%u, size=%ldx%ld (total EGLImages: %d)\n",
            self, self->egl_image, self->mpv_texture, self->fbo, required_width, required_height, g_egl_image_count.load());
  }
  
  print_resource_stats("texture_gl_resources_created");
  
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
      --g_flutter_texture_count;
      g_print("[TextureGL %p] Old Flutter texture deleted during update (remaining: %d)\n", self, g_flutter_texture_count.load());
    }
    
    // Create Flutter's texture from EGLImage (in Flutter's GL context)
    glGenTextures(1, &self->name);
    ++g_flutter_texture_count;
    g_print("[TextureGL %p] Flutter texture created: %u (total: %d)\n", self, self->name, g_flutter_texture_count.load());
    glBindTexture(GL_TEXTURE_2D, self->name);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glEGLImageTargetTexture2DOES(GL_TEXTURE_2D, self->egl_image);
    
    // Check for GL errors
    GLenum gl_error = glGetError();
    if (gl_error != GL_NO_ERROR) {
      g_printerr("[TextureGL %p] ERROR: GL error after glEGLImageTargetTexture2DOES: 0x%x\n", self, gl_error);
      // Delete the created texture on error
      glDeleteTextures(1, &self->name);
      --g_flutter_texture_count;
      self->name = 0;
      glBindTexture(GL_TEXTURE_2D, 0);
      print_resource_stats("texture_gl_flutter_texture_eglimage_failed");
      return FALSE;  // Return error to Flutter
    }
    
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
    ++g_flutter_texture_count;
    g_print("[TextureGL %p] Dummy Flutter texture created: %u (total: %d)\n", self, self->name, g_flutter_texture_count.load());
    glBindTexture(GL_TEXTURE_2D, self->name);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    
    // Check for GL errors
    GLenum gl_error = glGetError();
    if (gl_error != GL_NO_ERROR) {
      g_printerr("[TextureGL %p] ERROR: GL error after dummy texture creation: 0x%x\n", self, gl_error);
      glDeleteTextures(1, &self->name);
      --g_flutter_texture_count;
      self->name = 0;
      print_resource_stats("texture_gl_dummy_texture_failed");
      return FALSE;  // Return error to Flutter
    }
    
    glBindTexture(GL_TEXTURE_2D, 0);
    *name = self->name;
    *width = 1;
    *height = 1;
    g_print("[TextureGL %p] Dummy texture created: name=%u\n", self, self->name);
  }
  
  return TRUE;
}
