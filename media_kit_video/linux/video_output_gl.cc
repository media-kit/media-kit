// This file is a part of media_kit
// (https://github.com/alexmercerind/media_kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#include "include/media_kit_video/video_output_gl.h"

#include <epoxy/gl.h>

struct _VideoOutputGL {
  FlTextureGL parent_instance;
  uint32_t target;
  uint32_t name;
  uint32_t width;
  uint32_t height;
};

G_DEFINE_TYPE(VideoOutputGL, video_output_gl, fl_texture_gl_get_type())

static void video_output_gl_init(VideoOutputGL* self) {}

static void video_output_gl_dispose(GObject* object) {
  G_OBJECT_CLASS(video_output_gl_parent_class)->dispose(object);
}

static void video_output_gl_class_init(VideoOutputGLClass* klass) {
  FL_TEXTURE_GL_CLASS(klass)->populate = video_output_gl_populate_texture;
  G_OBJECT_CLASS(klass)->dispose = video_output_gl_dispose;
}

static VideoOutputGL* video_output_gl_new() {
  return VIDEO_OUTPUT_GL(g_object_new(video_output_gl_get_type(), nullptr));
}

static gint64 video_output_gl_get_texture_id(VideoOutputGL* self) {
  return reinterpret_cast<gint64>(FL_TEXTURE_GL(self));
}

static gboolean video_output_gl_populate_texture(FlTextureGL* texture,
                                                 uint32_t* target,
                                                 uint32_t* name,
                                                 uint32_t* width,
                                                 uint32_t* height,
                                                 GError** error) {
  *target = VIDEO_OUTPUT_GL(texture)->target;
  *name = VIDEO_OUTPUT_GL(texture)->name;
  *width = VIDEO_OUTPUT_GL(texture)->width;
  *height = VIDEO_OUTPUT_GL(texture)->height;
  return TRUE;
}
