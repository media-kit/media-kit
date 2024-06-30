/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'package:media_kit/src/player/platform_player.dart';
import 'package:meta/meta.dart';
import 'package:synchronized/synchronized.dart';

void webEnsureInitialized({String? libmpv}) {}

class WebPlayer extends PlatformPlayer {
  WebPlayer({required super.configuration});

  /// Whether the [WebPlayer] is initialized for unit-testing.
  @visibleForTesting
  static bool test = false;

  bool disposed = false;

  get element => throw UnimplementedError();

  int get id => 0;

  Lock get lock => Lock();
}
