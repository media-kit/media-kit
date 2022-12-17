import 'dart:io';
import 'package:media_kit/media_kit.dart';
import 'package:safe_local_storage/safe_local_storage.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print(
      'Please provide a directory path.\ne.g. dart directory.dart C:/Path/To/Directory/Where/Some/Music/Files/Are/',
    );
    return;
  }
  final tagger = Tagger();
  final contents = await Directory(args.first).list_();
  for (final entity in contents) {
    if ([
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
    ].contains(entity.extension)) {
      try {
        final data = await tagger.parse(Media(entity.path));
        print(data);
      } on FormatException catch (exception, stacktrace) {
        print(exception.toString());
        print(stacktrace.toString());
      }
    }
  }
}
