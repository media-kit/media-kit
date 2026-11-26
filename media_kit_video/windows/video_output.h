// This file is a part of media_kit
// (https://github.com/media-kit/media-kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#ifndef VIDEO_OUTPUT_H_
#define VIDEO_OUTPUT_H_

#include <atomic>
#include <optional>
#include <vector>

#include <client.h>
#include <render.h>
#include <render_d3d11.h>

#include <future>
#include <memory>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include "d3d11_surface_manager.h"
#include "thread_pool.h"
#include "video_frame_size.h"

typedef struct _VideoOutputConfiguration {
  std::optional<int64_t> width;
  std::optional<int64_t> height;
  // Try D3D11 first when this flag is true. Fall back to software if setup fails.
  // The mpv hwdec option controls video decoding.
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
  // Create and destroy this output outside the rendering worker.
  // Both operations wait for tasks on that worker.
  // Keep the pool alive until destruction ends.
  VideoOutput(int64_t handle,
              VideoOutputConfiguration configuration,
              flutter::TextureRegistrar* registrar,
              ThreadPool* thread_pool_ref,
              const std::atomic<bool>* shutting_down = nullptr,
              IDXGIAdapter* adapter = nullptr);

  ~VideoOutput();

  // The rendering worker reports the texture ID, width, and height.
  // Send platform messages from the Flutter platform thread.
  void SetTextureUpdateCallback(
      std::function<void(int64_t, int64_t, int64_t)> callback);

  // Pass nullopt to use the video dimension for that axis.
  // The rendering worker resizes and redraws the frame even during pause.
  void SetSize(std::optional<int64_t> width, std::optional<int64_t> height);

 private:
  struct Frame {
    media_kit::VideoFrameSize size;
    std::shared_ptr<D3D11SurfaceManager::Surface> first_target;
    // The rendering worker publishes latest atomically.
    // Only the Flutter raster thread uses imported and the GPU descriptor.
    std::shared_ptr<D3D11SurfaceManager::Surface> latest;
    std::shared_ptr<D3D11SurfaceManager::Surface> imported;
    std::vector<uint8_t> pixels;
    std::mutex pixels_mutex;
    FlutterDesktopGpuSurfaceDescriptor gpu_descriptor{};
    FlutterDesktopPixelBuffer pixel_descriptor{};
  };
  struct TextureRegistration {
    int64_t id = -1;
    std::shared_ptr<Frame> frame;
    std::unique_ptr<flutter::TextureVariant> variant;
  };

  void RetireTexture();
  void CleanUp();
  void NotifyRender();

  void Render();

  void CheckAndResize();

  void Resize(
      int64_t required_width,
      int64_t required_height,
      std::shared_ptr<D3D11SurfaceManager::Surface> first_target = nullptr);

  std::optional<media_kit::VideoFrameSize> GetVideoSize();

  std::optional<int64_t> width_ = std::nullopt;
  std::optional<int64_t> height_ = std::nullopt;
  VideoOutputConfiguration configuration_ = VideoOutputConfiguration{};

  mpv_handle* handle_ = nullptr;
  mpv_render_context* render_context_ = nullptr;
  flutter::TextureRegistrar* registrar_ = nullptr;
  ThreadPool* thread_pool_ref_ = nullptr;
  // The manager outlives its outputs. Unregister callbacks retain retired textures.
  // During shutdown, let the platform thread return to the engine.
  // The engine can then finish the callbacks.
  const std::atomic<bool>* shutting_down_ = nullptr;
  // Use this lock to stop new render requests before teardown.
  std::mutex notification_mutex_;
  bool render_queued_ = false;  // Protected by notification_mutex_.
  std::atomic<bool> destroyed_{false};
  std::unique_ptr<D3D11SurfaceManager> surface_manager_;
  bool software_ = false;
  int software_rotation_ = 0;
  std::vector<uint8_t> unrotated_pixels_;
  std::shared_ptr<TextureRegistration> texture_;
  // Each unregister callback retains only its own texture registration.
  std::vector<std::future<void>> retirements_;
  // Report the first texture. Report later changes to the texture or its size.
  std::function<void(int64_t, int64_t, int64_t)> texture_update_callback_ =
      [](int64_t, int64_t, int64_t) {};
};

#endif  // VIDEO_OUTPUT_H_
