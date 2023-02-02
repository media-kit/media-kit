// This file is a part of media_kit
// (https://github.com/alexmercerind/media_kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#include "include/media_kit_video/video_output.h"

#include <mpv/client.h>
#include <mpv/render.h>
#include <mpv/render_gl.h>

struct _VideoOutput {
  GObject parent_instance;
  mpv_handle* handle;
  mpv_render_context* render_context;
  gint64 width;
  gint64 height;
  gint64 texture_id;
  TextureUpdateCallback texture_update_callback;
  gpointer texture_update_callback_context;
};

G_DEFINE_TYPE(VideoOutput, video_output, G_TYPE_OBJECT)

static void video_output_dispose(GObject* object) {
  G_OBJECT_CLASS(video_output_parent_class)->dispose(object);
}

static void video_output_class_init(VideoOutputClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = video_output_dispose;
}

static void video_output_init(VideoOutput* self) {
  self->handle = NULL;
  self->render_context = NULL;
  self->width = 0;
  self->height = 0;
  self->texture_id = 0;
  self->texture_update_callback = NULL;
  self->texture_update_callback_context = NULL;
}

VideoOutput* video_output_new(FlTextureRegistrar* texture_registrar,
                              gint64 handle,
                              gint64 width,
                              gint64 height) {
  VideoOutput* self = VIDEO_OUTPUT(g_object_new(video_output_get_type(), NULL));
  self->handle = reinterpret_cast<mpv_handle*>(handle);
  self->width = width;
  self->height = height;
  g_print("media_kit: video_output_new: %ld\n", handle);
  return self;
}

void video_output_set_texture_update_callback(
    VideoOutput* self,
    TextureUpdateCallback texture_update_callback,
    gpointer texture_update_callback_context) {
  self->texture_update_callback = texture_update_callback;
  self->texture_update_callback_context = texture_update_callback_context;
  gint64 texture_id = self->texture_id;
  gint64 width = video_output_get_width(self);
  gint64 height = video_output_get_height(self);
  gpointer context = self->texture_update_callback_context;
  self->texture_update_callback(texture_id, width, height, context);
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
    return self->width;
  }
  // Video resolution dependent height.
  gint64 height = 0;
  mpv_get_property(self->handle, "height", MPV_FORMAT_INT64, &height);
  return height;
}

// TODO(@alexmercerind): Fallback S/W rendering.
