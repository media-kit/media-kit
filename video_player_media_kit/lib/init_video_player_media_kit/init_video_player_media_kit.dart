import 'package:media_kit/media_kit.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:video_player_media_kit/video_player_media_kit_interface/video_player_media_kit_interface.dart';

/// Initializes the VideoPlayerMediaKit plugin if running on a supported platform.
///
/// On Windows, Linux, and macOS, this function registers the VideoPlayerMediaKit
/// plugin using the `registerWith()` method. On iOS, it also registers the plugin
/// if the `iosUseMediaKit` parameter is set to `true`. On Android, it registers
/// the plugin using the `registerWith()` method if the `androidUseMediaKit`
/// parameter is set to `true`.
///
///
/// Parameters:
/// - `iosUseMediaKit`: A boolean value indicating whether to register the plugin on iOS.
/// - `androidUseMediaKit`: A boolean value indicating whether to register the plugin on Android.
/// - `webUseMediaKit`: A boolean value indicating whether to register the plugin on the web.
/// - `logLevel`: A `LogLevel` value indicating the desired log level.
/// - `throwErrors`: when playing errors happens, throw error (can be disabled incase of false positives)
void initVideoPlayerMediaKitIfNeeded(
    {bool iosUseMediaKit = false,
    bool androidUseMediaKit = false,
    bool webUseMediaKit = false,
    MPVLogLevel logLevel = MPVLogLevel.warn,
    bool throwErrors = true}) {
  if ((UniversalPlatform.isWindows ||
      UniversalPlatform.isLinux ||
      UniversalPlatform.isMacOS)) {
    MediaKit.ensureInitialized();
    VideoPlayerMediaKit.registerWith(
        logLevel: logLevel, throwErrors: throwErrors);
  }
  if (UniversalPlatform.isIOS && iosUseMediaKit) {
    MediaKit.ensureInitialized();
    VideoPlayerMediaKit.registerWith(
        logLevel: logLevel, throwErrors: throwErrors);
  }
  if (UniversalPlatform.isAndroid && androidUseMediaKit) {
    MediaKit.ensureInitialized();
    VideoPlayerMediaKit.registerWith(
        logLevel: logLevel, throwErrors: throwErrors);
  }
  if (UniversalPlatform.isWeb && webUseMediaKit) {
    MediaKit.ensureInitialized();
    VideoPlayerMediaKit.registerWith(
        logLevel: logLevel, throwErrors: throwErrors);
  }
}
