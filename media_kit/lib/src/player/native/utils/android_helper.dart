/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
// ignore_for_file: non_constant_identifier_names, camel_case_types
import 'dart:io';
import 'dart:ffi';

/// {@template android_helper}
///
/// AndroidHelper
/// -------------
///
/// Learn more: https://github.com/media-kit/media-kit-android-helper
///
/// {@endtemplate}
abstract class AndroidHelper {
  /// {@macro android_helper}
  static void ensureInitialized() {
    try {
      if (Platform.isAndroid) {
        final libavcodec = DynamicLibrary.open(
          'libavcodec.so',
        );
        final libmediakitandroidhelper = DynamicLibrary.open(
          'libmediakitandroidhelper.so',
        );
        _av_jni_set_java_vm = libavcodec
            .lookupFunction<av_jni_set_java_vmCXX, av_jni_set_java_vmDart>(
          'av_jni_set_java_vm',
        );
        _MediaKitAndroidHelperGetJavaVM =
            libmediakitandroidhelper.lookupFunction<
                MediaKitAndroidHelperGetJavaVMCXX,
                MediaKitAndroidHelperGetJavaVMDart>(
          'MediaKitAndroidHelperGetJavaVM',
        );
        _MediaKitAndroidHelperGetAPILevel =
            libmediakitandroidhelper.lookupFunction<
                MediaKitAndroidHelperGetAPILevelCXX,
                MediaKitAndroidHelperGetAPILevelDart>(
          'MediaKitAndroidHelperGetAPILevel',
        );
        _MediaKitAndroidHelperIsEmulator =
            libmediakitandroidhelper.lookupFunction<
                MediaKitAndroidHelperIsEmulatorCXX,
                MediaKitAndroidHelperIsEmulatorDart>(
          'MediaKitAndroidHelperIsEmulator',
        );

        Pointer<Void>? vm;
        while (true) {
          // Invoke av_jni_set_java_vm to set reference to JavaVM*.
          // This is internally consumed by libmpv & FFmpeg.
          vm = _MediaKitAndroidHelperGetJavaVM?.call();
          if (vm != null) {
            if (vm != nullptr) {
              _av_jni_set_java_vm?.call(vm);
              break;
            }
          }
          sleep(const Duration(milliseconds: 20));
        }
      }
    } catch (exception, stacktrace) {
      print(exception);
      print(stacktrace);
    }
  }

  static int get APILevel {
    if (Platform.isAndroid) {
      return _MediaKitAndroidHelperGetAPILevel?.call() ?? -1;
    }
    return -1;
  }

  static bool get isEmulator {
    if (Platform.isAndroid) {
      return _MediaKitAndroidHelperIsEmulator?.call() == 1;
    }
    return false;
  }

  static bool get isPhysicalDevice {
    if (Platform.isAndroid) {
      return !isEmulator;
    }
    return false;
  }

  static av_jni_set_java_vmDart? _av_jni_set_java_vm;
  static MediaKitAndroidHelperGetJavaVMDart? _MediaKitAndroidHelperGetJavaVM;
  static MediaKitAndroidHelperGetAPILevelDart?
      _MediaKitAndroidHelperGetAPILevel;
  static MediaKitAndroidHelperIsEmulatorDart? _MediaKitAndroidHelperIsEmulator;
}

typedef av_jni_set_java_vmCXX = Void Function(Pointer<Void> jvm);
typedef av_jni_set_java_vmDart = void Function(Pointer<Void> jvm);

typedef MediaKitAndroidHelperGetJavaVMCXX = Pointer<Void> Function();
typedef MediaKitAndroidHelperGetJavaVMDart = Pointer<Void> Function();

typedef MediaKitAndroidHelperGetAPILevelCXX = Int32 Function();
typedef MediaKitAndroidHelperGetAPILevelDart = int Function();

typedef MediaKitAndroidHelperIsEmulatorCXX = Int8 Function();
typedef MediaKitAndroidHelperIsEmulatorDart = int Function();
