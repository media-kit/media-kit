/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:async';

import 'package:flutter/services.dart';

import 'package:media_kit_video/src/picture_in_picture/pip_event.dart';
import 'package:media_kit_video/src/picture_in_picture/picture_in_picture_controller.dart';

/// Android 8.0 (API 26)+ implementation of [PictureInPictureController]
/// backed by `Activity.enterPictureInPictureMode`.
///
/// The Android model is different from iOS: the whole Activity (i.e. the
/// Flutter surface) is minimized to a system-level floating window, so the
/// native side does not need frame pumping; it just toggles the Activity
/// mode and forwards `onPictureInPictureModeChanged` callbacks back to
/// Dart through the event channel.
class PictureInPictureAndroid implements PictureInPictureController {
  PictureInPictureAndroid();

  static const MethodChannel _method =
      MethodChannel('com.alexmercerind/media_kit_video/pip');
  static const EventChannel _events =
      EventChannel('com.alexmercerind/media_kit_video/pip/events');

  Stream<PipEvent>? _eventStream;

  @override
  Future<bool> isSupported() async {
    try {
      final supported = await _method.invokeMethod<bool>('isSupported');
      return supported ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<bool> isActive() async {
    try {
      final active = await _method.invokeMethod<bool>('isActive');
      return active ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> start({
    required int handle,
    required Size videoSize,
    bool autoEnter = true,
    bool startImmediately = false,
  }) async {
    try {
      await _method.invokeMethod<void>('start', <String, dynamic>{
        'width': videoSize.width,
        'height': videoSize.height,
        'autoEnter': autoEnter,
        'startImmediately': startImmediately,
      });
    } on MissingPluginException {
      // Android version does not support PiP; silently no-op.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _method.invokeMethod<void>('stop');
    } on MissingPluginException {
      // no-op
    }
  }

  @override
  Future<void> setAutoEnter({required bool enabled}) async {
    try {
      await _method.invokeMethod<void>(
        'setAutoEnter',
        <String, dynamic>{'enabled': enabled},
      );
    } on MissingPluginException {
      // no-op
    }
  }

  @override
  Stream<PipEvent> get events =>
      _eventStream ??= _events
          .receiveBroadcastStream()
          .map(_mapEvent)
          .asBroadcastStream();

  PipEvent _mapEvent(dynamic raw) {
    if (raw is! Map) return const PipFailed('invalid_payload');
    final name = raw['event'];
    switch (name) {
      case 'willStart':
        return const PipWillStart();
      case 'didStart':
        return const PipDidStart();
      case 'willStop':
        return const PipWillStop();
      case 'didStop':
        return const PipDidStop();
      case 'closed':
        return const PipClosed();
      case 'failed':
        return PipFailed(raw['reason']?.toString() ?? 'unknown');
      default:
        return PipFailed('unknown_event:$name');
    }
  }
}
