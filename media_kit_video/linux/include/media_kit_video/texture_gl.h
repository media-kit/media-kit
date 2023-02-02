// This file is a part of media_kit
// (https://github.com/alexmercerind/media_kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#ifndef TEXTURE_GL_H_
#define TEXTURE_GL_H_

#include <flutter_linux/flutter_linux.h>

#define TEXTURE_GL_TYPE (texture_gl_get_type())

G_DECLARE_FINAL_TYPE(TextureGL, texture_gl, TEXTURE_GL, TEXTURE_GL, FlTextureGL)

#define TEXTURE_GL(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), texture_gl_get_type(), TextureGL))

TextureGL* texture_gl_new();

gint64 texture_gl_get_texture_id(TextureGL* self);

gboolean texture_gl_populate_texture(FlTextureGL* texture,
                                     uint32_t* target,
                                     uint32_t* name,
                                     uint32_t* width,
                                     uint32_t* height,
                                     GError** error);

#endif  // TEXTURE_GL_H_
