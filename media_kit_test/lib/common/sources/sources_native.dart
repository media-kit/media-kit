import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path;

/// List of sample videos available for playback.
final sources = <String>[];

Future<void> prepareSources() async {
  final uris = [
    'https://user-images.githubusercontent.com/28951144/229373695-22f88f13-d18f-4288-9bf1-c3e078d83722.mp4',
    'https://user-images.githubusercontent.com/28951144/229373709-603a7a89-2105-4e1b-a5a5-a6c3567c9a59.mp4',
    'https://user-images.githubusercontent.com/28951144/229373716-76da0a4e-225a-44e4-9ee7-3e9006dbc3e3.mp4',
    'https://user-images.githubusercontent.com/28951144/229373718-86ce5e1d-d195-45d5-baa6-ef94041d0b90.mp4',
    'https://user-images.githubusercontent.com/28951144/229373720-14d69157-1a56-4a78-a2f4-d7a134d7c3e9.mp4',
  ];
  final directory = await path.getApplicationSupportDirectory();
  for (int i = 0; i < uris.length; i++) {
    final file = File(
      path.join(
        directory.path,
        'media_kit_test',
        'video$i.mp4',
      ),
    );
    if (!await file.exists()) {
      debugPrint('Downloading ${uris[i]}...');
      final response = await http.get(Uri.parse(uris[i]));
      await file.create(recursive: true);
      await file.writeAsBytes(response.bodyBytes);
    }
    debugPrint('Sample Video: ${file.path}');
    sources.add(file.path);
  }
}

String convertBytesToURL(Uint8List bytes) {
  // N/A
  throw UnimplementedError();
}
