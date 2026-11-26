// This file is a part of media_kit
// (https://github.com/media-kit/media-kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#include "video_output.h"

#include <algorithm>
#include <cstring>
#include <iostream>
#include <stdexcept>

namespace {
// The software renderer scales the frame before rotation.
// The GPU renderer applies rotation itself.
void RotateSoftwareFrame(const uint8_t* source, uint8_t* destination,
                         int width, int height, int clockwise) {
  const int output_width = clockwise == 180 ? width : height;
  for (int y = 0; y < height; ++y) {
    int index;
    int step;
    if (clockwise == 90) {
      index = height - 1 - y;
      step = output_width;
    } else if (clockwise == 270) {
      index = (width - 1) * output_width + y;
      step = -output_width;
    } else {
      index = (height - y) * output_width - 1;
      step = -1;
    }
    for (int x = 0; x < width; ++x, index += step, source += 4)
      std::memcpy(destination + index * 4, source, 4);
  }
}
}  // namespace

VideoOutput::VideoOutput(int64_t handle,
                         VideoOutputConfiguration configuration,
                         flutter::TextureRegistrar* registrar,
                         ThreadPool* thread_pool_ref,
                         const std::atomic<bool>* shutting_down,
                         IDXGIAdapter* adapter)
    : width_(configuration.width),
      height_(configuration.height),
      configuration_(configuration),
      handle_(reinterpret_cast<mpv_handle*>(handle)),
      registrar_(registrar),
      thread_pool_ref_(thread_pool_ref),
      shutting_down_(shutting_down) {
  // All outputs share one worker for D3D11 and libmpv rendering.
  auto future = thread_pool_ref_->Post([this, configuration, adapter]() {
    try {
      mpv_set_option_string(handle_, "video-sync", "audio");
      mpv_set_option_string(handle_, "video-timing-offset", "0");
      std::shared_ptr<D3D11SurfaceManager::Surface> first_target;
      if (configuration.enable_hardware_acceleration) {
        try {
          surface_manager_ = std::make_unique<D3D11SurfaceManager>(adapter);
          const auto size =
              media_kit::ResolveVideoFrameSize(1, 1, 0, width_, height_, false)
                  .value_or(media_kit::VideoFrameSize{1, 1});
          first_target =
              surface_manager_->CreateSurface(size.width, size.height);
          mpv_d3d11_init_params init{surface_manager_->device()};
          mpv_render_param params[] = {
              {MPV_RENDER_PARAM_API_TYPE, MPV_RENDER_API_TYPE_D3D11},
              {MPV_RENDER_PARAM_D3D11_INIT_PARAMS, &init},
              {MPV_RENDER_PARAM_INVALID, nullptr}};
          const auto error =
              mpv_render_context_create(&render_context_, handle_, params);
          if (error < 0)
            throw std::runtime_error(mpv_error_string(error));
        } catch (const std::exception& error) {
          std::cerr << "media_kit: D3D11 fallback: " << error.what()
                    << std::endl;
          first_target.reset();
          surface_manager_.reset();
        }
      }
      software_ = !surface_manager_;
      if (software_) {
        mpv_render_param params[] = {
            {MPV_RENDER_PARAM_API_TYPE, MPV_RENDER_API_TYPE_SW},
            {MPV_RENDER_PARAM_INVALID, nullptr}};
        const auto error =
            mpv_render_context_create(&render_context_, handle_, params);
        if (error < 0)
          throw std::runtime_error(mpv_error_string(error));
      }
      const auto size =
          media_kit::ResolveVideoFrameSize(1, 1, 0, width_, height_, software_)
              .value_or(media_kit::VideoFrameSize{1, 1});
      Resize(size.width, size.height, std::move(first_target));
      mpv_render_context_set_update_callback(
          render_context_,
          [](void* context) {
            static_cast<VideoOutput*>(context)->NotifyRender();
          },
          this);
      std::cout << "media_kit: VideoOutput: Using "
                << (software_ ? "S/W" : "D3D11") << " rendering." << std::endl;
    } catch (...) {
      CleanUp();
      throw;
    }
  });
  // Wait for initialization. Report any error to the caller.
  future.get();
}

VideoOutput::~VideoOutput() {
  {
    std::lock_guard<std::mutex> lock(notification_mutex_);
    destroyed_ = true;
  }
  // The worker finishes all accepted tasks before cleanup.
  // The shutdown flag blocks new render requests.
  // Unregister callbacks retain their own resources.
  thread_pool_ref_->Post([this]() { CleanUp(); }).get();
  for (auto& retirement : retirements_) {
    while (retirement.wait_for(std::chrono::milliseconds(10)) !=
           std::future_status::ready) {
      if (shutting_down_ && shutting_down_->load())
        break;
    }
  }
}

void VideoOutput::CleanUp() {
  if (render_context_) {
    mpv_render_context_set_update_callback(render_context_, nullptr, nullptr);
    mpv_render_context_free(render_context_);
    render_context_ = nullptr;
  }
  RetireTexture();
  surface_manager_.reset();
}

void VideoOutput::RetireTexture() {
  if (!texture_)
    return;
  auto retired = std::move(texture_);
  auto completion = std::make_shared<std::promise<void>>();
  retirements_.erase(
      std::remove_if(retirements_.begin(), retirements_.end(),
                     [](auto& future) {
                       return future.wait_for(std::chrono::seconds(0)) ==
                              std::future_status::ready;
                     }),
      retirements_.end());
  retirements_.push_back(completion->get_future());
  const auto id = retired->id;
  registrar_->UnregisterTexture(
      id, [retired = std::move(retired), completion]() mutable {
        // Keep the callback, descriptors, and COM references alive until
        // the engine releases this registration.
        retired.reset();
        completion->set_value();
      });
}

void VideoOutput::NotifyRender() {
  std::lock_guard<std::mutex> lock(notification_mutex_);
  if (destroyed_ || render_queued_)
    return;
  thread_pool_ref_->Post([this]() {
    {
      std::lock_guard<std::mutex> notification_lock(notification_mutex_);
      // Updates during this render may queue one more pass for this output.
      render_queued_ = false;
      if (destroyed_)
        return;
    }
    try {
      CheckAndResize();
      Render();
    } catch (const std::exception& error) {
      std::cerr << "media_kit: VideoOutput render failed: " << error.what()
                << std::endl;
    }
  });
  render_queued_ = true;
}

void VideoOutput::Render() {
  if (!texture_ || !render_context_)
    return;
  const auto& frame = texture_->frame;
  if (surface_manager_) {
    auto target = std::move(frame->first_target);
    if (!target)
      target = surface_manager_->CreateSurface(frame->size.width,
                                               frame->size.height);
    mpv_d3d11_fbo fbo{target->texture.Get()};
    mpv_render_param params[] = {{MPV_RENDER_PARAM_D3D11_FBO, &fbo},
                                 {MPV_RENDER_PARAM_INVALID, nullptr}};
    const auto error = mpv_render_context_render(render_context_, params);
    if (error < 0)
      throw std::runtime_error(mpv_error_string(error));
    surface_manager_->WaitForWrites();
    std::atomic_store(&frame->latest, std::move(target));
  } else {
    // Flutter releases this lock only after uploading the returned pixel data.
    std::lock_guard<std::mutex> lock(frame->pixels_mutex);
    const auto layout =
        media_kit::GetSoftwareFrameLayout(frame->size, frame->pixels.size());
    if (!layout)
      throw std::runtime_error("Invalid software frame capacity");
    int size[]{frame->size.width, frame->size.height};
    size_t stride = layout->stride;
    auto* pixels = frame->pixels.data();
    if (software_rotation_) {
      if (software_rotation_ != 180)
        std::swap(size[0], size[1]);
      stride = static_cast<size_t>(size[0]) * 4;
      unrotated_pixels_.resize(layout->bytes);
      pixels = unrotated_pixels_.data();
    }
    mpv_render_param params[] = {
        {MPV_RENDER_PARAM_SW_SIZE, size},
        {MPV_RENDER_PARAM_SW_FORMAT, "rgb0"},
        {MPV_RENDER_PARAM_SW_STRIDE, &stride},
        {MPV_RENDER_PARAM_SW_POINTER, pixels},
        {MPV_RENDER_PARAM_INVALID, nullptr}};
    const auto error = mpv_render_context_render(render_context_, params);
    if (error < 0)
      throw std::runtime_error(mpv_error_string(error));
    if (software_rotation_)
      RotateSoftwareFrame(pixels, frame->pixels.data(), size[0], size[1],
                          software_rotation_);
  }
  registrar_->MarkTextureFrameAvailable(texture_->id);
}

void VideoOutput::SetTextureUpdateCallback(
    std::function<void(int64_t, int64_t, int64_t)> callback) {
  thread_pool_ref_
      ->Post([this, callback = std::move(callback)]() {
        texture_update_callback_ = callback;
        const auto size = GetVideoSize();
        texture_update_callback_(texture_->id, size ? size->width : 0,
                                 size ? size->height : 0);
      })
      .get();
}

void VideoOutput::SetSize(std::optional<int64_t> width,
                          std::optional<int64_t> height) {
  thread_pool_ref_->Post([this, width, height]() {
    if (destroyed_)
      return;
    width_ = width;
    height_ = height;
    // A paused player may never issue another update callback.
    try {
      CheckAndResize();
      Render();
    } catch (const std::exception& error) {
      std::cerr << "media_kit: VideoOutput resize failed: " << error.what()
                << std::endl;
    }
  });
}

void VideoOutput::CheckAndResize() {
  const auto size = GetVideoSize();
  if (!size)
    return;
  if (texture_ && texture_->frame->size.width == size->width &&
      texture_->frame->size.height == size->height)
    return;
  Resize(size->width, size->height);
}

void VideoOutput::Resize(
    int64_t required_width,
    int64_t required_height,
    std::shared_ptr<D3D11SurfaceManager::Surface> first_target) {
  auto next = std::make_shared<TextureRegistration>();
  auto frame = std::make_shared<Frame>();
  frame->size = {static_cast<int32_t>(required_width),
                 static_cast<int32_t>(required_height)};
  next->frame = frame;
  const auto register_texture = [&]() {
    next->id = registrar_->RegisterTexture(next->variant.get());
    if (next->id < 0)
      throw std::runtime_error("Flutter texture registration failed");
  };
  if (surface_manager_) {
    // Allocate the new surface before replacing the current registration.
    frame->first_target = first_target
                              ? std::move(first_target)
                              : surface_manager_->CreateSurface(
                                    frame->size.width, frame->size.height);
    auto& descriptor = frame->gpu_descriptor;
    descriptor.struct_size = sizeof(descriptor);
    descriptor.width = descriptor.visible_width = frame->size.width;
    descriptor.height = descriptor.visible_height = frame->size.height;
    descriptor.format = kFlutterDesktopPixelFormatBGRA8888;
    next->variant =
        std::make_unique<flutter::TextureVariant>(flutter::GpuSurfaceTexture(
            kFlutterDesktopGpuSurfaceTypeDxgiSharedHandle,
            [frame](auto, auto) -> const FlutterDesktopGpuSurfaceDescriptor* {
              frame->imported = std::atomic_load(&frame->latest);
              if (!frame->imported)
                return nullptr;
              frame->gpu_descriptor.handle = frame->imported->handle;
              return &frame->gpu_descriptor;
            }));
    register_texture();
  } else {
    const auto layout = media_kit::GetSoftwareFrameLayout(
        frame->size, media_kit::kSoftwareBufferCapacity);
    if (!layout)
      throw std::runtime_error("Invalid software texture size");
    frame->pixels.resize(layout->bytes);
    auto& descriptor = frame->pixel_descriptor;
    descriptor.buffer = frame->pixels.data();
    descriptor.width = frame->size.width;
    descriptor.height = frame->size.height;
    descriptor.release_context = frame.get();
    descriptor.release_callback = [](void* context) {
      static_cast<Frame*>(context)->pixels_mutex.unlock();
    };
    next->variant = std::make_unique<flutter::TextureVariant>(
        flutter::PixelBufferTexture([frame](auto, auto) {
          frame->pixels_mutex.lock();
          return &frame->pixel_descriptor;
        }));
    register_texture();
  }
  // The new callback owns its resources before Flutter can call it.
  RetireTexture();
  texture_ = std::move(next);
  texture_update_callback_(texture_->id, required_width, required_height);
}
std::optional<media_kit::VideoFrameSize> VideoOutput::GetVideoSize() {
  int64_t dw = 0, dh = 0, rotate = 0;
  // Read both dimensions from the same mpv property.
  // mpv can omit this property before playback or for audio-only media.
  mpv_node params{};
  if (mpv_get_property(handle_, "video-out-params", MPV_FORMAT_NODE, &params) >=
      0) {
    if (params.format == MPV_FORMAT_NODE_MAP && params.u.list != nullptr) {
      for (int32_t i = 0; i < params.u.list->num; ++i) {
        const char* key = params.u.list->keys[i];
        const auto& value = params.u.list->values[i];
        if (key != nullptr && value.format == MPV_FORMAT_INT64) {
          if (strcmp(key, "dw") == 0)
            dw = value.u.int64;
          if (strcmp(key, "dh") == 0)
            dh = value.u.int64;
          if (strcmp(key, "rotate") == 0)
            rotate = value.u.int64;
        }
      }
    }
    mpv_free_node_contents(&params);
  }
  if (software_) {
    const int angle = static_cast<int>((rotate % 360 + 360) % 360);
    software_rotation_ = angle % 90 == 0 ? angle : 0;
  }
  return media_kit::ResolveVideoFrameSize(dw, dh, rotate, width_, height_,
                                          software_);
}
