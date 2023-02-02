// This file is a part of media_kit
// (https://github.com/alexmercerind/media_kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#include "include/media_kit_video/texture_gl.h"

#include <epoxy/gl.h>

struct _TextureGL {
  FlTextureGL parent_instance;
  uint32_t target;
  uint32_t name;
  uint32_t width;
  uint32_t height;
};

G_DEFINE_TYPE(TextureGL, texture_gl, fl_texture_gl_get_type())

static void texture_gl_init(TextureGL* self) {}

static void texture_gl_dispose(GObject* object) {
  G_OBJECT_CLASS(texture_gl_parent_class)->dispose(object);
}

static void texture_gl_class_init(TextureGLClass* klass) {
  FL_TEXTURE_GL_CLASS(klass)->populate = texture_gl_populate_texture;
  G_OBJECT_CLASS(klass)->dispose = texture_gl_dispose;
}

TextureGL* texture_gl_new() {
  return TEXTURE_GL(g_object_new(texture_gl_get_type(), nullptr));
}

gint64 texture_gl_get_texture_id(TextureGL* self) {
  return reinterpret_cast<gint64>(FL_TEXTURE_GL(self));
}

gboolean texture_gl_populate_texture(FlTextureGL* texture,
                                     uint32_t* target,
                                     uint32_t* name,
                                     uint32_t* width,
                                     uint32_t* height,
                                     GError** error) {
  *target = TEXTURE_GL(texture)->target;
  *name = TEXTURE_GL(texture)->name;
  *width = TEXTURE_GL(texture)->width;
  *height = TEXTURE_GL(texture)->height;
  return TRUE;
}
