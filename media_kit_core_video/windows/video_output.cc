// This file is a part of media_kit
// (https://github.com/alexmercerind/media_kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#include "video_output.h"

VideoOutput::VideoOutput(int64_t handle,
                         std::optional<int64_t> width,
                         std::optional<int64_t> height,
                         IDXGIAdapter* adapter,
                         flutter::TextureRegistrar* texture_registrar)
    : handle_(reinterpret_cast<mpv_handle*>(handle)),
      width_(width),
      height_(height),
      adapter_(adapter),
      texture_registrar_(texture_registrar) {
  if (adapter_ != nullptr) {
    std::cout << "media_kit: VideoOutput: Using H/W rendering." << std::endl;
    // H/W acceleration is supported.
    // OpenGL context needs to be set before
    // |mpv_render_context_create|.
    surface_manager_ = std::make_unique<ANGLESurfaceManager>(1, 1, adapter_);
    mpv_opengl_init_params gl_init_params{
        [](auto, auto name) {
          return reinterpret_cast<void*>(eglGetProcAddress(name));
        },
        nullptr,
    };
    mpv_render_param params[]{
        {
            MPV_RENDER_PARAM_API_TYPE,
            MPV_RENDER_API_TYPE_OPENGL,
        },
        {
            MPV_RENDER_PARAM_OPENGL_INIT_PARAMS,
            &gl_init_params,
        },
        {
            MPV_RENDER_PARAM_INVALID,
            nullptr,
        },
    };
    // Request H/W decoding.
    mpv_set_option_string(handle_, "hwdec", "auto");
    // Create render context.
    if (mpv_render_context_create(&render_context_, handle_, params) == 0) {
      mpv_render_context_set_update_callback(
          render_context_,
          [](void* ctx) -> void {
            reinterpret_cast<VideoOutput*>(ctx)->Render();
          },
          reinterpret_cast<void*>(this));
    }
  } else {
    std::cout << "media_kit: VideoOutput: Using S/W rendering." << std::endl;
    // TODO(@alexmercerind): S/W rendering.
  }
}

VideoOutput::~VideoOutput() {
  if (render_context_) {
    mpv_render_context_free(render_context_);
  }
  surface_manager_.reset(nullptr);
}

void VideoOutput::Render() {
  // libmpv APIs cannot be called directly from the
  // |mpv_render_context_set_update_callback| callback, otherwise it results in
  // a deadlock. Spawning a new detached thread to perform the rendering.
  std::thread([&]() {
    std::lock_guard<std::mutex> lock(mutex_);
    auto width = GetVideoWidth();
    auto height = GetVideoHeight();
    if (surface_manager_ != nullptr && width > 0 && height > 0) {
      if (width != surface_manager_->width() ||
          height != surface_manager_->height()) {
        // A new video has been started. A change in output resolution.
        Resize(width, height);
      }
      // Acquire context.
      surface_manager_->MakeCurrent(true);
      // Render frame.
      mpv_opengl_fbo fbo{
          0,
          surface_manager_->width(),
          surface_manager_->height(),
          0,
      };
      // No flipping needed.
      mpv_render_param params[] = {
          {MPV_RENDER_PARAM_OPENGL_FBO, &fbo},
          {MPV_RENDER_PARAM_INVALID, nullptr},
      };
      mpv_render_context_render(render_context_, params);
      surface_manager_->SwapBuffers();
      texture_registrar_->MarkTextureFrameAvailable(texture_id_);
      // Release context.
      surface_manager_->MakeCurrent(false);
    }
  }).detach();
}

void VideoOutput::SetTextureUpdateCallback(
    std::function<void(int64_t, int64_t, int64_t)> callback) {
  texture_update_callback_ = callback;
}

void VideoOutput::Resize(int64_t width, int64_t height) {
  std::cout << "media_kit: VideoOutput: Resize: " << width << " " << height
            << std::endl;
  // Unregister previously registered texture.
  if (texture_id_) {
    texture_registrar_->UnregisterTexture(texture_id_);
    texture_id_ = 0;
  }
  if (surface_manager_) {
    // Register new texture.
    surface_manager_->HandleResize(static_cast<int32_t>(width),
                                   static_cast<int32_t>(height));
    texture_ = std::make_unique<FlutterDesktopGpuSurfaceDescriptor>();
    texture_->struct_size = sizeof(FlutterDesktopGpuSurfaceDescriptor);
    texture_->handle = surface_manager_->handle();
    texture_->width = texture_->visible_width = surface_manager_->width();
    texture_->height = texture_->visible_height = surface_manager_->height();
    texture_->release_context = nullptr;
    texture_->release_callback = [](void*) {};
    texture_->format = kFlutterDesktopPixelFormatBGRA8888;
    texture_variant_ =
        std::make_unique<flutter::TextureVariant>(flutter::GpuSurfaceTexture(
            kFlutterDesktopGpuSurfaceTypeDxgiSharedHandle,
            [&](auto, auto) { return texture_.get(); }));
    texture_id_ = texture_registrar_->RegisterTexture(texture_variant_.get());
    std::cout << "media_kit: VideoOutput: Texture ID: " << texture_id_
              << std::endl;
    // Notify public texture update callback.
    texture_update_callback_(texture_id_, surface_manager_->width(),
                             surface_manager_->height());
  }
}

int64_t VideoOutput::GetVideoWidth() {
  // Fixed width.
  if (width_) {
    return width_.value();
  }
  // Video resolution dependent width.
  int64_t width = 0;
  mpv_get_property(handle_, "width", MPV_FORMAT_INT64, &width);
  return width;
}

int64_t VideoOutput::GetVideoHeight() {
  // Fixed height.
  if (height_) {
    return height_.value();
  }
  // Video resolution dependent height.
  int64_t height = 0;
  mpv_get_property(handle_, "height", MPV_FORMAT_INT64, &height);
  return height;
}
