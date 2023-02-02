// This file is a part of media_kit
// (https://github.com/alexmercerind/media_kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#ifndef VIDEO_OUTPUT_H_
#define VIDEO_OUTPUT_H_

#include <flutter_linux/flutter_linux.h>

// Callback invoked when the texture ID updates i.e. video dimensions changes.
typedef void (*TextureUpdateCallback)(gint64 id,
                                      gint64 width,
                                      gint64 height,
                                      gpointer context);

#define VIDEO_OUTPUT_TYPE (video_output_get_type())

G_DECLARE_FINAL_TYPE(VideoOutput,
                     video_output,
                     VIDEO_OUTPUT,
                     VIDEO_OUTPUT,
                     GObject)

#define VIDEO_OUTPUT(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), video_output_get_type(), VideoOutput))

VideoOutput* video_output_new(FlTextureRegistrar* texture_registrar,
                              gint64 handle,
                              gint64 width,
                              gint64 height);

void video_output_set_texture_update_callback(
    VideoOutput* self,
    TextureUpdateCallback texture_update_callback,
    gpointer texture_update_callback_context);

gint64 video_output_get_width(VideoOutput* self);

gint64 video_output_get_height(VideoOutput* self);

#endif  // VIDEO_OUTPUT_H_
