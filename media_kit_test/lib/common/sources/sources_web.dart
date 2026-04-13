// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:js_interop';

import 'package:web/web.dart' as html;
import 'package:flutter/foundation.dart';

/// List of sample videos available for playback.
final sources = [
  'https://user-images.githubusercontent.com/28951144/229373695-22f88f13-d18f-4288-9bf1-c3e078d83722.mp4',
  'https://user-images.githubusercontent.com/28951144/229373709-603a7a89-2105-4e1b-a5a5-a6c3567c9a59.mp4',
  'https://user-images.githubusercontent.com/28951144/229373716-76da0a4e-225a-44e4-9ee7-3e9006dbc3e3.mp4',
  'https://user-images.githubusercontent.com/28951144/229373718-86ce5e1d-d195-45d5-baa6-ef94041d0b90.mp4',
  'https://user-images.githubusercontent.com/28951144/229373720-14d69157-1a56-4a78-a2f4-d7a134d7c3e9.mp4',
];

Future<void> prepareSources() async {
  // N/A
}

String convertBytesToURL(Uint8List bytes) {
  final blob = html.Blob(<JSUint8Array>[(bytes).toJS].toJS);
  final object = html.URL.createObjectURL(blob);
  return object;
}

final ValueNotifier<String> progress = ValueNotifier<String>(
  '',
);
