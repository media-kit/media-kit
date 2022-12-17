/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:io';
import 'package:path/path.dart';

/// NativeLibrary
/// -------------
///
/// This class is used to discover the native shared library of `libmpv`.
/// It is generally present with the name `mpv-2.dll` on Windows & `libmpv.so` on Linux.
///
/// The [find] method looks for `mpv-2.dll` or `libmpv.so` in the same
/// directory as the script or the compiled executable. If it is not found, then:
/// On Windows, `mpv-2.dll` is searched at `MPV_PATH` & `PATH`.
/// On Linux, `libmpv.so` is searched at usual places.
///
abstract class NativeLibrary {
  /// Returns the discovered path of the native shared library.
  /// Optionally, manual [path] can be provided.
  ///
  static Future<String> find({String? path}) async {
    if (path != null) {
      return path;
    }
    final scriptDir = File(Platform.script.toFilePath()).parent.path;
    final executableDir = File(Platform.resolvedExecutable).parent.path;
    if (Platform.isWindows) {
      if (await File(join(scriptDir, kWindowsNativeLibrary)).exists()) {
        return join(scriptDir, kWindowsNativeLibrary);
      }
      if (await File(join(executableDir, kWindowsNativeLibrary)).exists()) {
        return join(executableDir, kWindowsNativeLibrary);
      }
      // Check for `MPV_PATH` environment variable & system `PATH`.
      final mpvPath = Platform.environment['MPV_PATH'];
      final envPath = Platform.environment['PATH'];
      if (mpvPath != null) {
        if (await File(join(mpvPath, kWindowsNativeLibrary)).exists()) {
          return join(mpvPath, kWindowsNativeLibrary);
        }
      }
      if (envPath != null) {
        final paths = envPath.split(';');
        for (var path in paths) {
          if (await File(join(path, kWindowsNativeLibrary)).exists()) {
            return join(path, kWindowsNativeLibrary);
          }
        }
      }
      throw Exception(kWindowsNativeLibraryNotFoundMessage);
    }
    if (Platform.isLinux) {
      if (await File(join(scriptDir, kLinuxNativeLibrary)).exists()) {
        return join(scriptDir, kLinuxNativeLibrary);
      }
      if (await File(join(executableDir, kLinuxNativeLibrary)).exists()) {
        return join(executableDir, kLinuxNativeLibrary);
      }
      // Check for globally accessible shared libraries.
      final systemPaths = [
        // For Debian or Ubuntu based distributions.
        '/usr/lib/x86_64-linux-gnu',
        // For Arch Linux based distributions.
        '/usr/lib',
        // For Fedora based distributions.
        '/usr/lib64',
      ];
      for (final path in systemPaths) {
        if (await File(join(path, kLinuxNativeLibrary)).exists()) {
          return join(path, kLinuxNativeLibrary);
        }
      }
      throw Exception(kLinuxNativeLibraryNotFoundMessage);
    }
    throw Exception(
      'NativeLibrary.find is not supported on ${Platform.operatingSystem}.',
    );
  }

  /// Default `libmpv` shared library name on Windows.
  static const String kWindowsNativeLibrary = 'mpv-2.dll';

  /// Default `libmpv` shared library name on Linux.
  static const String kLinuxNativeLibrary = 'libmpv.so';

  /// [Exception] message thrown when the native library is not found on Windows.
  static const String kWindowsNativeLibraryNotFoundMessage =
      'Cannot find mpv-2.dll in your system %PATH%. One way to deal with this is to ship mpv-2.dll with your script or compiled executable in the same directory.';

  /// [Exception] message thrown when the native library is not found on Linux.
  static const String kLinuxNativeLibraryNotFoundMessage =
      'Cannot find libmpv in the usual places. Depending on your distro, you may try installing mpv-devel or libmpv-dev package.';
}
