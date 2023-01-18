// This file is a part of media_kit
// (https://github.com/alexmercerind/media_kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#ifndef FLUTTER_PLUGIN_MEDIA_KIT_VIDEO_VIDEO_OUTPUT_MANAGER_H_
#define FLUTTER_PLUGIN_MEDIA_KIT_VIDEO_VIDEO_OUTPUT_MANAGER_H_

#include <flutter/plugin_registrar_windows.h>

#include <unordered_map>

#include "video_output.h"

// Creates & disposes |VideoOutput| instances for video embedding inside Flutter
// Windows. |Create| & |Dispose| methods are thread-safe.
class VideoOutputManager {
 public:
  VideoOutputManager(flutter::PluginRegistrarWindows* registrar);

  // Creates a new |VideoOutput| and returns reference to it.
  // It's texture ID may be used to render the video.
  VideoOutput* Create(
      int64_t handle,
      std::optional<int64_t> width,
      std::optional<int64_t> height,
      std::function<void(int64_t, int64_t, int64_t)> texture_update_callback);

  // Destroys the |VideoOutput| with given handle.
  bool Dispose(int64_t handle);

  ~VideoOutputManager();

 private:
  std::mutex render_mutex_ = std::mutex();
  flutter::PluginRegistrarWindows* registrar_ = nullptr;
  std::unordered_map<int64_t, std::unique_ptr<VideoOutput>> video_outputs_ = {};
};

#endif  // FLUTTER_PLUGIN_MEDIA_KIT_VIDEO_VIDEO_OUTPUT_MANAGER_H_
