import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'media_kit_core_video_method_channel.dart';

abstract class MediaKitCoreVideoPlatform extends PlatformInterface {
  /// Constructs a MediaKitCoreVideoPlatform.
  MediaKitCoreVideoPlatform() : super(token: _token);

  static final Object _token = Object();

  static MediaKitCoreVideoPlatform _instance = MethodChannelMediaKitCoreVideo();

  /// The default instance of [MediaKitCoreVideoPlatform] to use.
  ///
  /// Defaults to [MethodChannelMediaKitCoreVideo].
  static MediaKitCoreVideoPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MediaKitCoreVideoPlatform] when
  /// they register themselves.
  static set instance(MediaKitCoreVideoPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
