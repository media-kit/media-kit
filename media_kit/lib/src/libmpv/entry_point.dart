/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'package:media_kit/src/libmpv/core/native_library.dart';
import 'package:media_kit/src/libmpv/core/initializer_native_event_loop.dart';

/// Initializes the libmpv backend for package:media_kit.
///
/// Following optional parameters are available:
/// * `libmpv`: Manually specified the path to the libmpv shared library.
void ensureInitialized({String? libmpv}) {
  NativeLibrary.ensureInitialized(libmpv: libmpv);
  InitializerNativeEventLoop.ensureInitialized();
}
