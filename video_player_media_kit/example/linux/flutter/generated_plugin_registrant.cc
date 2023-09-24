//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <media_kit_video/media_kit_video_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) media_kit_video_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "MediaKitVideoPlugin");
  media_kit_video_plugin_register_with_registrar(media_kit_video_registrar);
}
