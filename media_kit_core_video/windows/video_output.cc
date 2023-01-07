// This file is a part of media_kit
// (https://github.com/alexmercerind/media_kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#include "video_output.h"

#include <algorithm>

// Only used for fallback software rendering, when hardware does not support
// DirectX 11 i.e. enough to support ANGLE. There is no way I'm allowing
// rendering anything higher 1080p with CPU on some retarded old computer. The
// thing might blow up in flames.
#define SW_RENDERING_MAX_WIDTH 1920
#define SW_RENDERING_MAX_HEIGHT 1080
#define SW_RENDERING_PIXEL_BUFFER_SIZE \
  SW_RENDERING_MAX_WIDTH* SW_RENDERING_MAX_HEIGHT * 4

VideoOutput::VideoOutput(int64_t handle,
                         std::optional<int64_t> width,
                         std::optional<int64_t> height,
                         flutter::PluginRegistrarWindows* registrar)
    : handle_(reinterpret_cast<mpv_handle*>(handle)),
      width_(width),
      height_(height),
      registrar_(registrar) {
  // First try to initialize video playback with hardware acceleration &
  // |ANGLESurfaceManager|, use S/W API as fallback.
  auto is_hardware_acceleration_enabled = false;
  // Attempt to use H/W rendering.
  try {
    // OpenGL context needs to be set before |mpv_render_context_create|.
    surface_manager_ = std::make_unique<ANGLESurfaceManager>(
        static_cast<int32_t>(width_.value_or(1)),
        static_cast<int32_t>(height_.value_or(1)));
    Resize(width_.value_or(1), height_.value_or(1));
    mpv_opengl_init_params gl_init_params{
        [](auto, auto name) {
          return reinterpret_cast<void*>(eglGetProcAddress(name));
        },
        nullptr,
    };
    mpv_render_param params[] = {
        {MPV_RENDER_PARAM_API_TYPE, MPV_RENDER_API_TYPE_OPENGL},
        {MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, &gl_init_params},
        {MPV_RENDER_PARAM_INVALID, nullptr},
    };
    // Request H/W decoding. Forcing `dxva2-copy` for now.
    mpv_set_option_string(handle_, "hwdec", "dxva2-copy");
    // Create render context.
    if (mpv_render_context_create(&render_context_, handle_, params) == 0) {
      mpv_render_context_set_update_callback(
          render_context_,
          [](void* context) {
            // Notify Flutter that a new frame is available. The actual
            // rendering will take place in the |Render| method, which will be
            // called by Flutter on the render thread.
            auto that = reinterpret_cast<VideoOutput*>(context);
            that->NotifyRender();
          },
          reinterpret_cast<void*>(this));
      // Set flag to true, indicating that H/W rendering is supported.
      is_hardware_acceleration_enabled = true;
      std::cout << "media_kit: VideoOutput: Using H/W rendering." << std::endl;
    }
  } catch (...) {
    // Do nothing.
    // Likely received an |std::runtime_error| from |ANGLESurfaceManager|,
    // which indicates that H/W rendering is not supported.
  }
  if (!is_hardware_acceleration_enabled) {
    std::cout << "media_kit: VideoOutput: Using S/W rendering." << std::endl;
    // Allocate a "large enough" buffer ahead of time.
    pixel_buffer_ = std::make_unique<uint8_t[]>(SW_RENDERING_PIXEL_BUFFER_SIZE);
    Resize(width_.value_or(1), height_.value_or(1));
    mpv_render_param params[] = {
        {MPV_RENDER_PARAM_API_TYPE, MPV_RENDER_API_TYPE_SW},
        {MPV_RENDER_PARAM_INVALID, nullptr},
    };
    if (mpv_render_context_create(&render_context_, handle_, params) == 0) {
      mpv_render_context_set_update_callback(
          render_context_,
          [](void* context) {
            // Notify Flutter that a new frame is available. The actual
            // rendering will take place in the |Render| method, which will be
            // called by Flutter on the render thread.
            auto that = reinterpret_cast<VideoOutput*>(context);
            that->NotifyRender();
          },
          reinterpret_cast<void*>(this));
    }
  };
}

VideoOutput::~VideoOutput() {
  if (texture_id_) {
    registrar_->texture_registrar()->UnregisterTexture(texture_id_);
    texture_id_ = 0;
  }
  if (render_context_) {
    mpv_render_context_free(render_context_);
  }
}

void VideoOutput::NotifyRender() {
  // mpv_* APIs should not be called directly from the libmpv's render context
  // update callback. However, we need to create new texture if the resolution /
  // dimensions of the currently playing video change. Thus, checking for video
  // output dimensions and then, creating / registering new texture &
  // unregistering previous texture accordingly before rendering on Flutter's
  // render thread. Creating new texture(s) instead of using a single one with
  // hardcoded dimensions is good for two reasons:
  // * This will not cause redundant load for videos with lower resolution /
  // dimensions than those hard-coded texture dimensions.
  // * This will not degrade video output quality for videos with higher
  // resolution / dimensions than those hard-coded texture dimensions.
  std::thread([&]() {
    std::lock_guard<std::mutex> lock(notify_render_mutex_);
    CheckAndResize();
    // Ask Flutter to invoke the |Render|.
    if (texture_id_) {
      registrar_->texture_registrar()->MarkTextureFrameAvailable(texture_id_);
    }
  }).detach();
}

void VideoOutput::Render() {
  std::lock_guard<std::mutex> lock(render_mutex_);
  // H/W
  if (surface_manager_ != nullptr) {
    surface_manager_->MakeCurrent(true);
    // Render frame.
    mpv_opengl_fbo fbo{
        0,
        surface_manager_->width(),
        surface_manager_->height(),
        0,
    };
    mpv_render_param params[]{
        {MPV_RENDER_PARAM_OPENGL_FBO, &fbo},
        {MPV_RENDER_PARAM_INVALID, nullptr},
    };
    mpv_render_context_render(render_context_, params);
    // Some GPUs/Hardware seem to cause black flickering when rendering with
    // hardware acceleration. Calling |glFinish| eliminates this. This seems to
    // be some sort of synchronization problem between Flutter / Monitor / mpv
    // etc. This method is invoked directly on the Flutter's render thread, so I
    // don't think there's anything better that can be done.
    //
    // Personally, my budget machine with AMD Ryzen 3 2200U with integrated
    // Radeon Vega 3 Mobile Graphics never experienced this issue.
    // At most, 4K 30FPS or 1080p 60FPS videos play flawlessly without any major
    // load on the hardware. 4K 60FPS videos certainly experience frame drops.
    glFinish();
    surface_manager_->MakeCurrent(false);
  }
  // S/W
  if (pixel_buffer_ != nullptr) {
    int32_t size[]{static_cast<int32_t>(pixel_buffer_texture_->width),
                   static_cast<int32_t>(pixel_buffer_texture_->height)};
    auto pitch = static_cast<int32_t>(pixel_buffer_texture_->width) * 4;
    mpv_render_param params[]{
        {MPV_RENDER_PARAM_SW_SIZE, size},
        {MPV_RENDER_PARAM_SW_FORMAT, "rgb0"},
        {MPV_RENDER_PARAM_SW_STRIDE, &pitch},
        {MPV_RENDER_PARAM_SW_POINTER, pixel_buffer_.get()},
        {MPV_RENDER_PARAM_INVALID, nullptr},
    };
    mpv_render_context_render(render_context_, params);
  }
}

void VideoOutput::SetTextureUpdateCallback(
    std::function<void(int64_t, int64_t, int64_t)> callback) {
  texture_update_callback_ = callback;
}

void VideoOutput::CheckAndResize() {
  // Check if a new texture with different dimensions is needed.
  auto required_width = GetVideoWidth(), required_height = GetVideoHeight();
  if (required_width < 1 || required_height < 1) {
    // Invalid.
    return;
  }
  int64_t current_width = -1, current_height = -1;
  if (surface_manager_ != nullptr) {
    current_width = surface_manager_->width();
    current_height = surface_manager_->height();
  }
  if (pixel_buffer_ != nullptr) {
    current_width = pixel_buffer_texture_->width;
    current_height = pixel_buffer_texture_->height;
  }
  // Currently rendered video output dimensions.
  // Either H/W or S/W rendered.
  assert(current_width > 0);
  assert(current_height > 0);
  if (required_width == current_width && required_height == current_height) {
    // No creation of new texture required.
    return;
  }
  Resize(required_width, required_height);
}

void VideoOutput::Resize(int64_t required_width, int64_t required_height) {
  std::cout << required_width << " " << required_height << std::endl;
  // Unregister previously registered texture.
  if (texture_id_) {
    registrar_->texture_registrar()->UnregisterTexture(texture_id_);
    texture_id_ = 0;
  }
  // H/W
  if (surface_manager_ != nullptr) {
    // Destroy internal ID3D11Texture2D & EGLSurface & create new with updated
    // dimensions while preserving previous EGLDisplay & EGLContext.
    surface_manager_->HandleResize(static_cast<int32_t>(required_width),
                                   static_cast<int32_t>(required_height));
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
            kFlutterDesktopGpuSurfaceTypeDxgiSharedHandle, [&](auto, auto) {
              Render();
              return texture_.get();
            }));
    // Register new texture.
    if (texture_variant_ != nullptr) {
      texture_id_ = registrar_->texture_registrar()->RegisterTexture(
          texture_variant_.get());
      std::cout << "media_kit: VideoOutput: Texture ID: " << texture_id_
                << std::endl;
      // Notify public texture update callback.
      texture_update_callback_(texture_id_, surface_manager_->width(),
                               surface_manager_->height());
    }
  }
  // S/W
  if (pixel_buffer_ != nullptr) {
    pixel_buffer_texture_ = std::make_unique<FlutterDesktopPixelBuffer>();
    pixel_buffer_texture_->buffer = pixel_buffer_.get();
    pixel_buffer_texture_->width = required_width;
    pixel_buffer_texture_->height = required_height;
    pixel_buffer_texture_->release_context = nullptr;
    pixel_buffer_texture_->release_callback = [](void*) {};
    texture_variant_ = std::make_unique<flutter::TextureVariant>(
        flutter::PixelBufferTexture([&](auto, auto) {
          Render();
          return pixel_buffer_texture_.get();
        }));
    // Register new texture.
    if (texture_variant_ != nullptr) {
      texture_id_ = registrar_->texture_registrar()->RegisterTexture(
          texture_variant_.get());
      std::cout << "media_kit: VideoOutput: Texture ID: " << texture_id_
                << std::endl;
      // Notify public texture update callback.
      texture_update_callback_(texture_id_, pixel_buffer_texture_->width,
                               pixel_buffer_texture_->height);
    }
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
  if (pixel_buffer_ != nullptr) {
    // Limit width if software rendering is being used.
    return std::clamp(width, static_cast<int64_t>(0),
                      static_cast<int64_t>(SW_RENDERING_MAX_WIDTH));
  }
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
  if (pixel_buffer_ != nullptr) {
    // Limit width if software rendering is being used.
    return std::clamp(height, static_cast<int64_t>(0),
                      static_cast<int64_t>(SW_RENDERING_MAX_HEIGHT));
  }
  return height;
}
