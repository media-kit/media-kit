// This file is a part of media_kit
// (https://github.com/alexmercerind/media_kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#include "video_output.h"

#include <algorithm>

VideoOutput::VideoOutput(int64_t handle,
                         std::optional<int64_t> width,
                         std::optional<int64_t> height,
                         IDXGIAdapter* adapter)
    : handle_(reinterpret_cast<mpv_handle*>(handle)),
      width_(width_),
      height_(height),
      adapter_(adapter) {}

int64_t VideoOutput::GetVideoWidth() {
  int64_t width = 0;
  mpv_get_property(handle_, "width", MPV_FORMAT_INT64, &width);
  return width;
}

int64_t VideoOutput::GetVideoHeight() {
  int64_t height = 0;
  mpv_get_property(handle_, "height", MPV_FORMAT_INT64, &height);
  return height;
}
