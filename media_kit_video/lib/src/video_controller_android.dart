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
import 'package:synchronized/synchronized.dart';

// ignore_for_file: unused_import, implementation_imports
// It's absolutely crazy that C/C++ interop in Dart is so much easier & less tedious (possibly more performant as well) than in Java/Kotlin.
// I don't want to add some additional code to make it accessible through JNI & additionally bundle it with the app. We can directly use the native library & it's bindings instead to make our life easier & bundle size smaller.
//
// Only downside I can see is that we are now depending package:media_kit_video on package:ffi & package:media_kit. However, it's absolutely fine because package:media_kit_video is crafted for package:media_kit.
// Also... now the API is also improved, now [VideoController.create] consumes [Player] directly instead of [Player.handle] which as an [int].
import 'package:media_kit/generated/libmpv/bindings.dart';
import 'package:media_kit/src/libmpv/core/native_library.dart';

import 'package:media_kit_video/src/video_controller.dart';

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
    super.height,
    super.enableHardwareAcceleration,
  ) {
    // Merge the width & height [Stream]s into a single [Stream] of [Rect]s.
    int w = -1;
    int h = -1;
    _widthStreamSubscription = player.streams.width.listen(
      (event) => _lock.synchronized(() {
        w = event;
        if (w != -1 && h != -1) {
          _controller.add(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
          w = -1;
          h = -1;
        }
      }),
    );
    _heightStreamSubscription = player.streams.height.listen(
      (event) => _lock.synchronized(() {
        h = event;
        if (w != -1 && h != -1) {
          _controller.add(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
          w = -1;
          h = -1;
        }
      }),
    );
    final lock = Lock();
    _rectStreamSubscription = _controller.stream.listen(
      (event) => lock.synchronized(() async {
        rect.value = Rect.zero;
        // ----------------------------------------------
        // With --vo=gpu, we need to update the `android.graphics.SurfaceTexture` size & notify libmpv to re-create vo.
        // In native Android, this kind of rendering is done with `android.view.SurfaceView` + `android.view.SurfaceHolder`, which offers `onSurfaceChanged` callback to handle this.
        if (!enableHardwareAcceleration) {
          final handle = await player.handle;
          await _channel.invokeMethod(
            'VideoOutputManager.SetSurfaceTextureSize',
            {
              'handle': handle.toString(),
              'width': event.width.toInt().toString(),
              'height': event.height.toInt().toString(),
            },
          );
          NativeLibrary.ensureInitialized();
          final mpv = MPV(DynamicLibrary.open(NativeLibrary.path));
          final name = 'android-surface-size'.toNativeUtf8();
          final value =
              '${event.width.toInt()}x${event.height.toInt()}'.toNativeUtf8();
          mpv.mpv_set_option_string(
            Pointer.fromAddress(handle),
            name.cast(),
            value.cast(),
          );
          calloc.free(name);
          calloc.free(value);
        }
        // ----------------------------------------------
        rect.value = event;
      }),
    );
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

    // Enforce software rendering in emulators.
    final bool isEmulator = await _channel.invokeMethod('Utils.IsEmulator');
    if (isEmulator) {
      debugPrint('media_kit: VideoControllerAndroid: Emulator detected.');
      debugPrint('media_kit: VideoControllerAndroid: Enforcing S/W rendering.');
      enableHardwareAcceleration = false;
    }

    // Creation:

    final controller = VideoControllerAndroid(
      player,
      width,
      height,
      enableHardwareAcceleration,
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
    NativeLibrary.ensureInitialized();
    final mpv = MPV(DynamicLibrary.open(NativeLibrary.path));
    final values = enableHardwareAcceleration
        ? {
            // https://mpv.io/manual/stable/#video-output-drivers-mediacodec-embed
            // Truly native hardware decoding & rendering with --vo=mediacodec_embed & --hwdec=mediacodec.
            'opengl-es': 'yes',
            'force-window': 'yes',
            'hwdec': 'mediacodec',
            'gpu-context': 'android',
            'vo': 'mediacodec_embed',
            'wid': wid.toString(),
          }
        : {
            // Software decoding & rendering with --vo=gpu & --hwdec=no.
            // The `android.view.Surface` (bind with `android.graphics.SurfaceTexture`) instance which is passed as --wid to libmpv for rendering, is not actually "mounted" to the Android view hierarchy, because we are using Flutter.
            // The `android.view.Surface` instance is solely created for allowing libmpv to render into it. The Flutter internally reads from `android.graphics.SurfaceTexture` AFAIK.
            //
            // This makes the `android.view.Surface` not size accordingly to the video / display size (& render video as a single 1x1 pixel forever).
            // So, we use `setDefaultBufferSize` to set the size of the video output & make it render accordingly.
            // Learn more: https://developer.android.com/reference/android/graphics/SurfaceTexture#setDefaultBufferSize(int,%20int)
            //
            // From my observations, as soon as we use --vo=gpu, we need to use `setDefaultBufferSize` even with hardware acceleration enabled due to the reason mentioned above.
            'opengl-es': 'yes',
            'force-window': 'yes',
            'hwdec': 'no',
            'gpu-context': 'android',
            'vo': 'gpu',
            'wid': wid.toString(),
          };
    // TODO(@alexmercerind): A few other rendering options might be worth exposing to clients in the future e.g.
    // * --vo=gpu + --hwdec=mediacodec
    // * --vo=gpu + --hwdec=mediacodec-copy
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
  }) {
    throw UnimplementedError(
      '[VideoControllerAndroid.setSize] is not available on Android.',
    );
  }

  /// Disposes the [VideoController].
  /// Releases the allocated resources back to the system.
  @override
  Future<void> dispose() async {
    // Dispose the [StreamSubscription]s.
    await _widthStreamSubscription?.cancel();
    await _heightStreamSubscription?.cancel();
    await _rectStreamSubscription?.cancel();
    // Close the [StreamController]s.
    await _controller.close();
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

  /// [Lock] used to synchronize the [_widthStreamSubscription] & [_heightStreamSubscription].
  final _lock = Lock();

  /// [StreamController] for merging the [_widthStreamSubscription] & [_heightStreamSubscription] into a single [Stream<Rect>].
  final _controller = StreamController<Rect>();

  /// [StreamSubscription] for listening to video width.
  StreamSubscription<int>? _widthStreamSubscription;

  /// [StreamSubscription] for listening to video height.
  StreamSubscription<int>? _heightStreamSubscription;

  /// [StreamSubscription] for listening to video [Rect] from [_controller].
  StreamSubscription<Rect>? _rectStreamSubscription;

  /// Currently created [VideoControllerAndroid]s.
  static final _controllers = HashMap<int, VideoControllerAndroid>();

  /// [MethodChannel] for invoking platform specific native implementation.
  static const _channel = MethodChannel('com.alexmercerind/media_kit_video');
}
