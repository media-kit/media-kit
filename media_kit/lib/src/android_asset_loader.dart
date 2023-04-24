/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

/// {@template android_asset_loader}
///
/// AndroidAssetLoader
/// ------------------
///
/// This class is used to assets bundled with the application on Android.
/// The implementation depends on the mediakitandroidhelper library.
///
/// Learn more: https://github.com/media-kit/media-kit-android-helper
///
/// {@endtemplate}
class AndroidAssetLoader {
  /// {@macro android_asset_loader}
  static final instance = AndroidAssetLoader._();

  /// {@macro android_asset_loader}
  AndroidAssetLoader._() {
    try {
      if (Platform.isAndroid) {
        final library = DynamicLibrary.open('libmediakitandroidhelper.so');
        _mediaKitAndroidHelperCopyAssetToExternalFilesDir =
            library.lookupFunction<FnCXX, FnDart>(
          'MediaKitAndroidHelperCopyAssetToExternalFilesDir',
        );
      }
    } catch (exception, stacktrace) {
      print(exception);
      print(stacktrace);
    }
  }

  /// Copies an asset bundled with the application to the external files directory & returns it absolute path.
  String load(String asset) {
    final name = asset.toNativeUtf8();
    final result = List.generate(4096, (index) => ' ').join('').toNativeUtf8();
    _mediaKitAndroidHelperCopyAssetToExternalFilesDir?.call(
      name.cast(),
      result.cast(),
    );
    final path = result.cast<Utf8>().toDartString().trim();
    calloc.free(name);
    calloc.free(result);
    return path;
  }

  FnDart? _mediaKitAndroidHelperCopyAssetToExternalFilesDir;
}

// Type definitions for native functions in the shared library.

// C/C++:

typedef FnCXX = Void Function(Pointer<Utf8> asset, Pointer<Utf8> result);

// Dart:

typedef FnDart = void Function(Pointer<Utf8> asset, Pointer<Utf8> result);
