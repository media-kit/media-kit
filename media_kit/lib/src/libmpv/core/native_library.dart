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
    return (_resolved ??= await _search());
  }

  /// Searches the native shared library.
  static Future<String> _search() async {
    final scriptDir = File(Platform.script.toFilePath()).parent.path;
    final executableDir = File(Platform.resolvedExecutable).parent.path;
    if (Platform.isWindows) {
      for (final library in _kWindowsNativeLibraries) {
        if (await File(join(scriptDir, library)).exists()) {
          return join(scriptDir, library);
        }
        if (await File(join(executableDir, library)).exists()) {
          return join(executableDir, library);
        }
      }
      // Check for `MPV_PATH` environment variable & system `PATH`.
      final mpvPath = Platform.environment['MPV_PATH'];
      final envPath = Platform.environment['PATH'];
      if (mpvPath != null) {
        for (final library in _kWindowsNativeLibraries) {
          if (await File(join(mpvPath, library)).exists()) {
            return join(mpvPath, library);
          }
        }
      }
      if (envPath != null) {
        final paths = envPath.split(';');
        for (var path in paths) {
          for (final library in _kWindowsNativeLibraries) {
            if (await File(join(path, library)).exists()) {
              return join(path, library);
            }
          }
        }
      }
      throw Exception(_kWindowsNativeLibraryNotFoundMessage);
    }
    if (Platform.isLinux) {
      if (await File(join(scriptDir, _kLinuxNativeLibrary)).exists()) {
        return join(scriptDir, _kLinuxNativeLibrary);
      }
      if (await File(join(executableDir, _kLinuxNativeLibrary)).exists()) {
        return join(executableDir, _kLinuxNativeLibrary);
      }
      // Check for globally accessible shared libraries.
      final system = [
        // For Debian or Ubuntu based distributions.
        '/usr/lib/x86_64-linux-gnu',
        // For Arch Linux based distributions.
        '/usr/lib',
        // For Fedora based distributions.
        '/usr/lib64',
      ];
      for (final path in system) {
        if (await File(join(path, _kLinuxNativeLibrary)).exists()) {
          return join(path, _kLinuxNativeLibrary);
        }
      }
      throw Exception(_kLinuxNativeLibraryNotFoundMessage);
    }
    if (Platform.isMacOS) {
      final appDir = join(executableDir, "..");
      final libPath = join(
        appDir,
        "Frameworks",
        "media_kit_libs_macos.framework",
        "Resources",
        "Resources.bundle",
        "Contents",
        "Resources",
        _kMacOSNativeLibrary,
      );

      if (await File(libPath).exists()) {
        return libPath;
      }
      throw Exception(_kMacOSNativeLibraryNotFoundMessage);
    }
    throw Exception(
      'NativeLibrary.find is not supported on ${Platform.operatingSystem}.',
    );
  }

  /// Resolved path of the native shared library.
  static String? _resolved;

  /// Default libmpv shared library names on Windows.
  static const List<String> _kWindowsNativeLibraries = [
    'libmpv-2.dll',
    'mpv-2.dll',
    'mpv-1.dll',
  ];

  /// Default libmpv shared library name on Linux.
  static const String _kLinuxNativeLibrary = 'libmpv.so';

  /// Default libmpv shared library name on macOS.
  static const String _kMacOSNativeLibrary = 'libmpv.dylib';

  /// [Exception] message thrown when the native library is not found on Windows.
  static const String _kWindowsNativeLibraryNotFoundMessage =
      'Cannot find mpv-2.dll in your system %PATH%. One way to deal with this is to ship mpv-2.dll with your script or compiled executable in the same directory.';

  /// [Exception] message thrown when the native library is not found on Linux.
  static const String _kLinuxNativeLibraryNotFoundMessage =
      'Cannot find libmpv in the usual places. Depending on your distro, you may try installing mpv-devel or libmpv-dev package.';

  /// [Exception] message thrown when the native macOS is not found on macOS.
  static const String _kMacOSNativeLibraryNotFoundMessage =
      'Cannot find libmpv.dylib.';
}
