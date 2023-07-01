/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
// ignore_for_file: camel_case_types
import 'package:meta/meta.dart';

import 'package:media_kit/src/player/platform_player.dart';

void webEnsureInitialized({String? libmpv}) {}

class webPlayer extends PlatformPlayer {
  webPlayer({required super.configuration});

  /// Whether the `<video>` element should have muted attribute or not.
  @visibleForTesting
  static bool muted = false;
}
