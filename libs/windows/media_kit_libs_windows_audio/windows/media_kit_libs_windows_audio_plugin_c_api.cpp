#include "include/media_kit_libs_windows_audio/media_kit_libs_windows_audio_plugin_c_api.h"

#include <iostream>

#include <media_kit.h>

#include <flutter/plugin_registrar_windows.h>

void MediaKitLibsWindowsAudioPluginCApiRegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar) {
  MediaKit::GetInstance().FindPackages();
  std::cout << "package:media_kit_libs_windows_audio registered." << std::endl;
}
