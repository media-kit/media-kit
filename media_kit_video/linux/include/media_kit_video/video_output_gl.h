// This file is a part of media_kit
// (https://github.com/alexmercerind/media_kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#ifndef VIDEO_OUTPUT_GL_H_
#define VIDEO_OUTPUT_GL_H_

#include <flutter_linux/fl_texture.h>
#include <flutter_linux/fl_texture_gl.h>
#include <flutter_linux/flutter_linux.h>

#define VIDEO_OUTPUT_GL_TYPE (video_output_gl_get_type())

G_DECLARE_FINAL_TYPE(VideoOutputGL,
                     video_output_gl,
                     VIDEO_OUTPUT_GL,
                     VIDEO_OUTPUT_GL,
                     FlTextureGL)

#define VIDEO_OUTPUT_GL(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), video_output_gl_get_type(), VideoOutputGL))

static VideoOutputGL* video_output_gl_new();

static gint64 video_output_gl_get_texture_id(VideoOutputGL* self);

static gboolean video_output_gl_populate_texture(FlTextureGL* texture,
                                                 uint32_t* target,
                                                 uint32_t* name,
                                                 uint32_t* width,
                                                 uint32_t* height,
                                                 GError** error);

#endif  // VIDEO_OUTPUT_GL_H_
