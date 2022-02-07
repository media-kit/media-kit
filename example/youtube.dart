import 'package:libmpv/libmpv.dart';

Future<void> main() async {
  await MPV.initialize();
  final player = Player();
  player.open(
    [
      Media(Plugins.redirect(
              Uri.parse('https://www.youtube.com/watch?v=o1KWG3yRd2k'))
          .toString())
    ],
  );
}
