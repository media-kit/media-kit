import 'dart:io';

import 'package:media_kit/media_kit.dart';
import 'package:safe_local_storage/safe_local_storage.dart';

Future<void> main(List<String> args) async {
  await MPV.ensureInitialized();
  final player = Player();
  final contents = await Directory(args.first).list_();
  contents.removeWhere((file) => !kSupportedFileTypes.contains(file.extension));
  final playlist = Playlist(
    contents.map((file) => Media(file.path)).toList(),
  );
  player.open(playlist);
  print(medias.keys.toList().join('\n'));
  await Future.delayed(const Duration(seconds: 5));
  player.shuffle = true;
}

const List<String> kSupportedFileTypes = [
  'OGG',
  'OGA',
  'OGX',
  'AAC',
  'M4A',
  'MP3',
  'WMA',
  'WAV',
  'FLAC',
  'OPUS',
  'AIFF',
  'AC3',
  'ADT',
  'ADTS',
  'AMR',
  'EC3',
  'M3U',
  'M4R',
  'WPL',
  'ZPL',
];
