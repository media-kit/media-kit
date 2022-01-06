import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:libmpv/libmpv.dart';

Future<void> main() async {
  var player = Player('/usr/lib/x86_64-linux-gnu/libmpv.so');
  while (true) {
    var choice = await input();
    var arg = (choice.split(' ')..removeAt(0)).join(' ');
    if (choice.contains('open')) {
      player.open(
        [Media(arg)],
        play: true,
      );
    }
    if (choice.contains('play')) {
      player.play();
    }
    if (choice.contains('pause')) {
      player.pause();
    }
    if (choice.contains('seek')) {
      player.seek(Duration(seconds: int.parse(arg)));
    }
    if (choice.contains('back')) {
      player.back();
    }
    if (choice.contains('next')) {
      player.next();
    }
    if (choice.contains('jump')) {
      player.jump(int.parse(arg));
    }
  }
}

Stream<String> stream = stdin
    .transform(utf8.decoder)
    .transform(const LineSplitter())
    .asBroadcastStream();

Future<String> input() async {
  var completer = Completer<String>();
  var listener = stream.listen((line) {
    if (!completer.isCompleted) {
      completer.complete(line);
    }
  });
  return completer.future.then((line) {
    listener.cancel();
    return line.trim();
  });
}
