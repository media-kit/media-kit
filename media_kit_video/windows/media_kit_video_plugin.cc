// This file is a part of media_kit
// (https://github.com/alexmercerind/media_kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.
#include "media_kit_video_plugin.h"

#include <Windows.h>

namespace media_kit_video {

void MediaKitVideoPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto plugin = std::make_unique<MediaKitVideoPlugin>(registrar);
  registrar->AddPlugin(std::move(plugin));
}

MediaKitVideoPlugin::MediaKitVideoPlugin(
    flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "com.alexmercerind/media_kit_video",
      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([&](const auto& call, auto result) {
    HandleMethodCall(call, std::move(result));
  });
  video_output_manager_ =
      std::make_unique<VideoOutputManager>(registrar, channel_.get());
}

MediaKitVideoPlugin::~MediaKitVideoPlugin() {}

void MediaKitVideoPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (IS_METHOD("VideoOutputManager.Create")) {
    auto arguments = std::get<flutter::EncodableMap>(*method_call.arguments());
    auto handle = std::get<std::string>(arguments[VALUE("handle")]);
    auto width = std::get<std::string>(arguments[VALUE("width")]);
    auto height = std::get<std::string>(arguments[VALUE("height")]);
    auto handle_value =
        static_cast<int64_t>(strtoll(handle.c_str(), nullptr, 10));
    auto width_value = std::optional<int64_t>{};
    auto height_value = std::optional<int64_t>{};
    if (height.compare("null") != 0 && width.compare("null") != 0) {
      width_value = static_cast<int64_t>(strtoll(width.c_str(), nullptr, 10));
      height_value = static_cast<int64_t>(strtoll(height.c_str(), nullptr, 10));
    }
    auto video_output =
        video_output_manager_->Create(handle_value, width_value, height_value);
    result->Success(VALUE(flutter::EncodableMap({
        {
            VALUE("id"),
            VALUE(video_output->texture_id()),
        },
        {
            VALUE("rect"),
            VALUE(flutter::EncodableMap({
                {
                    VALUE("left"),
                    VALUE(0),
                },
                {
                    VALUE("top"),
                    VALUE(0),
                },
                {
                    VALUE("right"),
                    VALUE(video_output->width()),
                },
                {
                    VALUE("bottom"),
                    VALUE(video_output->height()),
                },
            })),
        },

    })));
  } else if (IS_METHOD("VideoOutputManager.Dispose")) {
    auto arguments = std::get<flutter::EncodableMap>(*method_call.arguments());
    auto handle = std::get<std::string>(arguments[VALUE("handle")]);
    auto handle_value =
        static_cast<int64_t>(strtoll(handle.c_str(), nullptr, 10));
    video_output_manager_->Dispose(handle_value);
    result->Success(VALUE(std::monostate{}));
  } else {
    result->NotImplemented();
  }
}

}  // namespace media_kit_video
