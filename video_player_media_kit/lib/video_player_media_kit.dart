/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2023 & onwards, Abdelaziz Mahdy <abdelaziz.h.mahdy@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'package:media_kit/media_kit.dart';
import 'package:universal_platform/universal_platform.dart';

import 'package:video_player_media_kit/src/media_kit_video_player.dart';

/// {@template video_player_media_kit}
///
/// VideoPlayerMediaKit
/// -------------------
///
/// package:video_player support for all platforms. Based on package:media_kit.
///
/// ```dart
/// void main() {
///   // Make sure to add the respective packages to pubspec.yaml. e.g.
///   //
///   // dependencies:
///   //   media_kit_libs_macos_video: any
///   //   media_kit_libs_windows_video: any
///   //   media_kit_libs_linux: any
///   VideoPlayerMediaKit.ensureInitialized(
///     macOS: true,
///     windows: true,
///     linux: true,
///   );
///
///   // Use package:video_player normally!
///   runApp(MyApp());
/// }
/// ```
///
/// References:
/// * https://pub.dev/packages/video_player
/// * https://pub.dev/packages/media_kit
///
/// {@endtemplate}
class VideoPlayerMediaKit {
  /// {@macro video_player_media_kit}
  static void ensureInitialized({
    bool android = false,
    bool iOS = false,
    bool macOS = false,
    bool windows = false,
    bool linux = false,
    bool web = false,
  }) {
    if ((UniversalPlatform.isAndroid && android) ||
        (UniversalPlatform.isIOS && iOS) ||
        (UniversalPlatform.isMacOS && macOS) ||
        (UniversalPlatform.isWindows && windows) ||
        (UniversalPlatform.isLinux && linux) ||
        (UniversalPlatform.isWeb && web)) {
      MediaKit.ensureInitialized();
      MediaKitVideoPlayer.registerWith();
    }
  }
}
