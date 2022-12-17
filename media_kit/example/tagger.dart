import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:media_kit/media_kit.dart';

Future<void> main() async {
  final tagger = Tagger();
  final cover = File(
    join(
      File(Platform.resolvedExecutable).parent.path,
      'cover.JPG',
    ),
  );
  Map<String, String> metadata;
  metadata = await tagger.parse(
    Media(
        'https://alexmercerind.github.io/harmonoid-website/random/Lost Sky - Lost.m4a'),
    cover: cover,
    timeout: const Duration(days: 1),
  );
  println(metadata);
  print('cover saved at ${cover.uri}.');
  metadata = await tagger.parse(
    Media(
      'https://alexmercerind.github.io/harmonoid-website/random/Lost Sky - Where We Started.m4a',
    ),
    cover: null,
    timeout: const Duration(days: 1),
  );
  println(metadata);
}

void println(dynamic object) =>
    print(JsonEncoder.withIndent('    ').convert(object));
