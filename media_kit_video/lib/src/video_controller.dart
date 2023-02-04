/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

/// Currently created [VideoController]s.
/// This is used to notify about updated texture IDs through [_channel].
HashMap<int, VideoController> _controllers = HashMap<int, VideoController>();

/// {@template video_controller}
///
/// VideoController
/// ---------------
///
/// This class is used to initialize & handle the video rendering inside the Flutter widget tree.
///
/// A [VideoController] must be created right after creating the [Player] from `package:media_kit`.
/// Pass the [handle] of the [Player] from `package:media_kit` to the [VideoController] constructor.
///
/// ```dart
/// final player = Player();
/// final controller = await VideoController.create(player.handle);
/// ```
///
/// It is important to [dispose] the [VideoController] when it is no longer needed.
/// It will release the allocated resources back to the system.
///
/// **Notes**
///
/// 1. You can limit size of the video output by specifying `width` & `height`.
///    By default, both `height` & `width` are `null` i.e. output is based on video's resolution.
/// 2. You can switch between GPU & CPU rendering by specifying `enableHardwareAcceleration`.
///    By default, `enableHardwareAcceleration` is `true` i.e. GPU (Direct3D/OpenGL/METAL) is utilized.
///
/// {@endtemplate}
class VideoController {
  /// Handle of the [Player] from `package:media_kit`.
  final int handle;

  /// Fixed width of the video output.
  final int? width;

  /// Fixed height of the video output.
  final int? height;

  /// Whether hardware acceleration should be enabled or not.
  final bool enableHardwareAcceleration;

  /// Texture ID of the video output, registered with Flutter engine by the native implementation.
  final ValueNotifier<int?> id = ValueNotifier<int?>(null);

  /// [Rect] of the video output, received from the native implementation.
  final ValueNotifier<Rect?> rect = ValueNotifier<Rect?>(null);

  /// {@macro video_controller}
  VideoController._(
    this.handle,
    this.width,
    this.height, {
    this.enableHardwareAcceleration = true,
  }) {
    // Save in [HashMap] for getting notified about updated texture IDs.
    _controllers[handle] = this;
  }

  /// {@macro video_controller}
  static Future<VideoController> create(
    Future<int> handle, {
    int? width,
    int? height,
    bool enableHardwareAcceleration = true,
  }) async {
    final controller = VideoController._(
      await handle,
      width,
      height,
      enableHardwareAcceleration: enableHardwareAcceleration,
    );

    // Wait until first texture ID is received i.e. render context & EGL/D3D surface is created.
    // We are not waiting on the native-side itself because it will block the UI thread.
    // Background platform channels are not a thing yet.
    final completer = Completer<void>();
    void listener() {
      if (controller.id.value != null) {
        debugPrint('VideoController: Texture ID: ${controller.id.value}');
        completer.complete();
      }
    }

    controller.id.addListener(listener);

    // Invoking native implementation for querying video adapter, registering OpenGL/Direct3D/ANGLE/pixel-buffer output callbacks & Flutter texture.
    // NOTE: Sending `int64_t` is causing crash on Windows 7, so sending as string.
    await _channel.invokeMethod(
      'VideoOutputManager.Create',
      {
        'handle': controller.handle.toString(),
        'width': controller.width.toString(),
        'height': controller.height.toString(),
        'enableHardwareAcceleration': controller.enableHardwareAcceleration,
      },
    );

    await completer.future;
    controller.id.removeListener(listener);

    // Return the [VideoController].
    return controller;
  }

  /// Disposes the [VideoController].
  /// Releases the allocated resources back to the system.
  Future<void> dispose() {
    _controllers.remove(handle);
    // NOTE: Sending `int64_t` is causing crash on Windows 7, so sending as string.
    return _channel.invokeMethod(
      'VideoOutputManager.Dispose',
      {
        'handle': handle.toString(),
      },
    );
  }

  @override
  String toString() {
    return 'VideoController(handle: $handle, width: $width, height: $height, id: ${id.value}, rect: $rect)';
  }
}

/// [MethodChannel] for invoking platform specific native implementation.
final _channel = const MethodChannel('com.alexmercerind/media_kit_video')
  ..setMethodCallHandler(
    (MethodCall call) async {
      try {
        debugPrint(call.method.toString());
        debugPrint(call.arguments.toString());
        switch (call.method) {
          case 'VideoOutput.Resize':
            {
              // Notify about updated texture ID & [Rect].
              final int handle = call.arguments['handle'];
              final Rect rect = Rect.fromLTWH(
                call.arguments['rect']['left'] * 1.0,
                call.arguments['rect']['top'] * 1.0,
                call.arguments['rect']['width'] * 1.0,
                call.arguments['rect']['height'] * 1.0,
              );
              final int id = call.arguments['id'];
              _controllers[handle]?.rect.value = rect;
              _controllers[handle]?.id.value = id;
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
