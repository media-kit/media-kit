/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:ffi';
import 'dart:async';
import 'dart:collection';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

// ignore_for_file: unused_import, implementation_imports
// It's absolutely crazy that C/C++ interop in Dart is so much easier & less tedious (possibly more performant as well) than in Java/Kotlin.
// I don't want to add some additional code to make it accessible through JNI & additionally bundle it with the app. We can directly use the native library & it's bindings instead to make our life easier & bundle size smaller.
//
// Only downside I can see is that we are now depending package:media_kit_video on package:ffi & package:media_kit. However, it's absolutely fine because package:media_kit_video is crafted for package:media_kit.
// Also... now the API is also improved, now [VideoController.create] consumes [Player] directly instead of [Player.handle] which as an [int].
import 'package:media_kit/generated/libmpv/bindings.dart';
import 'package:media_kit/src/libmpv/core/native_library.dart';

import 'package:media_kit_video/src/video_controller/video_controller.dart';

/// {@template video_controller_android}
///
/// VideoControllerAndroid
/// ----------------------
///
/// The [VideoController] implementation based on native JNI & C/C++ used on Android.
///
/// {@endtemplate}
class VideoControllerAndroid extends VideoController {
  /// Whether [VideoControllerAndroid] is supported on the current platform or not.
  static bool get supported => Platform.isAndroid;

  /// {@macro video_controller_android}
  VideoControllerAndroid(
    super.player,
    super.width,
    super.height, {
    super.enableHardwareAcceleration = true,
  }) {
    _widthStreamSubscription = player.streams.width.listen((width) {
      rect.value = Rect.fromLTWH(
        0,
        0,
        width.toDouble(),
        rect.value?.height ?? 0,
      );
    });
    _heightStreamSubscription = player.streams.height.listen((height) {
      rect.value = Rect.fromLTWH(
        0,
        0,
        rect.value?.width ?? 0,
        height.toDouble(),
      );
    });
  }

  /// {@macro video_controller_android}
  static Future<VideoController> create(
    Player player, {
    int? width,
    int? height,
    bool enableHardwareAcceleration = true,
  }) async {
    // Retrieve the native handle of the [Player].
    final handle = await player.handle;
    // Return the existing [VideoController] if it's already created.
    if (_controllers.containsKey(handle)) {
      return _controllers[handle]!;
    }

    // Creation:

    final controller = VideoControllerAndroid(
      player,
      width,
      height,
      enableHardwareAcceleration: enableHardwareAcceleration,
    );
    // Store the [VideoController] in the [_controllers].
    _controllers[handle] = controller;

    final data = await _channel.invokeMethod(
      'VideoOutputManager.Create',
      {
        'handle': handle.toString(),
      },
    );
    final int id = data['id'];
    final int wid = data['wid'];
    debugPrint(data.toString());

    // ----------------------------------------------
    // https://mpv.io/manual/stable/#video-output-drivers-mediacodec-embed
    NativeLibrary.ensureInitialized();
    final mpv = MPV(DynamicLibrary.open(NativeLibrary.path));
    final values = {
      'opengl-es': 'yes',
      'force-window': 'yes',
      'gpu-context': 'android',
      'vo': 'mediacodec_embed',
      'wid': wid.toString(),
      if (enableHardwareAcceleration) 'hwdec': 'mediacodec' else 'hwdec': 'no',
      if (width != null && height != null)
        'android-surface-size': '${width}x$height',
    };
    for (final entry in values.entries) {
      final name = entry.key.toNativeUtf8();
      final value = entry.value.toNativeUtf8();
      mpv.mpv_set_option_string(
        Pointer.fromAddress(handle),
        name.cast(),
        value.cast(),
      );
      calloc.free(name);
      calloc.free(value);
    }
    // ----------------------------------------------

    controller.id.value = id;
    if (width != null && height != null) {
      controller.rect.value = Rect.fromLTWH(
        0,
        0,
        width.toDouble(),
        height.toDouble(),
      );
    }

    // Return the [VideoController].
    return controller;
  }

  /// Sets the required size of the video output.
  /// This may yield substantial performance improvements if a small [width] & [height] is specified.
  ///
  /// Remember, “Premature optimization is the root of all evil”. So, use this method wisely.
  @override
  Future<void> setSize({
    int? width,
    int? height,
  }) async {
    final handle = await player.handle;
    if (this.width == width && this.height == height) {
      // No need to resize if the requested size is same as the current size.
      return;
    }
    this.width = width;
    this.height = height;
    // ----------------------------------------------
    NativeLibrary.ensureInitialized();
    final mpv = MPV(DynamicLibrary.open(NativeLibrary.path));
    final name = 'android-surface-size'.toNativeUtf8();
    final value = '${width}x$height'.toNativeUtf8();
    mpv.mpv_set_option_string(
      Pointer.fromAddress(handle),
      name.cast(),
      value.cast(),
    );
    calloc.free(name);
    calloc.free(value);
    // ----------------------------------------------
  }

  /// Disposes the [VideoController].
  /// Releases the allocated resources back to the system.
  @override
  Future<void> dispose() async {
    // Dispose the [StreamSubscription]s.
    await _widthStreamSubscription?.cancel();
    await _heightStreamSubscription?.cancel();
    // Release the native resources.
    final handle = await player.handle;
    _controllers.remove(handle);
    await _channel.invokeMethod(
      'VideoOutputManager.Dispose',
      {
        'handle': handle.toString(),
      },
    );
  }

  /// [StreamSubscription] for listening to video width.
  StreamSubscription<int>? _widthStreamSubscription;

  /// [StreamSubscription] for listening to video height.
  StreamSubscription<int>? _heightStreamSubscription;

  /// Currently created [VideoControllerAndroid]s.
  static final _controllers = HashMap<int, VideoControllerAndroid>();

  /// [MethodChannel] for invoking platform specific native implementation.
  static const _channel = MethodChannel('com.alexmercerind/media_kit_video');
}
