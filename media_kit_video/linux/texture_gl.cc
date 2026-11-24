// This file is a part of media_kit
// (https://github.com/media-kit/media-kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#include "include/media_kit_video/texture_gl.h"
#include "include/media_kit_video/isolated_egl.h"

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

// Flutter's texture names are made in Flutter's context on the raster thread,
// while an output is mostly disposed of on the platform thread, where another
// context is current (GDK's). A name is deleted in the context that made it: at
// once when that one is current, else at the next populate of a texture in it,
// so that neither another context's texture nor the frame the name holds
// through its EGLImage is lost.
typedef struct {
  EGLContext context;
  guint32 name;
} TextureGLPendingName;

static GMutex texture_gl_pending_mutex;
static GArray* texture_gl_pending_names = NULL;

static void texture_gl_delete_name(EGLContext context, guint32 name) {
  if (name == 0) {
    return;
  }
  if (context == EGL_NO_CONTEXT || eglGetCurrentContext() == context) {
    glDeleteTextures(1, &name);
    return;
  }
  g_mutex_lock(&texture_gl_pending_mutex);
  if (texture_gl_pending_names == NULL) {
    texture_gl_pending_names =
        g_array_new(FALSE, FALSE, sizeof(TextureGLPendingName));
  }
  TextureGLPendingName pending{context, name};
  g_array_append_val(texture_gl_pending_names, pending);
  g_mutex_unlock(&texture_gl_pending_mutex);
}

static void texture_gl_delete_pending_names() {
  EGLContext current = eglGetCurrentContext();
  g_mutex_lock(&texture_gl_pending_mutex);
  if (texture_gl_pending_names != NULL) {
    for (guint i = 0; i < texture_gl_pending_names->len;) {
      TextureGLPendingName* pending =
          &g_array_index(texture_gl_pending_names, TextureGLPendingName, i);
      if (pending->context == current) {
        glDeleteTextures(1, &pending->name);
        g_array_remove_index_fast(texture_gl_pending_names, i);
      } else {
        i++;
      }
    }
  }
  g_mutex_unlock(&texture_gl_pending_mutex);
}

struct _TextureGL {
  FlTextureGL parent_instance;
  guint32 name;              // Flutter's texture name
  EGLContext name_context;   // The EGL context |name| was made in
  guint32 fbo;               // mpv's FBO
  guint32 mpv_texture;       // mpv's texture
  EGLImageKHR egl_image;     // EGLImage for sharing between contexts
  guint32 current_width;
  guint32 current_height;
  VideoOutput* video_output;
};

G_DEFINE_TYPE(TextureGL, texture_gl, fl_texture_gl_get_type())

static void texture_gl_init(TextureGL* self) {
  self->name = 0;
  self->name_context = EGL_NO_CONTEXT;
  self->fbo = 0;
  self->mpv_texture = 0;
  self->egl_image = EGL_NO_IMAGE_KHR;
  self->current_width = 1;
  self->current_height = 1;
  self->video_output = NULL;
}

static void texture_gl_dispose(GObject* object) {
  TextureGL* self = TEXTURE_GL(object);
  VideoOutput* video_output = self->video_output;
  
  // Clean up Flutter's texture (in Flutter's context)
  texture_gl_delete_name(self->name_context, self->name);
  self->name = 0;
  
  // Clean up EGLImage
  if (self->egl_image != EGL_NO_IMAGE_KHR && video_output != NULL) {
    EGLDisplay egl_display = video_output_get_egl_display(video_output);
    eglDestroyImageKHR(egl_display, self->egl_image);
    self->egl_image = EGL_NO_IMAGE_KHR;
  }
  
  // Clean up mpv's OpenGL resources (in mpv's isolated context)
  if (video_output != NULL && (self->mpv_texture != 0 || self->fbo != 0)) {
    EGLDisplay egl_display = video_output_get_egl_display(video_output);
    EGLContext egl_context = video_output_get_egl_context(video_output);
    
    if (egl_context != EGL_NO_CONTEXT) {
      // Whatever this thread had current (GDK's GL context on the platform
      // thread) is put aside, then comes back
      IsolatedEglSaved saved;
      EGLint error = EGL_SUCCESS;
      if (isolated_egl_enter(egl_display, egl_context, &saved, &error)) {
        if (self->mpv_texture != 0) {
          glDeleteTextures(1, &self->mpv_texture);
        }
        if (self->fbo != 0) {
          glDeleteFramebuffers(1, &self->fbo);
        }
      }
      isolated_egl_leave(egl_display, &saved);
    }
    // Without the isolated context, they went with it (eglDestroyContext)
    self->mpv_texture = 0;
    self->fbo = 0;
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

gboolean texture_gl_populate_texture(FlTextureGL* texture,
                                     guint32* target,
                                     guint32* name,
                                     guint32* width,
                                     guint32* height,
                                     GError** error) {
  TextureGL* self = TEXTURE_GL(texture);
  VideoOutput* video_output = self->video_output;
  // Names of disposed textures made in this context
  texture_gl_delete_pending_names();
  
  gint32 required_width = (guint32)video_output_get_width(video_output);
  gint32 required_height = (guint32)video_output_get_height(video_output);
  
  if (required_width > 0 && required_height > 0) {
    gboolean first_frame = self->name == 0 || self->fbo == 0 || self->mpv_texture == 0;
    gboolean resize = self->current_width != required_width ||
                      self->current_height != required_height;
    
    if (first_frame || resize) {
      // Save Flutter's current EGL context
      EGLDisplay flutter_display = eglGetCurrentDisplay();
      EGLContext flutter_context = eglGetCurrentContext();
      EGLSurface flutter_draw = eglGetCurrentSurface(EGL_DRAW);
      EGLSurface flutter_read = eglGetCurrentSurface(EGL_READ);
      
      EGLDisplay egl_display = video_output_get_egl_display(video_output);
      EGLContext egl_context = video_output_get_egl_context(video_output);
      
      // Switch to mpv's isolated context to create/resize mpv's texture and FBO
      eglMakeCurrent(egl_display, EGL_NO_SURFACE, EGL_NO_SURFACE, egl_context);
      
      // Free previous resources in mpv's context
      if (!first_frame) {
        glDeleteTextures(1, &self->mpv_texture);
        glDeleteFramebuffers(1, &self->fbo);
        if (self->egl_image != EGL_NO_IMAGE_KHR) {
          eglDestroyImageKHR(egl_display, self->egl_image);
        }
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
      
      glBindFramebuffer(GL_FRAMEBUFFER, 0);
      glBindTexture(GL_TEXTURE_2D, 0);
      
      // Flush to ensure mpv's texture is ready
      glFlush();
      
      // Switch back to Flutter's context to create/update Flutter's texture
      eglMakeCurrent(flutter_display, flutter_draw, flutter_read, flutter_context);
      
      // Free previous Flutter texture (the 1x1 one made before the first
      // frame too)
      if (self->name != 0) {
        glDeleteTextures(1, &self->name);
      }
      
      // Create Flutter's texture from EGLImage
      glGenTextures(1, &self->name);
      self->name_context = eglGetCurrentContext();
      glBindTexture(GL_TEXTURE_2D, self->name);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
      glEGLImageTargetTexture2DOES(GL_TEXTURE_2D, self->egl_image);
      glBindTexture(GL_TEXTURE_2D, 0);
      
      self->current_width = required_width;
      self->current_height = required_height;
      
      // Notify Flutter about dimension change
      video_output_notify_texture_update(video_output);
      
      // Flutter's context is already current, so we're ready to render
    }
    
    // Save Flutter's current context
    EGLDisplay flutter_display = eglGetCurrentDisplay();
    EGLContext flutter_context = eglGetCurrentContext();
    EGLSurface flutter_draw = eglGetCurrentSurface(EGL_DRAW);
    EGLSurface flutter_read = eglGetCurrentSurface(EGL_READ);
    
    EGLDisplay egl_display = video_output_get_egl_display(video_output);
    EGLContext egl_context = video_output_get_egl_context(video_output);
    mpv_render_context* render_context = video_output_get_render_context(video_output);
    
    // Switch to mpv's isolated context for rendering
    eglMakeCurrent(egl_display, EGL_NO_SURFACE, EGL_NO_SURFACE, egl_context);
    
    // Bind mpv's FBO
    glBindFramebuffer(GL_FRAMEBUFFER, self->fbo);
    
    // Render mpv frame to mpv's texture
    mpv_opengl_fbo fbo{(gint32)self->fbo, required_width, required_height, 0};
    int flip_y = 0;
    int block_for_target_time = 0;
    mpv_render_param params[] = {
        {MPV_RENDER_PARAM_OPENGL_FBO, &fbo},
        {MPV_RENDER_PARAM_FLIP_Y, &flip_y},
        {MPV_RENDER_PARAM_BLOCK_FOR_TARGET_TIME, &block_for_target_time},
        {MPV_RENDER_PARAM_INVALID, NULL},
    };
    mpv_render_context_render(render_context, params);
    
    // Unbind FBO
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    // Flush to ensure rendering is complete
    glFlush();
    
    // Restore Flutter's context
    eglMakeCurrent(flutter_display, flutter_draw, flutter_read, flutter_context);
  }
  
  *target = GL_TEXTURE_2D;
  *name = self->name;
  *width = self->current_width;
  *height = self->current_height;
  
  if (self->name == 0) {
    // First frame not yet available - create dummy texture in Flutter's context
    glGenTextures(1, &self->name);
    self->name_context = eglGetCurrentContext();
    glBindTexture(GL_TEXTURE_2D, self->name);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glBindTexture(GL_TEXTURE_2D, 0);
    *name = self->name;
    *width = 1;
    *height = 1;
  }
  
  return TRUE;
}