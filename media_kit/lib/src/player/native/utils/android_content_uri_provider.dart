/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:ffi';
import 'dart:collection';

import 'package:media_kit/ffi/ffi.dart';

import 'package:media_kit/src/player/native/utils/isolates.dart';

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
  static Future<int> openFileDescriptor(String contentUri) async {
    final cachedFileDescriptor = _fileDescriptorsByContentUri[contentUri];
    if (cachedFileDescriptor != null) {
      return cachedFileDescriptor;
    }
    final fileDescriptor = await compute(_openFileDescriptor, contentUri);
    _fileDescriptorsByContentUri[contentUri] = fileDescriptor;
    if (fileDescriptor > 0) {
      _contentUrisByFileDescriptorUri['fd://$fileDescriptor'] = contentUri;
    }
    return fileDescriptor;
  }

  /// Returns the file descriptor of the content:// URI.
  static int openFileDescriptorSync(String contentUri) {
    final cachedFileDescriptor = _fileDescriptorsByContentUri[contentUri];
    if (cachedFileDescriptor != null) {
      return cachedFileDescriptor;
    }
    final fileDescriptor = _openFileDescriptor(contentUri);
    _fileDescriptorsByContentUri[contentUri] = fileDescriptor;
    if (fileDescriptor > 0) {
      _contentUrisByFileDescriptorUri['fd://$fileDescriptor'] = contentUri;
    }
    return fileDescriptor;
  }

  /// Closes the file descriptor of the content:// URI.
  static Future<void> closeFileDescriptor(
      String contentUriOrFileDescriptorUri) async {
    final contentUri = _contentUrisByFileDescriptorUri[
            contentUriOrFileDescriptorUri] ??
        contentUriOrFileDescriptorUri;
    final fileDescriptor = _fileDescriptorsByContentUri[contentUri];
    if (fileDescriptor != null) {
      _fileDescriptorsByContentUri.remove(contentUri);
      _contentUrisByFileDescriptorUri.remove('fd://$fileDescriptor');
      await compute(_closeFileDescriptor, fileDescriptor);
    }
  }

  /// Closes the file descriptor of the content:// URI.
  static void closeFileDescriptorSync(String contentUriOrFileDescriptorUri) {
    final contentUri = _contentUrisByFileDescriptorUri[
            contentUriOrFileDescriptorUri] ??
        contentUriOrFileDescriptorUri;
    final fileDescriptor = _fileDescriptorsByContentUri[contentUri];
    if (fileDescriptor != null) {
      _fileDescriptorsByContentUri.remove(contentUri);
      _contentUrisByFileDescriptorUri.remove('fd://$fileDescriptor');
      _closeFileDescriptor(fileDescriptor);
    }
  }

  /// The native implementation for [openFileDescriptor] & [openFileDescriptorSync].
  static int _openFileDescriptor(String contentUri) {
    final lib = DynamicLibrary.open('libmediakitandroidhelper.so');
    final fn =
        lib.lookupFunction<OpenFileDescriptorCXX, OpenFileDescriptorDart>(
      'MediaKitAndroidHelperOpenFileDescriptor',
    );
    final name = contentUri.toNativeUtf8();
    try {
      return fn.call(name.cast());
    } finally {
      calloc.free(name);
    }
  }

  /// The native implementation for [closeFileDescriptor] & [closeFileDescriptorSync].
  static void _closeFileDescriptor(int fileDescriptor) {
    final lib = DynamicLibrary.open('libmediakitandroidhelper.so');
    final fn =
        lib.lookupFunction<CloseFileDescriptorCXX, CloseFileDescriptorDart>(
      'MediaKitAndroidHelperCloseFileDescriptor',
    );
    fn.call(fileDescriptor);
  }

  /// Maps content:// URIs to their open file descriptors.
  static final HashMap<String, int> _fileDescriptorsByContentUri =
      HashMap<String, int>();

  /// Maps normalized fd:// URIs back to content:// URIs.
  static final HashMap<String, String> _contentUrisByFileDescriptorUri =
      HashMap<String, String>();
}

// Type definitions for native functions in the shared library.

// C/C++:

typedef OpenFileDescriptorCXX = Int32 Function(Pointer<Utf8> contentUri);
typedef CloseFileDescriptorCXX = Void Function(Int32 fileDescriptor);

// Dart:

typedef OpenFileDescriptorDart = int Function(Pointer<Utf8> contentUri);
typedef CloseFileDescriptorDart = void Function(int fileDescriptor);
