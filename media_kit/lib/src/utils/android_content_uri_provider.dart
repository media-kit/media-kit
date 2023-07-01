/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:ffi';
import 'dart:collection';
import 'package:ffi/ffi.dart';

import 'package:media_kit/src/utils/isolates.dart';

/// {@template android_content_uri_provider}
///
/// AndroidContentUriProvider
/// -------------------------
///
/// This class is used to access content:// URIs on Android.
/// The implementation depends on the mediakitandroidhelper library.
///
/// Learn more: https://github.com/media-kit/media-kit-android-helper
///
/// {@endtemplate}
abstract class AndroidContentUriProvider {
  /// Returns the file descriptor of the content:// URI.
  static Future<int> openFileDescriptor(String uri) async {
    if (_loaded.containsKey(uri)) {
      return _loaded[uri]!;
    }

    // Run on another [Isolate] to avoid blocking the UI.
    final path = await compute(openFileDescriptorSync, uri);

    _loaded[uri] = path;

    return path;
  }

  /// Returns the file descriptor of the content:// URI.
  static int openFileDescriptorSync(String uri) {
    if (_loaded.containsKey(uri)) {
      return _loaded[uri]!;
    }

    final lib = DynamicLibrary.open('libmediakitandroidhelper.so');
    final openFileDescriptor =
        lib.lookupFunction<OpenFileDescriptorCXX, OpenFileDescriptorDart>(
      'MediaKitAndroidHelperOpenFileDescriptor',
    );

    final name = uri.toNativeUtf8();

    final fileDescriptor = openFileDescriptor.call(name.cast());

    calloc.free(name);

    _loaded[uri] = fileDescriptor;

    return fileDescriptor;
  }

  /// Closes the file descriptor of the content:// URI.
  static Future<void> closeFileDescriptor(int fileDescriptor) async {
    _loaded.removeWhere((key, value) => value == fileDescriptor);
    // Run on another [Isolate] to avoid blocking the UI.
    await compute(closeFileDescriptorSync, fileDescriptor);
  }

  /// Closes the file descriptor of the content:// URI.
  static void closeFileDescriptorSync(int fileDescriptor) {
    _loaded.removeWhere((key, value) => value == fileDescriptor);
    final lib = DynamicLibrary.open('libmediakitandroidhelper.so');
    final closeFileDescriptor =
        lib.lookupFunction<CloseFileDescriptorCXX, CloseFileDescriptorDart>(
      'MediaKitAndroidHelperCloseFileDescriptor',
    );

    closeFileDescriptor.call(fileDescriptor);
  }

  /// Stores the file descriptors of previously loaded content:// URIs. This avoids redundant FFI calls.
  static final HashMap<String, int> _loaded = HashMap<String, int>();
}

// Type definitions for native functions in the shared library.

// C/C++:

typedef OpenFileDescriptorCXX = Int32 Function(Pointer<Utf8> uri);
typedef CloseFileDescriptorCXX = Void Function(Int32 fileDescriptor);

// Dart:

typedef OpenFileDescriptorDart = int Function(Pointer<Utf8> uri);
typedef CloseFileDescriptorDart = void Function(int fileDescriptor);
