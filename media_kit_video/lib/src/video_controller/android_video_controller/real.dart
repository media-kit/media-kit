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
import 'package:flutter/widgets.dart';
import 'package:synchronized/synchronized.dart';

import 'package:media_kit/media_kit.dart';

// ignore_for_file: implementation_imports
import 'package:media_kit/ffi/ffi.dart';
import 'package:media_kit/src/player/native/core/native_library.dart';

import 'package:media_kit/generated/libmpv/bindings.dart';

import 'package:media_kit_video/src/utils/query_decoders.dart';
import 'package:media_kit_video/src/video_controller/platform_video_controller.dart';

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

  // ----------------------------------------------

  bool get androidAttachSurfaceAfterVideoParameters =>
      configuration.androidAttachSurfaceAfterVideoParameters ??
      vo.startsWith('gpu');

  /// --vo
  String get vo => configuration.vo ?? 'gpu'; // gpu-next doesnt work on atv

  /// --hwdec
  Future<String> get hwdec async {
    if (_hwdec != null) {
      return _hwdec!;
    }
    bool enableHardwareAcceleration = configuration.enableHardwareAcceleration;
    // Enforce software rendering in emulators.
    final bool isEmulator = await _channel.invokeMethod('Utils.IsEmulator');
    if (isEmulator) {
      debugPrint('media_kit: AndroidVideoController: Emulator detected.');
      debugPrint('media_kit: AndroidVideoController: Enforcing S/W rendering.');
      enableHardwareAcceleration = false;
    }
    _hwdec =
        configuration.hwdec ?? (enableHardwareAcceleration ? 'auto' : 'no');
    return _hwdec!;
  }

  String? _hwdec;

  // ----------------------------------------------

  String? _current;

  /// {@macro android_video_controller}
  AndroidVideoController._(
    super.player,
    super.configuration,
  ) {
    final platform = player.platform as NativePlayer;

    platform.onUnloadHooks.add(() {
      return _lock.synchronized(
        () async {
          _current = null;

          final handle = await player.handle;
          NativeLibrary.ensureInitialized();
          final mpv = MPV(DynamicLibrary.open(NativeLibrary.path));
          // Release any references to current android.view.Surface.
          //
          // It is important to set --vo=null here for 2 reasons:
          // 1. Allow the native code to drop any references to the android.view.Surface.
          // 2. Resize the android.graphics.SurfaceTexture to next video's resolution before setting --vo=gpu.
          try {
            // ----------------------------------------------
            final values = {
              // NOTE: ORDER IS IMPORTANT.
              'vo': 'null',
              'wid': '0',
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
          } catch (exception, stacktrace) {
            debugPrint(exception.toString());
            debugPrint(stacktrace.toString());
          }
        },
      );
    });

    _subscription = player.stream.videoParams.listen(
      (event) => _lock.synchronized(() async {
        if ([0, null].contains(event.dw) || [0, null].contains(event.dh)) {
          return;
        }

        final int width;
        final int height;
        if (event.rotate == 0 || event.rotate == 180) {
          width = event.dw ?? 0;
          height = event.dh ?? 0;
        } else {
          // width & height are swapped for 90 or 270 degrees rotation.
          width = event.dh ?? 0;
          height = event.dw ?? 0;
        }

        try {
          final handle = await player.handle;
          NativeLibrary.ensureInitialized();
          final mpv = MPV(DynamicLibrary.open(NativeLibrary.path));

          if (vo.startsWith('gpu')) {
            // NOTE: Only required for --vo=gpu
            // With --vo=gpu, we need to update the android.graphics.SurfaceTexture size & notify libmpv to re-create vo.
            // In native Android, this kind of rendering is done with android.view.SurfaceView + android.view.SurfaceHolder, which offers onSurfaceChanged to handle this.
            final name = 'path'.toNativeUtf8();
            final path = mpv.mpv_get_property_string(
              Pointer.fromAddress(handle),
              name.cast(),
            );
            final current = path.cast<Utf8>().toDartString();
            calloc.free(name.cast());
            mpv.mpv_free(path.cast());

            final force = current != _current;
            if (force) {
              this.width = null;
              this.height = null;
            }

            _current = current;

            await setSize(
              width: this.width ?? width.toInt(),
              height: this.height ?? height.toInt(),
              synchronized: false,
              force: force,
            );

            // // ----------------------------------------------
            // final values = {
            //   // NOTE: ORDER IS IMPORTANT.
            //   // 'android-surface-size': [width, height].join('x'),
            //   'wid': _wid.toString(),
            //   'vo': vo,
            // };

            // for (final entry in values.entries) {
            //   final name = entry.key.toNativeUtf8();
            //   final value = entry.value.toNativeUtf8();
            //   mpv.mpv_set_option_string(
            //     Pointer.fromAddress(handle),
            //     name.cast(),
            //     value.cast(),
            //   );
            //   calloc.free(name);
            //   calloc.free(value);
            // }
          }
          // ----------------------------------------------
        } catch (exception, stacktrace) {
          debugPrint(exception.toString());
          debugPrint(stacktrace.toString());
        }

        if (!vo.startsWith('gpu')) {
          rect.value = Rect.fromLTWH(
            0.0,
            0.0,
            width.toDouble(),
            height.toDouble(),
          );
        }
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
    debugPrint(data.toString());

    controller._id = data['id'];

    // ----------------------------------------------
    NativeLibrary.ensureInitialized();
    final mpv = MPV(DynamicLibrary.open(NativeLibrary.path));

    final values = configuration.vo == null || configuration.hwdec == null
        ? {
            // It is necessary to set vo=null here to avoid SIGSEGV, --wid must be assigned before vo=gpu is set.
            'vo': 'null',
            'hwdec': await controller.hwdec,
          }
        : {
            'vo': 'null',
            'hwdec': await controller.hwdec,
          };
    values.addAll(
      {
        'vid': 'auto',
        'opengl-es': 'yes',
        'force-window': 'yes',
        'gpu-context': 'android',
        'sub-use-margins': 'no',
        'sub-font-provider': 'none',
        // 'sub-scale-with-window': 'yes',
        'hwdec-codecs': 'h264,hevc,mpeg4,mpeg2video,vp8,vp9,av1',
      },
    );

    for (final entry in values.entries) {
      final name = entry.key.toNativeUtf8();
      final value = entry.value.toNativeUtf8();
      mpv.mpv_set_property_string(
        Pointer.fromAddress(handle),
        name.cast(),
        value.cast(),
      );
      calloc.free(name);
      calloc.free(value);
    }
    // ----------------------------------------------

    controller.id.value = controller._id;

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
    bool force = false,
    bool synchronized = true,
  }) async {
    Future<void> function() async {
      final handle = await player.handle;
      final changed = this.width != (width ?? player.state.width) ||
          this.height != (height ?? player.state.height) ||
          _wid == null;
      if (!force && !changed) {
        debugPrint("[AndroidVideoController] Setting size no need to resize");
        // No need to resize if the requested size is same as the current size.
        return;
      }

      this.width = width ?? player.state.width;
      this.height = height ?? player.state.height;

      debugPrint(
          '[AndroidVideoController] Setting size to ${this.width} x ${this.height}, old: ${(width ?? player.state.width)} x ${(height ?? player.state.height)}, wid: $_wid');

      final res = await _channel.invokeMethod(
        'VideoOutputManager.CreateSurface',
        {
          'handle': handle.toString(),
          'width': this.width.toString(),
          'height': this.height.toString(),
        },
      );

      await _updateWID(wid: res['wid'], force: true);

      final mpv = (player.platform as NativePlayer);

      await mpv.setProperty('android-surface-size', '${this.width}x${this.height}');

      rect.value =
          Rect.fromLTWH(0, 0, this.width!.toDouble(), this.height!.toDouble());

      // if (!player.state.playing && changed) {
      //   player.seekRelative(Duration.zero);
      // }
    }

    if (synchronized) {
      return _lock.synchronized(function);
    } else {
      return function();
    }
  }

  Future<void> _updateWID({required int wid, bool force = false}) async {
    if (wid == _wid && !force) {
      return;
    }

    final mpv = (player.platform as NativePlayer);
    if (!mpv.disposed) {
      if (wid != _wid) {
        await mpv.setProperty('vo', 'null');
        await mpv.setProperty('wid', '0');
      }

      _wid = wid;

      if (wid != 0) {
        await mpv.setProperty('wid', wid.toString());
        await mpv.setProperty('vo', vo);
      }
    }
  }

  /// Disposes the instance. Releases allocated resources back to the system.
  Future<void> _dispose() async {
    // Dispose the [StreamSubscription]s.
    await _subscription?.cancel();
    // Release the native resources.
    final handle = await player.handle;
    await _updateWID(wid: 0);
    _controllers.remove(handle);
    await _channel.invokeMethod(
      'VideoOutputManager.Dispose',
      {
        'handle': handle.toString(),
      },
    );
  }

  /// Texture ID returned by Flutter's texture registry.
  int? _id;

  /// Pointer address to the global object reference of `android.view.Surface` i.e. `(intptr_t)(*android.view.Surface)`.
  int? _wid;

  /// [Lock] used to synchronize the [_widthStreamSubscription] & [_heightStreamSubscription].
  final _lock = Lock();

  /// [StreamSubscription] for listening to video [Rect] from [_controller].
  StreamSubscription<VideoParams>? _subscription;

  /// Currently created [AndroidVideoController]s.
  static final _controllers = HashMap<int, AndroidVideoController>();

  /// [MethodChannel] for invoking platform specific native implementation.
  static final _channel =
      const MethodChannel('com.alexmercerind/media_kit_video')
        ..setMethodCallHandler(
          (MethodCall call) async {
            try {
              debugPrint(call.method.toString());
              debugPrint(call.arguments.toString());
              switch (call.method) {
                case 'VideoOutput.WaitUntilFirstFrameRenderedNotify':
                  {
                    // Notify about updated texture ID & [Rect].
                    final int handle = call.arguments['handle'];
                    debugPrint(handle.toString());
                    // Notify about the first frame being rendered.
                    final completer = _controllers[handle]
                        ?.waitUntilFirstFrameRenderedCompleter;
                    if (!(completer?.isCompleted ?? true)) {
                      completer?.complete();
                    }
                    break;
                  }
                case 'VideoOutput.SurfaceUpdatedNotify':
                  {
                    // Notify about updated texture ID & [Rect].
                    final int handle = call.arguments['handle'];
                    final int wid = call.arguments['wid'];

                    _controllers[handle]?._updateWID(wid: wid);
                    break;
                  }
                default:
                  {
                    break;
                  }
              }
            } catch (exception, stacktrace) {
              debugPrint(exception.toString());
              debugPrint(stacktrace.toString());
            }
          },
        );
}
