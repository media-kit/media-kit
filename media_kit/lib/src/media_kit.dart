/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'package:universal_platform/universal_platform.dart';

import 'package:media_kit/src/player/web/player/player.dart';
import 'package:media_kit/src/player/libmpv/player/player.dart';

/// {@template media_kit}
///
/// package:media_kit
/// -----------------
/// A complete video & audio library for Flutter & Dart.
///
/// * GitHub  : https://github.com/alexmercerind/media_kit
/// * pub.dev : https://pub.dev/packages/media_kit
///
/// [MediaKit.ensureInitialized] must be called for using the package.
///
/// Following optional parameters are available:
/// * `libmpv`: Manually specified the path to the libmpv shared library.
///
/// {@endtemplate}
abstract class MediaKit {
  /// {@macro media_kit}
  static void ensureInitialized({String? libmpv}) {
    if (UniversalPlatform.isWindows) {
      libmpvEnsureInitialized(libmpv: libmpv);
    } else if (UniversalPlatform.isLinux) {
      libmpvEnsureInitialized(libmpv: libmpv);
    } else if (UniversalPlatform.isMacOS) {
      libmpvEnsureInitialized(libmpv: libmpv);
    } else if (UniversalPlatform.isIOS) {
      libmpvEnsureInitialized(libmpv: libmpv);
    } else if (UniversalPlatform.isAndroid) {
      libmpvEnsureInitialized(libmpv: libmpv);
    } else if (UniversalPlatform.isWeb) {
      webEnsureInitialized(libmpv: libmpv);
    }
  }
}
