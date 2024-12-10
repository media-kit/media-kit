import 'dart:async';
import 'dart:js_interop';
import 'package:synchronized/synchronized.dart';
import 'package:web/web.dart' as web;

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
      final completer = Completer();
      try {
        final script = web.HTMLScriptElement()
          ..setAttribute('async', 'true')
          ..setAttribute('charset', 'utf-8')
          ..setAttribute('type', 'text/javascript')
          ..setAttribute('src', hls ?? kHLSAsset);

        onLoad(JSObject _) {
          if (!completer.isCompleted) {
            completer.complete();
          }
        }

        onError(JSObject _) {
          if (!completer.isCompleted) {
            completer.completeError(Exception('Failed to load HLS.js'));
          }
        }

        script.addEventListener('load', onLoad.toJS);
        script.addEventListener('error', onError.toJS);

        final head = web.document.head ??
            (() {
              final newHead = web.HTMLHeadElement();
              web.document.appendChild(newHead);
              return newHead;
            })();

        head.appendChild(script);
      } catch (_) {
        if (!completer.isCompleted) {
          completer.completeError(Exception('Failed to load HLS.js'));
        }
      }
      try {
        await completer.future;
        _initialized = true;
      } catch (exception, stacktrace) {
        print(exception.toString());
        print(stacktrace.toString());
      }
    });
  }

  static const String kHLSAsset =
      'assets/packages/media_kit/assets/web/hls1.4.10.js';

  static const String kHLSCDN =
      'https://cdnjs.cloudflare.com/ajax/libs/hls.js/1.4.10/hls.js';

  static final Lock _lock = Lock();
  static bool _initialized = false;
}

// JavaScript interop definitions
@JS('Hls.isSupported')
external bool isHLSSupported();

@JS()
@staticInterop
class HlsOptions {
  external factory HlsOptions([JSObject? options]);
}

@JS()
@staticInterop
class Hls {
  external factory Hls([HlsOptions? options]);
}

extension HlsMethods on Hls {
  external void loadSource(String src);
  external void attachMedia(web.HTMLVideoElement video);
}

// Helper function to create HLS options
JSObject createHlsOptions({JSFunction? xhrSetup}) {
  final options = JSObject();
  if (xhrSetup != null) {
    // options['xhrSetup'] = xhrSetup;
  }
  return options;
}
