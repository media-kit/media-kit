// This file is a part of media_kit
// (https://github.com/alexmercerind/media_kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#ifndef FLUTTER_PLUGIN_MEDIA_KIT_CORE_VIDEO_VIDEO_OUTPUT_H_
#define FLUTTER_PLUGIN_MEDIA_KIT_CORE_VIDEO_VIDEO_OUTPUT_H_

#include <optional>

#include <client.h>

#include "angle_surface_manager.h"

class VideoOutput {
 public:
  VideoOutput(int64_t handle,
              std::optional<int64_t> width,
              std::optional<int64_t> height,
              IDXGIAdapter* adapter);

  ~VideoOutput();

 private:
  int64_t GetVideoWidth();

  int64_t GetVideoHeight();

  mpv_handle* handle_ = nullptr;
  std::optional<int64_t> height_ = std::nullopt;
  std::optional<int64_t> width_ = std::nullopt;
  IDXGIAdapter* adapter_ = nullptr;
  ANGLESurfaceManager* surface_manager_ = nullptr;
};

#endif  // FLUTTER_PLUGIN_MEDIA_KIT_CORE_VIDEO_VIDEO_OUTPUT_H_
