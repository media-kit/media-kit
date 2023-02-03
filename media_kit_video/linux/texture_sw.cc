// This file is a part of media_kit
// (https://github.com/alexmercerind/media_kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#include "include/media_kit_video/texture_sw.h"

struct _TextureSW {
  FlPixelBufferTexture parent_instance;
  VideoOutput* video_output;
};

G_DEFINE_TYPE(TextureSW, texture_sw, fl_pixel_buffer_texture_get_type())

static void texture_sw_init(TextureSW* self) {
  self->video_output = NULL;
}

static void texture_sw_dispose(GObject* object) {
  G_OBJECT_CLASS(texture_sw_parent_class)->dispose(object);
}

static void texture_sw_class_init(TextureSWClass* klass) {
  FL_PIXEL_BUFFER_TEXTURE_CLASS(klass)->copy_pixels = texture_sw_copy_pixels;
  G_OBJECT_CLASS(klass)->dispose = texture_sw_dispose;
}

TextureSW* texture_sw_new(VideoOutput* video_output) {
  TextureSW* self = TEXTURE_SW(g_object_new(texture_sw_get_type(), NULL));
  self->video_output = video_output;
  return self;
}

gboolean texture_sw_copy_pixels(FlPixelBufferTexture* texture,
                                const uint8_t** buffer,
                                uint32_t* width,
                                uint32_t* height,
                                GError** error) {
  TextureSW* self = TEXTURE_SW(texture);
  *buffer = video_output_get_pixel_buffer(self->video_output);
  *width = video_output_get_width(self->video_output);
  *height = video_output_get_height(self->video_output);
  return TRUE;
}
