/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
// ignore_for_file: non_constant_identifier_names, camel_case_types
import 'dart:io';
import 'dart:ffi';

import 'package:media_kit/ffi/ffi.dart';
import 'package:media_kit/generated/libmpv/bindings.dart';

/// {@template ohos_helper}
///
/// {@endtemplate}
abstract class OhosHelper {
  /// {@macro android_helper}
  static void ensureInitialized() {
    try {
      if (Platform.operatingSystem == 'ohos') {
        DynamicLibrary? libmpv, libcpp;
        try {
          libcpp = DynamicLibrary.open(
            'libc++_shared.so',
          );
        } catch (e) {
          print("load cpp failed: $e");
        }
        try {
          libmpv = DynamicLibrary.open(
            'libmpv.so.2',
          );
        } catch (e) {
          print("load libmpv failed: $e");
        }
        // Look for the required symbols.
        try {
          libcpp?.lookup('_ZNSt4__n18to_charsEPcS0_f');
        } catch (e) {
          print("symbol not found: $e");
        }
        try {
          libmpv?.lookupFunction('mpv_create');
        } catch (e) {
          print("symbol not found: $e");
        }
      }
    } catch (_) {}
  }
}