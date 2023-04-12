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
    : registrar_(registrar),
      video_output_manager_(std::make_unique<VideoOutputManager>(registrar)) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "com.alexmercerind/media_kit_video",
      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([&](const auto& call, auto result) {
    HandleMethodCall(call, std::move(result));
  });
}

MediaKitVideoPlugin::~MediaKitVideoPlugin() {}

void MediaKitVideoPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("VideoOutputManager.Create") == 0) {
    auto arguments = std::get<flutter::EncodableMap>(*method_call.arguments());
    auto handle =
        std::get<std::string>(arguments[flutter::EncodableValue("handle")]);
    auto width =
        std::get<std::string>(arguments[flutter::EncodableValue("width")]);
    auto height =
        std::get<std::string>(arguments[flutter::EncodableValue("height")]);
    auto handle_value =
        static_cast<int64_t>(strtoll(handle.c_str(), nullptr, 10));
    auto width_value = std::optional<int64_t>{};
    auto height_value = std::optional<int64_t>{};
    if (height.compare("null") != 0 && width.compare("null") != 0) {
      width_value = static_cast<int64_t>(strtoll(width.c_str(), nullptr, 10));
      height_value = static_cast<int64_t>(strtoll(height.c_str(), nullptr, 10));
    }
    video_output_manager_->Create(
        handle_value, width_value, height_value,
        [channel_ptr = channel_.get(), handle = handle_value](
            auto id, auto width, auto height) {
          channel_ptr->InvokeMethod(
              "VideoOutput.Resize",
              std::make_unique<flutter::EncodableValue>(flutter::EncodableMap{
                  {
                      flutter::EncodableValue("handle"),
                      flutter::EncodableValue(handle),
                  },
                  {
                      flutter::EncodableValue("id"),
                      flutter::EncodableValue(id),
                  },
                  {
                      flutter::EncodableValue("rect"),
                      flutter::EncodableValue(flutter::EncodableMap{
                          {
                              flutter::EncodableValue("left"),
                              flutter::EncodableValue(0),
                          },
                          {
                              flutter::EncodableValue("top"),
                              flutter::EncodableValue(0),
                          },
                          {
                              flutter::EncodableValue("width"),
                              flutter::EncodableValue(width),
                          },
                          {
                              flutter::EncodableValue("height"),
                              flutter::EncodableValue(height),
                          },
                      }),
                  },
              }),
              nullptr);
        });
    result->Success(flutter::EncodableValue(std::monostate{}));
  } else if (method_call.method_name().compare("VideoOutputManager.Dispose") ==
             0) {
    auto arguments = std::get<flutter::EncodableMap>(*method_call.arguments());
    auto handle =
        std::get<std::string>(arguments[flutter::EncodableValue("handle")]);
    auto handle_value =
        static_cast<int64_t>(strtoll(handle.c_str(), nullptr, 10));
    video_output_manager_->Dispose(handle_value);
    result->Success(flutter::EncodableValue(std::monostate{}));
  } else if (method_call.method_name().compare("VideoOutputManager.SetSize") ==
             0) {
    auto arguments = std::get<flutter::EncodableMap>(*method_call.arguments());
    auto handle =
        std::get<std::string>(arguments[flutter::EncodableValue("handle")]);
    auto width =
        std::get<std::string>(arguments[flutter::EncodableValue("width")]);
    auto height =
        std::get<std::string>(arguments[flutter::EncodableValue("height")]);
    auto handle_value =
        static_cast<int64_t>(strtoll(handle.c_str(), nullptr, 10));
    auto width_value = std::optional<int64_t>{};
    auto height_value = std::optional<int64_t>{};
    if (height.compare("null") != 0 && width.compare("null") != 0) {
      width_value = static_cast<int64_t>(strtoll(width.c_str(), nullptr, 10));
      height_value = static_cast<int64_t>(strtoll(height.c_str(), nullptr, 10));
    }
    video_output_manager_->SetSize(handle_value, width_value, height_value);
    result->Success(flutter::EncodableValue(std::monostate{}));
  } else {
    result->NotImplemented();
  }
}

}  // namespace media_kit_video
