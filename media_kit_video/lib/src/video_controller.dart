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
/// Optionally, fixed [width] & [height] can be passed.
/// Setting smaller [width] & [height] values can result in better performance especially on low-end devices & software rendering.
/// This will cause the video output to use the specified dimensions, instead of the original dimensions of the video.
/// Default is `null`, which means the original dimensions of the video will be used.
///
/// Internally, the [VideoController] invokes platform specific native implementation for video rendering.
/// Hardware acceleration is enabled by default.
/// The implementation will fallback to software rendering if system does not have proper support for it.
///
/// {@endtemplate}
class VideoController {
  /// Handle of the [Player] from `package:media_kit`.
  final int handle;

  /// Fixed width of the video output.
  final int? width;

  /// Fixed height of the video output.
  final int? height;

  /// Texture ID of the video output, registered with Flutter engine by the native implementation.
  final ValueNotifier<int?> id = ValueNotifier<int?>(null);

  /// [Rect] of the video output, received from the native implementation.
  final ValueNotifier<Rect?> rect = ValueNotifier<Rect?>(null);

  /// {@macro video_controller}
  VideoController._(
    this.handle,
    this.width,
    this.height,
  ) {
    // Save in [HashMap] for getting notified about updated texture IDs.
    _controllers[handle] = this;
  }

  /// {@macro video_controller}
  static Future<VideoController> create(
    Future<int> handle, {
    int? width,
    int? height,
  }) async {
    final controller = VideoController._(
      await handle,
      width,
      height,
    );
    // Invoking native implementation for querying video adapter, registering OpenGL/Direct3D/ANGLE/pixel-buffer output callbacks & Flutter texture.
    final result = await _channel.invokeMethod(
      'VideoOutputManager.Create',
      {
        'handle': controller.handle.toString(),
        'width': controller.width.toString(),
        'height': controller.height.toString(),
      },
    );
    // Notify about updated texture ID & [Rect].
    final Rect rect = Rect.fromLTRB(
      result['rect']['left'] * 1.0,
      result['rect']['top'] * 1.0,
      result['rect']['right'] * 1.0,
      result['rect']['bottom'] * 1.0,
    );
    final int id = result['id'];
    controller.rect.value = rect;
    controller.id.value = id;
    // Return the [VideoController].
    return controller;
  }

  /// Disposes the [VideoController].
  /// Releases the allocated resources back to the system.
  Future<void> dispose() {
    _controllers.remove(handle);
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
      debugPrint(call.method.toString());
      debugPrint(call.arguments.toString());
      switch (call.method) {
        case 'VideoOutput.Resize':
          {
            // Notify about updated texture ID & [Rect].
            final int handle = call.arguments['handle'];
            final Rect rect = Rect.fromLTRB(
              call.arguments['rect']['left'] * 1.0,
              call.arguments['rect']['top'] * 1.0,
              call.arguments['rect']['right'] * 1.0,
              call.arguments['rect']['bottom'] * 1.0,
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
    },
  );
