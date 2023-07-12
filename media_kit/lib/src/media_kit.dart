/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'package:universal_platform/universal_platform.dart';

import 'package:media_kit/src/player/native/player/player.dart';
import 'package:media_kit/src/player/web/player/player.dart';

/// {@template media_kit}
///
/// package:media_kit
/// -----------------
/// A complete video & audio library for Flutter & Dart.
///
/// {@endtemplate}
abstract class MediaKit {
  /// {@macro media_kit}
  static void ensureInitialized({String? libmpv}) {
    if (UniversalPlatform.isWindows) {
      nativeEnsureInitialized(libmpv: libmpv);
    } else if (UniversalPlatform.isLinux) {
      nativeEnsureInitialized(libmpv: libmpv);
    } else if (UniversalPlatform.isMacOS) {
      nativeEnsureInitialized(libmpv: libmpv);
    } else if (UniversalPlatform.isIOS) {
      nativeEnsureInitialized(libmpv: libmpv);
    } else if (UniversalPlatform.isAndroid) {
      nativeEnsureInitialized(libmpv: libmpv);
    } else if (UniversalPlatform.isWeb) {
      webEnsureInitialized(libmpv: libmpv);
    }
  }
}
