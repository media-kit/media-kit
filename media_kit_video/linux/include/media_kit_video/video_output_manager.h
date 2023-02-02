// This file is a part of media_kit
// (https://github.com/alexmercerind/media_kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#ifndef VIDEO_OUTPUT_MANAGER_H_
#define VIDEO_OUTPUT_MANAGER_H_

#include <flutter_linux/fl_texture_registrar.h>

#include "include/media_kit_video/video_output.h"

#define VIDEO_OUTPUT_MANAGER_TYPE (video_output_manager_get_type())

// Creates & disposes |VideoOutput| instances for video embedding.
//
// The methods in this class are thread-safe & run on separate worker thread so
// that they don't block Flutter's UI thread while platform channels are being
// invoked.
G_DECLARE_FINAL_TYPE(VideoOutputManager,
                     video_output_manager,
                     VIDEO_OUTPUT_MANAGER,
                     VIDEO_OUTPUT_MANAGER,
                     GObject)

#define VIDEO_OUTPUT_MANAGER(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), video_output_manager_get_type(), \
                              VideoOutputManager))

static VideoOutputManager* video_output_manager_new(
    FlTextureRegistrar* texture_registrar);

// Creates a new |VideoOutput| instance. It's texture ID may be used to render
// the video. The changes in it's texture ID & video dimensions will be
// notified via the |texture_update_callback|.
static void video_output_manager_create(
    VideoOutputManager* self,
    gint64 handle,
    gint64 width,
    gint64 height,
    TextureUpdateCallback texture_update_callback,
    gpointer texture_update_callback_context);

// Destroys the |VideoOutput| with given handle.
static void video_output_manager_dispose(VideoOutputManager* self,
                                         gint64 handle);

#endif
