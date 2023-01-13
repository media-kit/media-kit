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
#include <render.h>
#include <render_gl.h>

#include <memory>
#include <mutex>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include "angle_surface_manager.h"

class VideoOutput {
 public:
  int64_t texture_id() const { return texture_id_; }
  int64_t width() const {
    // H/W
    if (surface_manager_width_ && surface_manager_height_) {
      return surface_managers_
          .at(surface_manager_width_ ^ surface_manager_height_)
          ->width();
    }
    // S/W
    if (pixel_buffer_ != nullptr) {
      return pixel_buffer_texture_->width;
    }
    return width_.value_or(1);
  }
  int64_t height() const {
    // H/W
    if (surface_manager_width_ && surface_manager_height_) {
      return surface_managers_
          .at(surface_manager_width_ ^ surface_manager_height_)
          ->height();
    }
    // S/W
    if (pixel_buffer_ != nullptr) {
      return pixel_buffer_texture_->height;
    }
    return height_.value_or(1);
  }

  VideoOutput(int64_t handle,
              std::optional<int64_t> width,
              std::optional<int64_t> height,
              flutter::PluginRegistrarWindows* registrar);

  ~VideoOutput();

  void SetTextureUpdateCallback(
      std::function<void(int64_t, int64_t, int64_t)> callback);

 private:
  void NotifyRender();

  void Render();

  void CheckAndResize();

  void Resize(int64_t required_width, int64_t required_height);

  int64_t GetVideoWidth();

  int64_t GetVideoHeight();

  mpv_handle* handle_ = nullptr;
  mpv_render_context* render_context_ = nullptr;
  std::optional<int64_t> height_ = std::nullopt;
  std::optional<int64_t> width_ = std::nullopt;
  int64_t texture_id_ = 0;
  flutter::PluginRegistrarWindows* registrar_ = nullptr;
  std::unique_ptr<flutter::TextureVariant> texture_variant_ = nullptr;

  // WIP:

  uint64_t dropped_frame_count_ = 0;

  std::mutex notify_render_mutex_ = std::mutex();
  std::mutex render_mutex_ = std::mutex();

  // H/W rendering.

  std::unordered_map<size_t, std::unique_ptr<ANGLESurfaceManager>>
      surface_managers_ = {};
  int64_t surface_manager_width_ = 0;
  int64_t surface_manager_height_ = 0;
  std::unique_ptr<FlutterDesktopGpuSurfaceDescriptor> texture_ = nullptr;

  // S/W rendering.

  std::unique_ptr<uint8_t[]> pixel_buffer_ = nullptr;
  std::unique_ptr<FlutterDesktopPixelBuffer> pixel_buffer_texture_ = nullptr;

  // Public notifier. This is called when a new texture is registered & texture
  // ID is changed. Only happens when video output resolution changes.
  std::function<void(int64_t, int64_t, int64_t)> texture_update_callback_ =
      [](int64_t, int64_t, int64_t) {};

  // Cached monitor refresh rates.
  std::unordered_map<HMONITOR, int64_t> monitor_refresh_rates_ = {};
};

#endif  // FLUTTER_PLUGIN_MEDIA_KIT_CORE_VIDEO_VIDEO_OUTPUT_H_
