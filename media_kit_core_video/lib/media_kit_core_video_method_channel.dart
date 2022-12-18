import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'media_kit_core_video_platform_interface.dart';

/// An implementation of [MediaKitCoreVideoPlatform] that uses method channels.
class MethodChannelMediaKitCoreVideo extends MediaKitCoreVideoPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('media_kit_core_video');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
