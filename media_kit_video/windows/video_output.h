// This file is a part of media_kit
// (https://github.com/media-kit/media-kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#ifndef VIDEO_OUTPUT_H_
#define VIDEO_OUTPUT_H_

#include <optional>

#include <client.h>
#include <render.h>
#include <render_gl.h>

#include <future>
#include <memory>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include "angle_surface_manager.h"
#include "thread_pool.h"

typedef struct _VideoOutputConfiguration {
  std::optional<int64_t> width;
  std::optional<int64_t> height;
  bool enable_hardware_acceleration;

  _VideoOutputConfiguration(std::optional<int64_t> width = std::nullopt,
                            std::optional<int64_t> height = std::nullopt,
                            bool enable_hardware_acceleration = true)
      : width(width),
        height(height),
        enable_hardware_acceleration(enable_hardware_acceleration) {}
} VideoOutputConfiguration;

class VideoOutput {
 public:
  int64_t texture_id() const { return texture_id_; }
  int64_t width() const {
    // H/W
    if (surface_manager_ != nullptr && texture_id_) {
      return surface_manager_->width();
    }
    // S/W
    if (pixel_buffer_ != nullptr && texture_id_) {
      return pixel_buffer_textures_.at(texture_id_)->width;
    }
    return width_.value_or(1);
  }
  int64_t height() const {
    // H/W
    if (surface_manager_ != nullptr && texture_id_) {
      return surface_manager_->height();
    }
    // S/W
    if (pixel_buffer_ != nullptr && texture_id_) {
      return pixel_buffer_textures_.at(texture_id_)->height;
    }
    return height_.value_or(1);
  }

  VideoOutput(int64_t handle,
              VideoOutputConfiguration configuration,
              flutter::PluginRegistrarWindows* registrar,
              ThreadPool* thread_pool_ref);

  ~VideoOutput();

  void SetTextureUpdateCallback(
      std::function<void(int64_t, int64_t, int64_t)> callback);

  void SetSize(std::optional<int64_t> width, std::optional<int64_t> height);

 private:
  void NotifyRender();

  void Render();

  void CheckAndResize();

  void Resize(int64_t required_width, int64_t required_height);

  int64_t GetVideoWidth();

  int64_t GetVideoHeight();

  std::optional<int64_t> height_ = std::nullopt;
  std::optional<int64_t> width_ = std::nullopt;
  VideoOutputConfiguration configuration_ = VideoOutputConfiguration{};

  mpv_handle* handle_ = nullptr;
  mpv_render_context* render_context_ = nullptr;
  int64_t texture_id_ = 0;
  flutter::PluginRegistrarWindows* registrar_ = nullptr;
  ThreadPool* thread_pool_ref_ = nullptr;
  // For preventing any asynchronous operations (primarily texture objects
  // deletion after unregister in |Resize|) access this object after
  // destruction.
  bool destroyed_ = false;

  std::mutex textures_mutex_ = std::mutex();

  std::unordered_map<int64_t, std::unique_ptr<flutter::TextureVariant>>
      texture_variants_ = {};

  // H/W rendering.

  std::unique_ptr<ANGLESurfaceManager> surface_manager_ = nullptr;
  std::unordered_map<int64_t,
                     std::unique_ptr<FlutterDesktopGpuSurfaceDescriptor>>
      textures_ = {};

  // S/W rendering.

  std::unique_ptr<uint32_t[]> pixel_buffer_ = nullptr;
  std::unordered_map<int64_t, std::unique_ptr<FlutterDesktopPixelBuffer>>
      pixel_buffer_textures_ = {};

  // Public notifier. This is called when a new texture is registered & texture
  // ID is changed. Only happens when video output resolution changes.
  std::function<void(int64_t, int64_t, int64_t)> texture_update_callback_ =
      [](int64_t, int64_t, int64_t) {};
};

#endif  // VIDEO_OUTPUT_H_
