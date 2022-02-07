/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:io';
import 'package:path/path.dart';

/// Path to DLL or shared object of libmpv.
late String mpvDynamicLibraryPath;

const String kWindowsDynamicLibrary = 'mpv-1.dll';
const String kLinuxDynamicLibrary = 'libmpv.so';

/// ## MPV
///
/// A complete video & audio library for Flutter.
/// [MPV.initialize] initializes the library.
///
/// ```dart
/// void main() {
///   await MPV.initialize();
///   final player = Player();
///   player.open(
///     [
///       Media('https://alexmercerind.github.io/music.mp3'),
///       Media('file://C:/documents/video.mp4'),
///     ],
///   );
///   player.play();
/// }
/// ```
///
abstract class MPV {
  /// Loads the shared library & initializes the library.
  ///
  /// Checks for `mpv-1.dll` or `libmpv.so` in the same directory as the script or the compiled executable.
  /// If not found, then:
  /// On Windows, checks for `mpv-1.dll` at `MPV_PATH` & `PATH`.
  /// On Linux, checks for `libmpv.so` at usual places.
  static Future<void> initialize({String? dynamicLibrary}) async {
    if (dynamicLibrary != null) {
      mpvDynamicLibraryPath = dynamicLibrary;
      return;
    }
    if (Platform.isWindows) {
      if (await File(join(Platform.script.path, kWindowsDynamicLibrary))
          .exists()) {
        mpvDynamicLibraryPath =
            join(Platform.script.path, kWindowsDynamicLibrary);
        return;
      }
      if (await File(join(
              (Platform.resolvedExecutable.split('\\')..removeLast())
                  .join('\\'),
              kWindowsDynamicLibrary))
          .exists()) {
        mpvDynamicLibraryPath = join(
            (Platform.resolvedExecutable.split('\\')..removeLast()).join('\\'),
            kWindowsDynamicLibrary);
        return;
      }
      final mpvPath = Platform.environment['MPV_PATH'];
      final envPath = Platform.environment['PATH'];
      if (mpvPath != null) {
        if (await File(join(mpvPath, kWindowsDynamicLibrary)).exists()) {
          mpvDynamicLibraryPath = join(mpvPath, kWindowsDynamicLibrary);
          return;
        }
      }
      if (envPath != null) {
        final paths = envPath.split(';');
        for (var path in paths) {
          if (await File(join(path, kWindowsDynamicLibrary)).exists()) {
            mpvDynamicLibraryPath = join(path, kWindowsDynamicLibrary);
            return;
          }
        }
      }
      throw Exception(
          'Cannot find mpv-1.dll in your system %PATH%. One way to deal with this is to ship mpv-1.dll with your script or compiled executable in the same directory.');
    }
    if (Platform.isLinux) {
      if (await File(join(Platform.script.path, kWindowsDynamicLibrary))
          .exists()) {
        mpvDynamicLibraryPath =
            join(Platform.script.path, kWindowsDynamicLibrary);
        return;
      }
      if (await File(join(
              (Platform.resolvedExecutable.split('/')..removeLast()).join('/'),
              kWindowsDynamicLibrary))
          .exists()) {
        mpvDynamicLibraryPath = join(
            (Platform.resolvedExecutable.split('/')..removeLast()).join('/'),
            kWindowsDynamicLibrary);
        return;
      }

      // For Debian based distros
      if (await File('/usr/lib/x86_64-linux-gnu/$kLinuxDynamicLibrary')
          .exists()) {
        mpvDynamicLibraryPath =
            '/usr/lib/x86_64-linux-gnu/$kLinuxDynamicLibrary';
        return;
      }
      // For Other Distros
      else if (await File('/usr/lib/$kLinuxDynamicLibrary').exists()) {
        mpvDynamicLibraryPath = '/usr/lib/$kLinuxDynamicLibrary';
        return;
      }
      throw Exception(
          'Cannot find libmpv in the usual places. Depending on your distro, you may try installing mpv-devel or libmpv-dev package.');
    }
  }
}
