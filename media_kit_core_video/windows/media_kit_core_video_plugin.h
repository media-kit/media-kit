#ifndef FLUTTER_PLUGIN_MEDIA_KIT_CORE_VIDEO_PLUGIN_H_
#define FLUTTER_PLUGIN_MEDIA_KIT_CORE_VIDEO_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

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
};

}  // namespace media_kit_core_video

#endif  // FLUTTER_PLUGIN_MEDIA_KIT_CORE_VIDEO_PLUGIN_H_
