// This file is a part of media_kit (https://github.com/media-kit/media-kit).
//
// Copyright © 2021 & onwards, WanJiMi.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';

import 'package:synchronized/synchronized.dart';
import 'package:web/web.dart' as web;

// --------------------------------------------------

/// {@template hls}
///
/// HLS
/// ---
///
/// Adds [HLS.js](https://github.com/video-dev/hls.js/) to the HTML document using [web.HTMLScriptElement].
///
/// {@endtemplate}
abstract class HLS {
  static Future<void> ensureInitialized({String? hls}) {
    return _lock.synchronized(() async {
      if (_initialized) {
        return;
      }
      final completer = Completer<void>();
      try {
        final script = web.HTMLScriptElement()
          ..async = true
          ..charset = 'utf-8'
          ..type = 'text/javascript'
          ..src = hls ?? kHLSAsset;

        script.onLoad.listen((_) {
          if (!completer.isCompleted) {
            completer.complete();
          }
        });
        script.onError.listen((_) {
          if (!completer.isCompleted) {
            completer.completeError(Exception('Failed to load HLS.js'));
          }
        });

        web.HTMLHeadElement? head = web.document.head;
        if (head == null) {
          head = web.HTMLHeadElement();
          web.document.append(head);
        }
        head.append(script);
      } on Object {
        if (!completer.isCompleted) {
          completer.completeError(Exception('Failed to load HLS.js'));
        }
      }
      try {
        await completer.future;
        _initialized = true;
      } on Object catch (exception, stacktrace) {
        print(exception);
        print(stacktrace);
      }
    });
  }

  static const String kHLSAsset =
      'assets/packages/media_kit/assets/web/hls1.7.4.js';
  static const String kHLSCDN =
      'https://cdnjs.cloudflare.com/ajax/libs/hls.js/1.7.4/hls.js';

  static final Lock _lock = Lock();
  static bool _initialized = false;
}

// --------------------------------------------------

@JS('Hls.isSupported')
external bool isHLSSupported();

@JS()
@staticInterop
abstract class XHRSetupCallback {}

extension on XHRSetupCallback {
  // ignore: unused_element
  external void call(web.XMLHttpRequest xhr, String url);
  // TODO(media-kit): Verify whether hls.js requires this call signature.
}

@JS()
@anonymous
@staticInterop
class HlsOptions {
  external factory HlsOptions({XHRSetupCallback? xhrSetup});
}

@JS()
@staticInterop
class Hls {
  external factory Hls(HlsOptions options);
}

extension ExtensionHls on Hls {
  external void loadSource(String src);

  external void attachMedia(web.HTMLVideoElement video);
}

// --------------------------------------------------
