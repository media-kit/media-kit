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

#include "thread_pool.h"
#include "video_output.h"

// Creates & disposes |VideoOutput| instances for video embedding.
//
// The methods in this class are thread-safe & run on separate worker thread so
// that they don't block Flutter's UI thread while platform channels are being
// invoked.
class VideoOutputManager {
 public:
  VideoOutputManager(flutter::PluginRegistrarWindows* registrar);

  // Creates a new |VideoOutput| instance. It's texture ID may be used to render
  // the video. The changes in it's texture ID & video dimensions will be
  // notified via the |texture_update_callback|.
  void Create(
      int64_t handle,
      std::optional<int64_t> width,
      std::optional<int64_t> height,
      std::function<void(int64_t, int64_t, int64_t)> texture_update_callback);

  // Destroys the |VideoOutput| with given handle.
  void Dispose(int64_t handle);

  ~VideoOutputManager();

 private:
  // All the operations involving ANGLE or EGL or libmpv must be performed on
  // same single thread to prevent any race conditions or invalid ANGLE usage.
  // Not doing so results in access violations & crashes.
  //
  // Technically, the correct place to do all the video rendering (& thus
  // resize) etc. is on Flutter's render thread itself (exposed as callback in
  // |flutter::GpuSurfaceTexture| & |flutter::PixelBufferTexture|). However,
  // this slows down the UI too much. So, I decided to create our own
  // |ThreadPool| & use it for all the video rendering purposes through one
  // single thread.
  //
  // Secondly, setting a |std::mutex| was not enough. It still resulted in
  // access violations. Maybe it does not provide a fair mutex, which caused
  // race between resize & render.
  //
  // The following operations are performed through the |ThreadPool|:
  // All of these involve ANGLE or OpenGL context etc. etc.
  //
  // * Rendering of video frame i.e. |mpv_render_context_render| is called
  //   through the |ThreadPool| after being notified by
  //   |mpv_render_context_set_update_callback|.
  // * Creation / Disposal of new |VideoOutput| i.e.
  //   |VideoOutputManager::Create| & |VideoOutputManager::Dispose| are called
  //   through the |ThreadPool|. Thus, |mpv_render_context_create| is called &
  //   instantiation of a new |ANGLESurfaceManager| is done through |ThreadPool|
  //   (in |VideoOutput| constructor).
  // * Resizing of |ANGLESurfaceManager| & creation of newly sized Flutter
  //   textures (|flutter::GpuSurfaceTexture| & |flutter::PixelBufferTexture|)
  //   is also done through |ThreadPool|. See |VideoOutput::CheckAndResize|.
  //
  // Thus, creating a new |ThreadPool| with maximum number of worker threads as
  // 1, ensures that all the ANGLE, EGL & libmpv operations are performed on a
  // single thread orderly. This also makes usage of any |std::mutex|
  // unnecessary.
  std::unique_ptr<ThreadPool> thread_pool_ = std::make_unique<ThreadPool>(1);
  flutter::PluginRegistrarWindows* registrar_ = nullptr;
  std::unordered_map<int64_t, std::unique_ptr<VideoOutput>> video_outputs_ = {};
};

#endif  // FLUTTER_PLUGIN_MEDIA_KIT_VIDEO_VIDEO_OUTPUT_MANAGER_H_
