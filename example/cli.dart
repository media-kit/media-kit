/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';
import 'package:media_kit/media_kit.dart';

Future<void> main(List<String> args) async {
  String? dynamicLibrary;
  for (final arg in args) {
    if (![
      '--verbose',
      '--version',
    ].contains(arg)) {
      dynamicLibrary = arg;
    }
  }
  await MPV.initialize(
    dynamicLibrary: dynamicLibrary,
  );
  if (args.contains('--version')) {
    print('Tagger');
    return;
  }
  final verbose = args.contains('--verbose');
  final tagger = Tagger(
    create: false,
    verbose: verbose,
  );
  await tagger.open();
  while (true) {
    final opt = stdin.readLineSync()?.trim();
    assert(['parse', 'dispose'].contains(opt));
    if (opt == 'parse') {
      final media = stdin.readLineSync()?.trim();
      final cover = stdin.readLineSync()?.trim();
      final coverDirectory = stdin.readLineSync()?.trim();
      final timeout = int.tryParse(stdin.readLineSync()?.trim() ?? '');
      if (media != null && timeout != null) {
        try {
          final metadata = await tagger.parse(
            Media(media),
            cover: [null, ''].contains(cover) ? null : File(cover!),
            coverDirectory: [null, ''].contains(coverDirectory)
                ? null
                : Directory(coverDirectory!),
            timeout: Duration(milliseconds: timeout),
          );
          print(const JsonEncoder.withIndent('    ').convert(metadata));
        } catch (exception, stacktrace) {
          print(exception);
          print(stacktrace);
        }
      }
    } else if (opt == 'dispose') {
      await tagger.dispose();
      exit(0);
    }
  }
}
