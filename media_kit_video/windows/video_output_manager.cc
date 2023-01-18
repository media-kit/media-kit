// This file is a part of media_kit
// (https://github.com/alexmercerind/media_kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#include "video_output_manager.h"

VideoOutputManager::VideoOutputManager(
    flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar) {}

VideoOutput* VideoOutputManager::Create(
    int64_t handle,
    std::optional<int64_t> width,
    std::optional<int64_t> height,
    std::function<void(int64_t, int64_t, int64_t)> texture_update_callback) {
  if (video_outputs_.find(handle) == video_outputs_.end()) {
    auto instance = std::make_unique<VideoOutput>(handle, width, height,
                                                  registrar_, &render_mutex_);
    auto ref = instance.get();
    ref->SetTextureUpdateCallback(texture_update_callback);
    video_outputs_.insert(std::make_pair(handle, std::move(instance)));
  }
  return video_outputs_[handle].get();
}

bool VideoOutputManager::Dispose(int64_t handle) {
  if (video_outputs_.find(handle) == video_outputs_.end()) {
    return false;
  }
  video_outputs_.erase(handle);
  return true;
}

VideoOutputManager::~VideoOutputManager() {
  // Destroy all video outputs.
  // |VideoOutput| destructor will do the relevant cleanup.
  video_outputs_.clear();
}
