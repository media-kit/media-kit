/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

// [kIsWeb] is part of Flutter's foundation library. Since, package:media_kit works independently of Flutter, we need to define it here.

/// A constant that is true if the application was compiled to run on the web.
/// Learn more: https://api.flutter.dev/flutter/foundation/kIsWeb-constant.html
const bool kIsWeb = bool.fromEnvironment('dart.library.js_util');
