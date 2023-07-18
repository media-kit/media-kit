#include "include/media_kit_libs_windows_audio/media_kit_libs_windows_audio_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>
#include <iostream>

void MediaKitLibsWindowsAudioPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  std::cout << "package:media_kit_libs_windows_audio registered." << std::endl;
}
