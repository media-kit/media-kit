import 'package:libmpv/libmpv.dart';

Future<void> main() async {
  await MPV.initialize();
  final player = Player();
  final sources = [
    Uri.https(
      'www.youtube.com',
      '/watch',
      {
        'v': 'EO4_qL7GCHQ',
        'list': 'RDAMVMEO4_qL7GCHQ',
      },
    ),
    Uri.https(
      'youtu.be',
      '/o1KWG3yRd2k/',
    ),
  ];
  print(sources);
  print(sources.map((e) => LibmpvPluginUtils.thumbnail(e)));
  print(sources.map((e) => LibmpvPluginUtils.thumbnail(e, small: true)));
  player.open(
    Playlist(
      sources
          .map((e) => Media(LibmpvPluginUtils.redirect(e).toString()))
          .toList(),
    ),
  );
}
