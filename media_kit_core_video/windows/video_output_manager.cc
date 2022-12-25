// This file is a part of media_kit
// (https://github.com/alexmercerind/media_kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#include "video_output_manager.h"

VideoOutputManager::VideoOutputManager(
    flutter::PluginRegistrarWindows* registrar,
    flutter::MethodChannel<flutter::EncodableValue>* channel)
    : registrar_(registrar), channel_(channel) {}

VideoOutput* VideoOutputManager::Create(int64_t handle,
                                        std::optional<int64_t> width,
                                        std::optional<int64_t> height) {
  if (video_outputs_.find(handle) == video_outputs_.end()) {
    auto video_output =
        std::make_unique<VideoOutput>(handle, width, height, GetIDXGIAdapter());
    video_outputs_.insert({handle, std::move(video_output)});
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

IDXGIAdapter* VideoOutputManager::GetIDXGIAdapter() {
  return registrar_->GetView()->GetGraphicsAdapter();
}
