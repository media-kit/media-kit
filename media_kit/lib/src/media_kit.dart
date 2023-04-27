/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:io';

import 'package:media_kit/src/libmpv/entry_point.dart' as implementation;

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
    if (Platform.isWindows) {
      implementation.ensureInitialized(libmpv: libmpv);
    }
    if (Platform.isLinux) {
      implementation.ensureInitialized(libmpv: libmpv);
    }
    if (Platform.isMacOS) {
      implementation.ensureInitialized(libmpv: libmpv);
    }
    if (Platform.isIOS) {
      implementation.ensureInitialized(libmpv: libmpv);
    }
    if (Platform.isAndroid) {
      implementation.ensureInitialized(libmpv: libmpv);
    }
  }
}
