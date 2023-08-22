/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, WanJiMi.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:html' as html;
import 'package:js/js.dart';

// --------------------------------------------------

/// {@template hls}
///
/// HLS
/// ---
///
/// Adds [HLS.js](https://github.com/video-dev/hls.js/) to the HTML document using [html.ScriptElement].
///
/// {@endtemplate}
abstract class HLS {
  static void ensureInitialized() {
    final script = html.ScriptElement()
      ..async = true
      ..charset = 'utf-8'
      ..type = 'text/javascript'
      ..src = 'assets/packages/media_kit/assets/web/hls1.4.10.js';
    html.querySelector('head')?.children.add(script);
  }
}

// --------------------------------------------------

@JS("Hls.isSupported")
external bool isHLSSupported();

@JS()
@staticInterop
class Hls {
  external factory Hls();
}

extension ExtensionHls on Hls {
  external void loadSource(String src);
  external void attachMedia(html.VideoElement video);
}

// --------------------------------------------------
