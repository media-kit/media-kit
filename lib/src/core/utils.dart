/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:ffi';
import 'package:ffi/ffi.dart';

extension NativeTypes on List<String> {
  /// Utility method to convert a [List<String>] to [Pointer<Pointer<Utf8>>] (char**) equivalent in dart.
  Pointer<Pointer<Utf8>> toNativeUtf8Array() {
    final ptr = map((String string) => string.toNativeUtf8())
        .toList()
        .cast<Pointer<Utf8>>();
    final Pointer<Pointer<Utf8>> ptrPtr = calloc.allocate(join('').length);
    for (int index = 0; index < length; index++) {
      ptrPtr[index] = ptr[index];
    }
    return ptrPtr;
  }
}
