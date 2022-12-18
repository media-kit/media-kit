#ifndef FLUTTER_PLUGIN_MEDIA_KIT_CORE_VIDEO_PLUGIN_H_
#define FLUTTER_PLUGIN_MEDIA_KIT_CORE_VIDEO_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace media_kit_core_video {

class MediaKitCoreVideoPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  MediaKitCoreVideoPlugin();

  virtual ~MediaKitCoreVideoPlugin();

  // Disallow copy and assign.
  MediaKitCoreVideoPlugin(const MediaKitCoreVideoPlugin&) = delete;
  MediaKitCoreVideoPlugin& operator=(const MediaKitCoreVideoPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace media_kit_core_video

#endif  // FLUTTER_PLUGIN_MEDIA_KIT_CORE_VIDEO_PLUGIN_H_
