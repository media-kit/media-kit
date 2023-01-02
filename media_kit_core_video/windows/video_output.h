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

  VideoOutput(int64_t handle,
              std::optional<int64_t> width,
              std::optional<int64_t> height,
              flutter::TextureRegistrar* texture_registrar);

  ~VideoOutput();

  void SetTextureUpdateCallback(
      std::function<void(int64_t, int64_t, int64_t)> callback);

 private:
  void Render();

  void Resize(int64_t width, int64_t height);

  int64_t GetVideoWidth();

  int64_t GetVideoHeight();

  mpv_handle* handle_ = nullptr;
  mpv_render_context* render_context_ = nullptr;
  std::optional<int64_t> height_ = std::nullopt;
  std::optional<int64_t> width_ = std::nullopt;
  int64_t texture_id_ = 0;
  flutter::TextureRegistrar* texture_registrar_ = nullptr;
  std::unique_ptr<flutter::TextureVariant> texture_variant_ = nullptr;

  // H/W
  std::unique_ptr<ANGLESurfaceManager> surface_manager_ = nullptr;
  std::unique_ptr<FlutterDesktopGpuSurfaceDescriptor> texture_ = nullptr;
  // S/W
  std::unique_ptr<uint8_t[]> pixel_buffer_ = nullptr;
  std::unique_ptr<FlutterDesktopPixelBuffer> pixel_buffer_texture_ = nullptr;

  std::mutex mutex_ = std::mutex();
  std::function<void(int64_t, int64_t, int64_t)> texture_update_callback_ =
      [](int64_t, int64_t, int64_t) {};
};

#endif  // FLUTTER_PLUGIN_MEDIA_KIT_CORE_VIDEO_VIDEO_OUTPUT_H_
