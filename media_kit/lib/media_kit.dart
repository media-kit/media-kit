/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

// ignore_for_file: camel_case_types

export 'package:media_kit/src/player.dart';
export 'package:media_kit/src/platform_player.dart';

export 'package:media_kit/src/models/media.dart';
export 'package:media_kit/src/models/track.dart';
export 'package:media_kit/src/models/playlist.dart';
export 'package:media_kit/src/models/audio_device.dart';
export 'package:media_kit/src/models/audio_params.dart';
export 'package:media_kit/src/models/playlist_mode.dart';

// For invoking platform specific API.

import 'package:media_kit/src/libmpv/player.dart' as libmpv;
import 'package:media_kit/src/libmpv/core/native_library.dart' as libmpv;

typedef libmpvPlayer = libmpv.Player;
typedef libmpvNativeLibrary = libmpv.NativeLibrary;
