// This file is a part of media_kit
// (https://github.com/media-kit/media-kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#ifndef VIDEO_OUTPUT_MANAGER_H_
#define VIDEO_OUTPUT_MANAGER_H_

#include <flutter/plugin_registrar_windows.h>

#include <unordered_map>

#include "thread_pool.h"
#include "video_output.h"

// Manage video outputs for embedded playback.
//
// Create, SetSize, and Dispose run on the control worker.
// All outputs share one rendering worker.
class VideoOutputManager {
 public:
  VideoOutputManager(flutter::TextureRegistrar* registrar,
                     Microsoft::WRL::ComPtr<IDXGIAdapter> adapter = nullptr);

  // Create one output per handle. The callback reports the texture ID and size.
  // It runs on a background thread at registration and after a resize.
  // Send platform messages from the Flutter platform thread.
  void Create(
      int64_t handle,
      VideoOutputConfiguration configuration,
      std::function<void(int64_t, int64_t, int64_t)> texture_update_callback,
      std::function<void(std::string)> completion);

  // Pass nullopt to use the video dimension for that axis.
  // The rendering worker applies the size change even during pause.
  void SetSize(int64_t handle,
               std::optional<int64_t> width,
               std::optional<int64_t> height);

  // Destroy the output for this handle.
  void Dispose(int64_t handle, std::function<void()> completion);

  ~VideoOutputManager();

 private:
  // All outputs use the same adapter and rendering worker.
  Microsoft::WRL::ComPtr<IDXGIAdapter> adapter_;
  std::unique_ptr<ThreadPool> thread_pool_ = std::make_unique<ThreadPool>(1);
  flutter::TextureRegistrar* registrar_ = nullptr;
  std::atomic<bool> shutting_down_{false};
  std::unordered_map<int64_t, std::unique_ptr<VideoOutput>> video_outputs_ = {};
  // The control worker processes platform calls in order.
  // It can wait for rendering and texture release during destruction.
  std::unique_ptr<ThreadPool> operations_ = std::make_unique<ThreadPool>(1);
};

#endif  // VIDEO_OUTPUT_MANAGER_H_
