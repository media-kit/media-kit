import 'dart:convert';
import 'dart:io';

import 'package:libmpv/libmpv.dart';

Future<void> main() async {
  await MPV.initialize();
  final tagger = Tagger();
  Map<String, String> metadata;
  metadata = await tagger.parse(
    'https://alexmercerind.github.io/music.m4a',
    cover: File('cover.jpg'),
  );
  println(metadata);
  metadata = await tagger.parse(
    'https://alexmercerind.github.io/audio.ogg',
    cover: null,
  );
  println(metadata);
}

void println(dynamic object) =>
    print(JsonEncoder.withIndent('    ').convert(object));
