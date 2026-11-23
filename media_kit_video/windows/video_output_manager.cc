// This file is a part of media_kit
// (https://github.com/media-kit/media-kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#include "video_output_manager.h"

VideoOutputManager::VideoOutputManager(
    flutter::TextureRegistrar* registrar,
    Microsoft::WRL::ComPtr<IDXGIAdapter> adapter)
    : adapter_(std::move(adapter)), registrar_(registrar) {}

void VideoOutputManager::Create(
    int64_t handle,
    VideoOutputConfiguration configuration,
    std::function<void(int64_t, int64_t, int64_t)> texture_update_callback,
    std::function<void(std::string)> completion) {
  operations_->Post([=]() {
    try {
      if (video_outputs_.find(handle) == video_outputs_.end()) {
        auto instance = std::make_unique<VideoOutput>(
            handle, configuration, registrar_, thread_pool_.get(),
            &shutting_down_, adapter_.Get());
        instance->SetTextureUpdateCallback(texture_update_callback);
        video_outputs_.insert(std::make_pair(handle, std::move(instance)));
      }
      completion("");
    } catch (const std::exception& error) {
      completion(error.what());
    }
  });
}

void VideoOutputManager::SetSize(int64_t handle,
                                 std::optional<int64_t> width,
                                 std::optional<int64_t> height) {
  operations_->Post([=]() {
    if (video_outputs_.find(handle) != video_outputs_.end()) {
      video_outputs_[handle]->SetSize(width, height);
    }
  });
}

void VideoOutputManager::Dispose(int64_t handle,
                                 std::function<void()> completion) {
  operations_->Post([=]() {
    if (video_outputs_.find(handle) != video_outputs_.end()) {
      video_outputs_.erase(handle);
    }
    completion();
  });
}

VideoOutputManager::~VideoOutputManager() {
  // The engine can finish unregister callbacks after this destructor returns.
  // Each callback retains its own resources.
  shutting_down_ = true;
  // Join the control worker before accessing its output map.
  operations_.reset();
  // Each output releases its resources in its destructor.
  video_outputs_.clear();
}
