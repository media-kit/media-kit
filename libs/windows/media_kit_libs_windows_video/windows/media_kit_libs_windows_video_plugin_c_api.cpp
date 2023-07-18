#include "include/media_kit_libs_windows_video/media_kit_libs_windows_video_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>
#include <iostream>

void MediaKitLibsWindowsVideoPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  std::cout << "package:media_kit_libs_windows_video registered." << std::endl;
}
