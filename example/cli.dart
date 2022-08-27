/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:io';
import 'dart:convert';
import 'package:libmpv/libmpv.dart';

Future<void> main(List<String> args) async {
  try {
    await MPV.initialize(
      dynamicLibrary: args.length <= 1 ? null : args.last,
    );
  } catch (e) {
    //
  }
  final verbose = args.contains('--verbose');
  final tagger = Tagger(verbose: verbose);
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
            duration: verbose,
            bitrate: verbose,
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
