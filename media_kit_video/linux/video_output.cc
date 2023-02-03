// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

#include "include/media_kit_video/video_output.h"
#include "include/media_kit_video/texture_gl.h"

#include <epoxy/egl.h>
#include <epoxy/glx.h>
#include <gdk/gdkwayland.h>
#include <gdk/gdkx.h>

struct _VideoOutput {
  GObject parent_instance;
  TextureGL* texture_gl;
  GdkGLContext* context_gl;
  mpv_handle* handle;
  mpv_render_context* render_context;
  gint64 width;
  gint64 height;
  TextureUpdateCallback texture_update_callback;
  gpointer texture_update_callback_context;
  FlTextureRegistrar* texture_registrar;
  gboolean destroyed;
};

G_DEFINE_TYPE(VideoOutput, video_output, G_TYPE_OBJECT)

static void video_output_dispose(GObject* object) {
  VideoOutput* self = VIDEO_OUTPUT(object);
  self->destroyed = TRUE;
  fl_texture_registrar_mark_texture_frame_available(self->texture_registrar, FL_TEXTURE(self->texture_gl));
  // H/W
  if (self->texture_gl) {
    fl_texture_registrar_unregister_texture(self->texture_registrar, FL_TEXTURE(self->texture_gl));
    g_object_unref(self->context_gl);
    g_object_unref(self->texture_gl);
  }
  // TODO(@alexmercerind): Missing S/W rendering.
  mpv_render_context_free(self->render_context);
  g_print("media_kit: VideoOutput: video_output_dispose: %ld\n", (gint64)self->handle);
  G_OBJECT_CLASS(video_output_parent_class)->dispose(object);
}

static void video_output_class_init(VideoOutputClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = video_output_dispose;
}

static void video_output_init(VideoOutput* self) {
  self->texture_gl = NULL;
  self->context_gl = NULL;
  self->handle = NULL;
  self->render_context = NULL;
  self->width = 0;
  self->height = 0;
  self->texture_update_callback = NULL;
  self->texture_update_callback_context = NULL;
  self->texture_registrar = NULL;
  self->destroyed = FALSE;
}

VideoOutput* video_output_new(FlTextureRegistrar* texture_registrar, gint64 handle, gint64 width, gint64 height) {
  g_print("media_kit: VideoOutput: video_output_new: %ld\n", handle);
  VideoOutput* self = VIDEO_OUTPUT(g_object_new(video_output_get_type(), NULL));
  self->texture_registrar = texture_registrar;
  self->handle = (mpv_handle*)handle;
  self->width = width;
  self->height = height;
  GError* error = NULL;
  self->context_gl = gdk_window_create_gl_context(gdk_get_default_root_window(), &error);
  if (error == NULL) {
    // GL context must be made current before creating mpv render context.
    gdk_gl_context_realize(self->context_gl, &error);
    if (error == NULL) {
      // Create |FlTextureGL| and register it.
      self->texture_gl = texture_gl_new(self);
      if (fl_texture_registrar_register_texture(texture_registrar, FL_TEXTURE(self->texture_gl))) {
        // Request H/W decoding.
        mpv_set_option_string(self->handle, "hwdec", "auto");
        mpv_opengl_init_params gl_init_params{
            [](auto, auto name) -> void* {
              GdkDisplay* display = gdk_display_get_default();
              if (GDK_IS_WAYLAND_DISPLAY(display)) {
                return (void*)eglGetProcAddress(name);
              }
              if (GDK_IS_X11_DISPLAY(display)) {
                return (void*)(intptr_t)glXGetProcAddressARB((const GLubyte*)name);
              }
              g_assert_not_reached();
              return NULL;
            },
            NULL,
        };
        mpv_render_param params[] = {
            {MPV_RENDER_PARAM_API_TYPE, (void*)MPV_RENDER_API_TYPE_OPENGL},
            {MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, (void*)&gl_init_params},
            {MPV_RENDER_PARAM_INVALID, (void*)0},
        };
        gint success = mpv_render_context_create(&self->render_context, self->handle, params);
        if (success == 0) {
          mpv_render_context_set_update_callback(
              self->render_context,
              [](void* data) {
                VideoOutput* self = (VideoOutput*)data;
                if (self->destroyed) {
                  return;
                }
                FlTextureRegistrar* texture_registrar = self->texture_registrar;
                FlTexture* texture = FL_TEXTURE(self->texture_gl);
                fl_texture_registrar_mark_texture_frame_available(texture_registrar, texture);
              },
              self);
          g_print("media_kit: VideoOutput: Using H/W rendering.\n");
        }
      }
      gdk_gl_context_clear_current();
    }
  }
  if (error) {
    g_print("media_kit: VideoOutput: GError: %d\n", error->code);
    g_print("media_kit: VideoOutput: GError: %s\n", error->message);
  }
  // TODO(@alexmercerind): Fallback S/W rendering.
  return self;
}

void video_output_set_texture_update_callback(VideoOutput* self,
                                              TextureUpdateCallback texture_update_callback,
                                              gpointer texture_update_callback_context) {
  self->texture_update_callback = texture_update_callback;
  self->texture_update_callback_context = texture_update_callback_context;
  // Notify initial dimensions as (1, 1) if |width| & |height| are 0 i.e. texture & video frame size is based on playing
  // file's resolution. This will make sure that `Texture` widget on Flutter's widget tree is actually mounted &
  // |fl_texture_registrar_mark_texture_frame_available| actually invokes the |TextureGL| or |TextureSW| callbacks.
  // Otherwise it will be a never ending deadlock where no video frames are ever rendered.
  gint64 texture_id = video_output_get_texture_id(self);
  if (self->width == 0 || self->height == 0) {
    self->texture_update_callback(texture_id, 1, 1, self->texture_update_callback_context);
  } else {
    self->texture_update_callback(texture_id, self->width, self->height, self->texture_update_callback_context);
  }
}

mpv_render_context* video_output_get_render_context(VideoOutput* self) {
  return self->render_context;
}

gint64 video_output_get_width(VideoOutput* self) {
  // Fixed width.
  if (self->width) {
    return self->width;
  }
  // Video resolution dependent width.
  gint64 width = 0;
  mpv_get_property(self->handle, "width", MPV_FORMAT_INT64, &width);
  return width;
}

gint64 video_output_get_height(VideoOutput* self) {
  // Fixed height.
  if (self->width) {
    return self->height;
  }
  // Video resolution dependent height.
  gint64 height = 0;
  mpv_get_property(self->handle, "height", MPV_FORMAT_INT64, &height);
  return height;
}

gint64 video_output_get_texture_id(VideoOutput* self) {
  // H/W.
  if (self->texture_gl) {
    return (gint64)self->texture_gl;
  }
  // TODO(@alexmercerind): Missing S/W rendering.
  g_assert_not_reached();
  return -1;
}

void video_output_notify_texture_update(VideoOutput* self) {
  gint64 width = video_output_get_width(self);
  gint64 height = video_output_get_height(self);
  gpointer context = self->texture_update_callback_context;
  if (self->texture_update_callback != NULL) {
    self->texture_update_callback((gint64)self->texture_gl, width, height, context);
  }
}
