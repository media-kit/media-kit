import 'package:media_kit/media_kit.dart';

Future<void> main() async {
  final player = Player();
  player.streams.playlist.listen((event) {
    print(event);
  });
  player.streams.playlist.listen((event) {
    print(event);
  });
  player.streams.position.listen((event) {
    print(event);
  });
  player.streams.duration.listen((event) {
    print(event);
  });
  player.streams.audioBitrate.listen((event) {
    if (event != null) {
      print('${event ~/ 1000} KB/s');
    }
  });
  // Sample audio segments.
  // Shelter - Porter Robinson
  // Look At The Sky - Porter Robinson
  // Firefly pt. II (feat. STARLYTE) - Jim Yosef
  // Stay - Zedd
  final items = [
    Media(
      'https://p.scdn.co/mp3-preview/2312e9b4429d32218bf18778afb4dca0b25ac3f5?cid=a46f5c5745a14fbf826186da8da5ecc3',
    ),
    Media(
      'https://p.scdn.co/mp3-preview/feb4812ccf46114e71085c2e1a5159b1b992e9c3?cid=a46f5c5745a14fbf826186da8da5ecc3',
    ),
    Media(
      'https://p.scdn.co/mp3-preview/e2f3e698deaf0f09ed49436a7ab6abf6a989edfc?cid=a46f5c5745a14fbf826186da8da5ecc3',
    ),
    Media(
      'https://p.scdn.co/mp3-preview/3f794acc211c14f5bbaef6ff44aa57b02b69bd9d?cid=a46f5c5745a14fbf826186da8da5ecc3',
    ),
  ];
  await player.open(
    Playlist(items, index: 2),
    play: false,
  );
  await player.setPlaylistMode(PlaylistMode.loop);
  await player.play();
  player.volume = 50.0;
  player.rate = 1.0;
  player.shuffle = false;
  await Future.delayed(const Duration(seconds: 10));
  player.next();
  await Future.delayed(const Duration(seconds: 10));
  player.previous();
  await Future.delayed(const Duration(seconds: 10));
  await player.open(
    Playlist(items, index: 0),
    play: false,
  );
  await Future.delayed(const Duration(seconds: 10));
  await player.play();
  await Future.delayed(const Duration(seconds: 10));
  await player.dispose();
}
