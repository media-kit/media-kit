// This file is a part of media_kit
// (https://github.com/alexmercerind/media_kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.
#include "media_kit_core_video_plugin.h"

#include <Windows.h>

namespace media_kit_core_video {

void MediaKitCoreVideoPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto plugin = std::make_unique<MediaKitCoreVideoPlugin>(registrar);
  registrar->AddPlugin(std::move(plugin));
}

MediaKitCoreVideoPlugin::MediaKitCoreVideoPlugin(
    flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "com.alexmercerind/media_kit_core_video",
      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([&](const auto& call, auto result) {
    HandleMethodCall(call, std::move(result));
  });
  video_output_manager_ =
      std::make_unique<VideoOutputManager>(registrar, channel_.get());
}

MediaKitCoreVideoPlugin::~MediaKitCoreVideoPlugin() {}

void MediaKitCoreVideoPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (IS_METHOD("VideoOutputManager.Create")) {
    auto arguments = std::get<flutter::EncodableMap>(*method_call.arguments());
    auto handle = std::get<int64_t>(arguments[VALUE("handle")]);
    std::optional<int64_t> width = std::nullopt, height = std::nullopt;
    if (auto w = std::get_if<int64_t>(&arguments[VALUE("width")])) {
      width = *w;
    }
    if (auto h = std::get_if<int64_t>(&arguments[VALUE("height")])) {
      height = *h;
    }
    video_output_manager_->Create(handle, width, height);
    result->Success(VALUE(std::monostate{}));
  } else if (IS_METHOD("VideoOutputManager.Dispose")) {
    auto arguments = std::get<flutter::EncodableMap>(*method_call.arguments());
    auto handle = std::get<int64_t>(arguments[VALUE("handle")]);
    video_output_manager_->Dispose(handle);
    result->Success(VALUE(std::monostate{}));
  } else {
    result->NotImplemented();
  }
}

}  // namespace media_kit_core_video
