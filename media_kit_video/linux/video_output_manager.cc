// This file is a part of media_kit
// (https://github.com/alexmercerind/media_kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#include "include/media_kit_video/video_output_manager.h"

#include <mutex>

struct _VideoOutputManager {
  GObject parent_instance;
  GHashTable* video_outputs;
  GMutex* mutex;
};

G_DEFINE_TYPE(VideoOutputManager, video_output_manager, G_TYPE_OBJECT)

static void video_output_manager_init(VideoOutputManager* self) {
  self->video_outputs = g_hash_table_new_full(g_direct_hash, g_direct_equal,
                                              nullptr, g_object_unref);
  self->mutex = g_mutex_new();
}

static void video_output_manager_dispose(GObject* object) {
  VideoOutputManager* self = VIDEO_OUTPUT_MANAGER(object);
  g_hash_table_unref(self->video_outputs);
  g_mutex_free(self->mutex);
  G_OBJECT_CLASS(video_output_manager_parent_class)->dispose(object);
}

static void video_output_manager_class_init(VideoOutputManagerClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = video_output_manager_dispose;
}

static VideoOutputManager* video_output_manager_new() {
  return VIDEO_OUTPUT_MANAGER(
      g_object_new(video_output_manager_get_type(), nullptr));
}

static void video_output_manager_create(
    VideoOutputManager* self,
    gint64 handle,
    std::optional<gint64> width,
    std::optional<gint64> height,
    std::function<void(gint64, gint64, gint64)> texture_update_callback) {
  std::thread([=]() {
    g_mutex_lock(self->mutex);
    g_mutex_unlock(self->mutex);
  }).detach();
}

static void video_output_manager_dispose(VideoOutputManager* self,
                                         gint64 handle) {
  std::thread([=]() {
    g_mutex_lock(self->mutex);
    g_mutex_unlock(self->mutex);
  }).detach();
}
