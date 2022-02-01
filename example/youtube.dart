import 'package:libmpv/libmpv.dart';
import 'package:libmpv/src/plugins/youtube.dart';

Future<void> main() async {
  await MPV.initialize();
  final player = Player();
  player.open([Media(URI('https://www.youtube.com/watch?v=o1KWG3yRd2k'))]);
}
