/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:collection';

import 'package:media_kit/src/player/platform_player.dart';
import 'package:meta/meta.dart';

import '../../../models/media/media.dart';

void nativeEnsureInitialized({String? libmpv}) {}

class NativePlayer extends PlatformPlayer {
  NativePlayer({required super.configuration});

  /// Whether the [NativePlayer] is initialized for unit-testing.
  @visibleForTesting
  static bool test = false;

  Object? get ctx => throw UnimplementedError();

  List<Media> current = [];

  bool disposed = false;

  Future<void>? future;

  bool isBufferingStateChangeAllowed = true;

  bool isPlayingStateChangeAllowed = true;

  bool isShuffleEnabled = true;

  Future<void> command(List<String> command) async {}

  Future<String> getProperty(String property) => throw UnimplementedError();

  get mpv => throw UnimplementedError();

  Future<void> observeProperty(
      String property, Future<void> Function(String p1) listener) async {}

  HashMap<String, Future<void> Function(String p1)> get observed =>
      throw UnimplementedError();

  List<Future<void> Function()> get onLoadHooks => [];

  List<Future<void> Function()> get onUnloadHooks => [];

  Future<void> setProperty(String property, String value) async {}

  Future<void> unobserveProperty(String property) async {}
}
