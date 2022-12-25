// This file is a part of media_kit
// (https://github.com/alexmercerind/media_kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.
#ifndef FLUTTER_PLUGIN_MEDIA_KIT_CORE_VIDEO_PLUGIN_H_
#define FLUTTER_PLUGIN_MEDIA_KIT_CORE_VIDEO_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include "video_output_manager.h"

namespace media_kit_core_video {

class MediaKitCoreVideoPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  MediaKitCoreVideoPlugin(flutter::PluginRegistrarWindows* registrar);

  virtual ~MediaKitCoreVideoPlugin();

  MediaKitCoreVideoPlugin(const MediaKitCoreVideoPlugin&) = delete;
  MediaKitCoreVideoPlugin& operator=(const MediaKitCoreVideoPlugin&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  flutter::PluginRegistrarWindows* registrar_ = nullptr;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_ =
      nullptr;
  std::unique_ptr<VideoOutputManager> video_output_manager_ = nullptr;
};

}  // namespace media_kit_core_video

#endif  // FLUTTER_PLUGIN_MEDIA_KIT_CORE_VIDEO_PLUGIN_H_
