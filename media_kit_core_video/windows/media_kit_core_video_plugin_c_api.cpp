#include "include/media_kit_core_video/media_kit_core_video_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "media_kit_core_video_plugin.h"

void MediaKitCoreVideoPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  media_kit_core_video::MediaKitCoreVideoPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
