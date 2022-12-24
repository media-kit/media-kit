/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:async';
import 'package:flutter/services.dart';

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
/// final controller = VideoController(player.handle);
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
  final Future<int> handle;

  /// Fixed width of the video output.
  final int? width;

  /// Fixed height of the video output.
  final int? height;

  /// Texture ID of the video output, registered with the Flutter engine by native implementation.
  final Completer<int> id = Completer<int>();

  /// {@macro video_controller}
  VideoController(
    this.handle, {
    this.width,
    this.height,
  }) {
    handle.then((handle) {
      // Invoking native implementation for querying video adapter, registering OpenGL/Direct3D/ANGLE/pixel-buffer output callbacks & Flutter texture.
      _channel.invokeMethod(
        'VideoOutputManager.Create',
        {
          'handle': handle,
          'width': width,
          'height': height,
        },
      ).then(
        (value) {
          if (!id.isCompleted) {
            id.complete(value);
          }
        },
      );
    });
  }

  /// Disposes the [VideoController].
  /// Releases the allocated resources back to the system.
  Future<void> dispose() async {
    final ctx = await handle;
    await _channel.invokeMethod(
      'VideoOutputManager.Dispose',
      {
        'handle': ctx,
      },
    );
  }
}

/// [MethodChannel] for invoking platform specific native implementation.
const _channel = MethodChannel('com.alexmercerind/media_kit_core_video');
