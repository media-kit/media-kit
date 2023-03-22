/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:ffi';

/// NativeLibrary
/// -------------
///
/// This class is used to discover & load the libmpv shared library.
/// It is generally present with the name `libmpv-2.dll` on Windows & `libmpv.so` on Linux.
///
abstract class NativeLibrary {
  /// Returns the resolved libmpv [DynamicLibrary].
  static DynamicLibrary find({String? path}) {
    if (path != null) {
      return DynamicLibrary.open(path);
    }

    final names = {
      'windows': [
        'libmpv-2.dll',
        'mpv-2.dll',
        'mpv-1.dll',
      ],
      'linux': [
        'libmpv.so',
      ],
      'macos': [
        'libmpv.dylib',
      ],
      'ios': [
        'libmpv.dylib',
      ],
    }[Platform.operatingSystem];
    if (names != null) {
      for (final name in names) {
        try {
          return DynamicLibrary.open(name);
        } catch (_) {}
      }
      throw Exception(
        {
          'windows':
              'Cannot find libmpv-2.dll in your system %PATH%. One way to deal with this is to ship libmpv-2.dll with your compiled executable or script in the same directory.',
          'linux':
              'Cannot find libmpv at the usual places. Depending upon your distribution, you can install the libmpv package to make shared library available globally. On Debian or Ubuntu based systems, you can install it with: apt install libmpv-dev.',
          'macos':
              'Cannot find libmpv.dylib. Check that it is present in the Frameworks folder of your application.',
          'ios':
              'Cannot find libmpv.dylib. Check that it is present in the Frameworks folder of your application.',
        }[Platform.operatingSystem]!,
      );
    }
    throw Exception(
      'Unsupported operating system: ${Platform.operatingSystem}.',
    );
  }
}
