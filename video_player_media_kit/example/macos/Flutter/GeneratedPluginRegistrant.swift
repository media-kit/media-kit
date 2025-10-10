//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import media_kit_libs_macos_video
import media_kit_video
import package_info_plus
import path_provider_foundation
import video_player_avfoundation
import volume_controller
import wakelock_plus

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  MediaKitLibsMacosVideoPlugin.register(with: registry.registrar(forPlugin: "MediaKitLibsMacosVideoPlugin"))
  MediaKitVideoPlugin.register(with: registry.registrar(forPlugin: "MediaKitVideoPlugin"))
  FPPPackageInfoPlusPlugin.register(with: registry.registrar(forPlugin: "FPPPackageInfoPlusPlugin"))
  PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
  FVPVideoPlayerPlugin.register(with: registry.registrar(forPlugin: "FVPVideoPlayerPlugin"))
  VolumeControllerPlugin.register(with: registry.registrar(forPlugin: "VolumeControllerPlugin"))
  WakelockPlusMacosPlugin.register(with: registry.registrar(forPlugin: "WakelockPlusMacosPlugin"))
}
