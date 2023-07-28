/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:io';
import 'dart:ffi';
import 'dart:async';
import 'dart:collection';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:synchronized/synchronized.dart';

import 'package:media_kit/media_kit.dart';
// It's absolutely crazy that C/C++ interop in Dart is so much easier & less tedious (possibly more performant as well) than in Java/Kotlin.
// I don't want to add some additional code to make it accessible through JNI & additionally bundle it with the app. We can directly use the native library & it's bindings instead to make our life easier & bundle size smaller.
//
// Only downside I can see is that we are now depending package:media_kit_video on package:ffi & package:media_kit. However, it's absolutely fine because package:media_kit_video is crafted for package:media_kit.
// Also... now the API is also improved, now [VideoController.create] consumes [Player] directly instead of [Player.handle] which as an [int].
// ignore_for_file: unused_import, implementation_imports
import 'package:media_kit/ffi/ffi.dart';
import 'package:media_kit/src/player/native/core/native_library.dart';

import 'package:media_kit/generated/libmpv/bindings.dart';

import 'package:media_kit_video/src/video_controller/video_controller.dart';
import 'package:media_kit_video/src/video_controller/platform_video_controller.dart';

import 'package:media_kit_video/src/video_controller/utils/query_decoders.dart';

/// {@template android_video_controller}
///
/// AndroidVideoController
/// ----------------------
///
/// The [PlatformVideoController] implementation based on native JNI & C/C++ used on Android.
///
/// {@endtemplate}
class AndroidVideoController extends PlatformVideoController {
  /// Whether [AndroidVideoController] is supported on the current platform or not.
  static bool get supported => Platform.isAndroid;

  /// Fixed width of the video output.
  int? width;

  /// Fixed height of the video output.
  int? height;

  /// {@macro android_video_controller}
  AndroidVideoController._(
    super.player,
    super.configuration,
  ) {
    // Notify about the first frame being rendered.
    // Case: If some [Media] is already playing when [VideoController] is created.
    if (player.state.width != null && player.state.height != null) {
      if (!waitUntilFirstFrameRenderedCompleter.isCompleted) {
        waitUntilFirstFrameRenderedCompleter.complete();
      }
    }

    // Merge the width & height [Stream]s into a single [Stream] of [Rect]s.
    int w = -1;
    int h = -1;
    _widthStreamSubscription = player.stream.width.listen(
      (event) => _lock.synchronized(() {
        if (event != null && event > 0) {
          w = event;
          if (w != -1 && h != -1) {
            _controller.add(
              Rect.fromLTWH(
                0.0,
                0.0,
                w.toDouble(),
                h.toDouble(),
              ),
            );
            w = -1;
            h = -1;
          }
        }
      }),
    );
    _heightStreamSubscription = player.stream.height.listen(
      (event) => _lock.synchronized(() {
        if (event != null && event > 0) {
          h = event;
          if (w != -1 && h != -1) {
            _controller.add(
              Rect.fromLTWH(
                0.0,
                0.0,
                w.toDouble(),
                h.toDouble(),
              ),
            );
            w = -1;
            h = -1;
          }
        }
      }),
    );

    _rectStreamSubscription = _controller.stream.listen(
      (event) => _lock.synchronized(() async {
        rect.value = Rect.zero;
        try {
          // ----------------------------------------------
          final handle = await player.handle;
          NativeLibrary.ensureInitialized();
          final mpv = MPV(DynamicLibrary.open(NativeLibrary.path));
          final property = 'vo'.toNativeUtf8();
          final vo = mpv.mpv_get_property_string(
            Pointer.fromAddress(handle),
            property.cast(),
          );
          debugPrint(vo.cast<Utf8>().toDartString());
          if (vo.cast<Utf8>().toDartString() == 'gpu') {
            // NOTE: Only required for --vo=gpu
            // With --vo=gpu, we need to update the android.graphics.SurfaceTexture size & notify libmpv to re-create vo.
            // In native Android, this kind of rendering is done with android.view.SurfaceView + android.view.SurfaceHolder, which offers onSurfaceChanged to handle this.
            await _channel.invokeMethod(
              'VideoOutputManager.SetSurfaceTextureSize',
              {
                'handle': handle.toString(),
                'width': event.width.toInt().toString(),
                'height': event.height.toInt().toString(),
              },
            );
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
          calloc.free(property);
          mpv.mpv_free(vo.cast());

          // Notify about the first frame being rendered.
          if (!waitUntilFirstFrameRenderedCompleter.isCompleted) {
            // The first-time resize of the surface causes a glitchy frame to be rendered. Add a voluntary delay to avoid that.
            await Future.delayed(const Duration(milliseconds: 50));
            waitUntilFirstFrameRenderedCompleter.complete();
          }

          // ----------------------------------------------
        } catch (exception, stacktrace) {
          debugPrint(exception.toString());
          debugPrint(stacktrace.toString());
        }
        rect.value = event;
      }),
    );
  }

  /// {@macro android_video_controller}
  static Future<PlatformVideoController> create(
    Player player,
    VideoControllerConfiguration configuration,
  ) async {
    // Retrieve the native handle of the [Player].
    final handle = await player.handle;
    // Return the existing [VideoController] if it's already created.
    if (_controllers.containsKey(handle)) {
      return _controllers[handle]!;
    }

    bool enableHardwareAcceleration = configuration.enableHardwareAcceleration;

    // Enforce software rendering in emulators.
    final bool isEmulator = await _channel.invokeMethod('Utils.IsEmulator');
    if (isEmulator) {
      debugPrint('media_kit: AndroidVideoController: Emulator detected.');
      debugPrint('media_kit: AndroidVideoController: Enforcing S/W rendering.');
      enableHardwareAcceleration = false;
    }

    // Creation:
    final controller = AndroidVideoController._(
      player,
      configuration,
    );
    // Register [_dispose] for execution upon [Player.dispose].
    player.platform?.release.add(controller._dispose);

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

    // In case no video-decoders are found, this means media_kit_libs_***_audio is being used.
    // Thus, --vid=no is required to prevent libmpv from trying to decode video (otherwise bad things may happen).
    //
    // Search for common H264 decoder to check if video support is available.
    final decoders = await queryDecoders(handle);
    if (!decoders.contains('h264')) {
      throw UnsupportedError(
        '[VideoController] is not available.'
        ' '
        'Please use media_kit_libs_***_video instead of media_kit_libs_***_audio.',
      );
    }

    // ----------------------------------------------
    NativeLibrary.ensureInitialized();
    final mpv = MPV(DynamicLibrary.open(NativeLibrary.path));
    final values = configuration.vo == null || configuration.hwdec == null
        ? enableHardwareAcceleration
            ? {
                // H/W decoding & rendering with --vo=gpu + --hwdec=mediacodec.
                'vo': 'gpu',
                'hwdec': 'mediacodec',
                'vid': 'auto',
                'opengl-es': 'yes',
                'force-window': 'yes',
                'gpu-context': 'android',
                'wid': wid.toString(),
              }
            : {
                // S/W decoding & rendering with --vo=gpu + --hwdec=no.
                'vo': 'gpu',
                'hwdec': 'no',
                'vid': 'auto',
                'opengl-es': 'yes',
                'force-window': 'yes',
                'gpu-context': 'android',
                'wid': wid.toString(),
              }
        : {
            'vo': configuration.vo!,
            'hwdec': configuration.hwdec!,
            'vid': 'auto',
            'opengl-es': 'yes',
            'force-window': 'yes',
            'gpu-context': 'android',
            'wid': wid.toString(),
          };
    // TODO(@alexmercerind): Few other rendering options might be worth exposing to clients in the future.
    values.addAll(
      {
        'sub-use-margins': 'no',
        'sub-font-provider': 'none',
        'sub-scale-with-window': 'yes',
        'hwdec-codecs': 'h264,hevc,mpeg4,mpeg2video,vp8,vp9,av1',
      },
    );

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

    // Return the [PlatformVideoController].
    return controller;
  }

  /// Sets the required size of the video output.
  /// This may yield substantial performance improvements if a small [width] & [height] is specified.
  ///
  /// Remember:
  /// * “Premature optimization is the root of all evil”
  /// * “With great power comes great responsibility”
  @override
  Future<void> setSize({
    int? width,
    int? height,
  }) {
    throw UnsupportedError(
      '[AndroidVideoController.setSize] is not available on Android',
    );
  }

  /// Disposes the instance. Releases allocated resources back to the system.
  Future<void> _dispose() async {
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
  StreamSubscription<int?>? _widthStreamSubscription;

  /// [StreamSubscription] for listening to video height.
  StreamSubscription<int?>? _heightStreamSubscription;

  /// [StreamSubscription] for listening to video [Rect] from [_controller].
  StreamSubscription<Rect>? _rectStreamSubscription;

  /// Currently created [AndroidVideoController]s.
  static final _controllers = HashMap<int, AndroidVideoController>();

  /// [MethodChannel] for invoking platform specific native implementation.
  static const _channel = MethodChannel('com.alexmercerind/media_kit_video');
}
