/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/src/utils/query_decoders.dart';
import 'package:media_kit_video/src/video_controller/platform_video_controller.dart';
import 'package:synchronized/synchronized.dart';

/// {@template native_video_controller}
///
/// NativeVideoController
/// ---------------------
///
/// The [PlatformVideoController] implementation based on native C/C++ used on:
/// * Windows
/// * GNU/Linux
/// * macOS
/// * iOS
///
/// {@endtemplate}
class NativeVideoController extends PlatformVideoController {
  /// Whether [NativeVideoController] is supported on the current platform or not.
  static bool get supported =>
      Platform.isWindows ||
      Platform.isLinux ||
      Platform.isMacOS ||
      Platform.isIOS;

  /// Fixed width of the video output.
  int? width;

  /// Fixed height of the video output.
  int? height;

  /// Width of the video (from [VideoParams]).
  int? videoParamsWidth;

  /// Height of the video (from [VideoParams]).
  int? videoParamsHeight;

  /// [Lock] used to synchronize [onLoadHooks], [onUnloadHooks] & [subscription].
  final lock = Lock();

  NativePlayer get platform => player.platform as NativePlayer;

  Future<void> setProperty(String key, String value) async {
    _checkActive();
    await platform.setProperty(key, value, waitForInitialization: false);
    _checkActive();
  }

  Future<void> setProperties(Map<String, String> properties) async {
    // ORDER IS IMPORTANT.
    for (final entry in properties.entries) {
      await setProperty(entry.key, entry.value);
    }
  }

  /// [StreamSubscription] for listening to video [Rect].
  StreamSubscription<VideoParams>? videoParamsSubscription;
  bool _disposed = false;
  bool _nativeCreateRequested = false;
  Future<void>? _disposal;
  Future<PlatformVideoController>? _creation;
  final _textureReady = Completer<void>();

  void _checkActive() {
    if (_disposed || platform.disposeRequested.isCompleted) {
      throw StateError('Video controller is disposing');
    }
  }

  /// {@macro native_video_controller}
  NativeVideoController._(super.player, super.configuration)
      : width = configuration.width,
        height = configuration.height {
    _textureReady.future.ignore();
    waitUntilFirstFrameRenderedCompleter.future.ignore();
    videoParamsSubscription = player.stream.videoParams.listen(
      (event) => lock.synchronized(() async {
        if (_disposed) return;
        if ([0, null].contains(event.dw) || [0, null].contains(event.dh)) {
          return;
        }

        final int handle = await player.handle;
        if (_disposed) return;

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

        if (videoParamsWidth == width && videoParamsHeight == height) {
          return;
        }

        await _channel.invokeMethod('VideoOutputManager.SetSize', {
          'handle': handle.toString(),
          // Windows reads both automatic dimensions from one native snapshot.
          // Keep fixed configuration sizes when video parameters change.
          'width': (Platform.isWindows ? this.width : width).toString(),
          'height': (Platform.isWindows ? this.height : height).toString(),
        });
        videoParamsWidth = width;
        videoParamsHeight = height;
      }).catchError((Object error, StackTrace stack) {
        // Stream listeners do not consume asynchronous callback errors.
        // Leave dimensions unchanged so a subsequent update can retry.
        debugPrint('$error\n$stack');
      }),
    );
  }

  /// {@macro native_video_controller}
  static Future<PlatformVideoController> create(
    Player player,
    VideoControllerConfiguration configuration,
  ) async {
    // Update [configuration] to have default values.
    configuration = configuration.copyWith(
      vo: configuration.vo ?? 'libmpv',
      hwdec: configuration.hwdec ?? 'auto',
    );

    // Retrieve the native handle of the [Player].
    final handle = await player.handle;
    if (player.platform!.disposeRequested.isCompleted) {
      throw StateError('Player is disposing');
    }
    // Concurrent callers must await the same completed initialization.
    if (_controllers.containsKey(handle)) {
      return _controllers[handle]!._creation!;
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

    if (player.platform!.disposeRequested.isCompleted) {
      throw StateError('Player is disposing');
    }
    if (_controllers.containsKey(handle)) {
      return _controllers[handle]!._creation!;
    }
    final controller = NativeVideoController._(player, configuration);
    player.platform?.release.add(controller._dispose);
    _controllers[handle] = controller;
    return controller._creation = controller._initialize(handle);
  }

  Future<PlatformVideoController> _initialize(int handle) async {
    try {
      await Future.any<void>([
        _createNative(handle),
        platform.disposeRequested.future.then((_) {
          throw StateError('Video controller creation cancelled by dispose');
        }),
      ]);
      _checkActive();
      return this;
    } catch (_) {
      await _dispose();
      rethrow;
    }
  }

  Future<void> _createNative(int handle) async {
    await setProperties({
      'vo': configuration.vo!,
      'hwdec': configuration.hwdec!,
      'vid': 'auto',
    });
    _checkActive();
    _nativeCreateRequested = true;
    await _channel.invokeMethod('VideoOutputManager.Create', {
      'handle': handle.toString(),
      'configuration': {
        'width': configuration.width.toString(),
        'height': configuration.height.toString(),
        'enableHardwareAcceleration': configuration.enableHardwareAcceleration,
      },
    });
    _checkActive();
    await _textureReady.future;
  }

  /// Sets the required size of the video output.
  /// This may yield substantial performance improvements if a small [width] & [height] is specified.
  ///
  /// Remember:
  /// * “Premature optimization is the root of all evil”
  /// * “With great power comes great responsibility”
  @override
  Future<void> setSize({int? width, int? height}) async {
    if (_disposed) return;
    final handle = await player.handle;
    if (_disposed) return;
    if (this.width == width && this.height == height) {
      // No need to resize if the requested size is same as the current size.
      return;
    }
    if (width != null && height != null) {
      this.width = width;
      this.height = height;
      await _channel.invokeMethod('VideoOutputManager.SetSize', {
        'handle': handle.toString(),
        'width': width.toString(),
        'height': height.toString(),
      });
    } else {
      this.width = null;
      this.height = null;
      await _channel.invokeMethod('VideoOutputManager.SetSize', {
        'handle': handle.toString(),
        'width': Platform.isWindows
            ? 'null'
            : videoParamsWidth?.toString() ?? 'null',
        'height': Platform.isWindows
            ? 'null'
            : videoParamsHeight?.toString() ?? 'null',
      });
    }
  }

  /// Disposes the instance. Releases allocated resources back to the system.
  Future<void> _dispose() => _disposal ??= _disposeOnce();

  Future<void> _disposeOnce() async {
    _disposed = true;
    final error = StateError('Video controller disposed before becoming ready');
    if (!_textureReady.isCompleted) _textureReady.completeError(error);
    if (!waitUntilFirstFrameRenderedCompleter.isCompleted) {
      waitUntilFirstFrameRenderedCompleter.completeError(error);
    }
    final handle = await player.handle;
    if (identical(_controllers[handle], this)) _controllers.remove(handle);
    player.platform?.release.remove(_dispose);
    try {
      await videoParamsSubscription?.cancel();
      await lock.synchronized(() async {
        if (_nativeCreateRequested) {
          await _channel.invokeMethod('VideoOutputManager.Dispose', {
            'handle': handle.toString(),
          });
        }
      });
    } finally {
      super.dispose();
    }
  }

  /// Currently created [NativeVideoController]s.
  /// This is used to notify about updated texture IDs & [Rect]s through [_channel].
  static final _controllers = HashMap<int, NativeVideoController>();

  /// [MethodChannel] for invoking platform specific native implementation.
  static final _channel =
      const MethodChannel('com.alexmercerind/media_kit_video')
        ..setMethodCallHandler((MethodCall call) async {
          try {
            debugPrint(call.method.toString());
            debugPrint(call.arguments.toString());
            switch (call.method) {
              case 'VideoOutput.Resize':
                {
                  // Notify about updated texture ID & [Rect].
                  final int handle = call.arguments['handle'];
                  if (_controllers[handle]?._disposed ?? true) return;
                  final Rect rect = Rect.fromLTWH(
                    call.arguments['rect']['left'] * 1.0,
                    call.arguments['rect']['top'] * 1.0,
                    call.arguments['rect']['width'] * 1.0,
                    call.arguments['rect']['height'] * 1.0,
                  );
                  final int id = call.arguments['id'];
                  _controllers[handle]?.rect.value = rect;
                  _controllers[handle]?.id.value = id;
                  final ready = _controllers[handle]?._textureReady;
                  if (id >= 0 && ready != null && !ready.isCompleted) {
                    ready.complete();
                  }
                  // Notify about the first frame being rendered.
                  if (rect.width > 0 && rect.height > 0) {
                    final completer = _controllers[handle]
                        ?.waitUntilFirstFrameRenderedCompleter;
                    if (!(completer?.isCompleted ?? true)) {
                      completer?.complete();
                    }
                  }
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
        });
}
