import 'package:libmpv/libmpv.dart';

Future<void> main() async {
  await MPV.initialize();
  final player = Player(
    onCreate: (player) {
      print(player.version);
    },
  )
    ..streams.playlist.listen((event) {
      print(event);
    })
    ..streams.playlist.listen((event) {
      print(event);
    })
    ..streams.position.listen((event) {
      print(event);
    })
    ..streams.audioParams.listen((event) {
      print(event);
    });
  await player.open(
    Playlist(
      [
        Media(
            'https://p.scdn.co/mp3-preview/2312e9b4429d32218bf18778afb4dca0b25ac3f5?cid=a46f5c5745a14fbf826186da8da5ecc3'),
        Media(
            'https://p.scdn.co/mp3-preview/feb4812ccf46114e71085c2e1a5159b1b992e9c3?cid=a46f5c5745a14fbf826186da8da5ecc3'),
        Media(
            'https://p.scdn.co/mp3-preview/e2f3e698deaf0f09ed49436a7ab6abf6a989edfc?cid=a46f5c5745a14fbf826186da8da5ecc3'),
        Media(
            'https://p.scdn.co/mp3-preview/3f794acc211c14f5bbaef6ff44aa57b02b69bd9d?cid=a46f5c5745a14fbf826186da8da5ecc3'),
      ],
      index: 2,
    ),
    play: false,
  );
  await player.setPlaylistMode(PlaylistMode.loop);
  await player.play();
  await player.play();
  player.volume = 50.0;
  player.rate = 1.0;
  player.shuffle = false;
  Future.delayed(const Duration(seconds: 10), () {
    player.next();
  });
  Future.delayed(const Duration(seconds: 20), () {
    player.previous();
  });
  Future.delayed(const Duration(seconds: 30), () {
    player.open(
      Playlist(
        [
          Media(
              'https://p.scdn.co/mp3-preview/2312e9b4429d32218bf18778afb4dca0b25ac3f5?cid=a46f5c5745a14fbf826186da8da5ecc3'),
          Media(
              'https://p.scdn.co/mp3-preview/feb4812ccf46114e71085c2e1a5159b1b992e9c3?cid=a46f5c5745a14fbf826186da8da5ecc3'),
          Media(
              'https://p.scdn.co/mp3-preview/e2f3e698deaf0f09ed49436a7ab6abf6a989edfc?cid=a46f5c5745a14fbf826186da8da5ecc3'),
          Media(
              'https://p.scdn.co/mp3-preview/3f794acc211c14f5bbaef6ff44aa57b02b69bd9d?cid=a46f5c5745a14fbf826186da8da5ecc3'),
        ],
        index: 0,
      ),
      play: false,
    );
  });
  Future.delayed(const Duration(seconds: 40), () {
    player.play();
  });
  Future.delayed(const Duration(seconds: 60), () {
    player.dispose();
  });
}
