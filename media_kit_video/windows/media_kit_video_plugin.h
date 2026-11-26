// This file is a part of media_kit
// (https://github.com/media-kit/media-kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.
#ifndef MEDIA_KIT_VIDEO_PLUGIN_H_
#define MEDIA_KIT_VIDEO_PLUGIN_H_

#include <Windows.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <atomic>
#include <functional>
#include <memory>

#include "platform_task_runner.h"
#include "video_output_manager.h"

namespace media_kit_video {

class MediaKitVideoPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  MediaKitVideoPlugin(flutter::PluginRegistrarWindows* registrar);

  virtual ~MediaKitVideoPlugin();

  // Disallow copy and assign.
  MediaKitVideoPlugin(const MediaKitVideoPlugin&) = delete;
  MediaKitVideoPlugin& operator=(const MediaKitVideoPlugin&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Posts callbacks to the platform thread independently of any Flutter view.
  void RunOnMainThread(std::function<void()> task);

  flutter::PluginRegistrarWindows* registrar_ = nullptr;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_ =
      nullptr;
  PlatformTaskRunner platform_tasks_;
  std::unique_ptr<VideoOutputManager> video_output_manager_ = nullptr;
  std::atomic<bool> shutting_down_{false};
};

}  // namespace media_kit_video

#endif  // MEDIA_KIT_VIDEO_PLUGIN_H_
