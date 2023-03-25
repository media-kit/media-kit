import 'package:media_kit/media_kit.dart';

Future<void> main() async {
  final player = Player();
  player.streams.playlist.listen((e) => print(e));
  player.streams.playing.listen((e) => print(e));
  player.streams.completed.listen((e) => print(e));
  player.streams.position.listen((e) => print(e));
  player.streams.duration.listen((e) => print(e));
  player.streams.volume.listen((e) => print(e));
  player.streams.rate.listen((e) => print(e));
  player.streams.pitch.listen((e) => print(e));
  player.streams.buffering.listen((e) => print(e));
  player.streams.audioParams.listen((e) => print(e));
  player.streams.audioBitrate.listen((e) => print(e));
  player.streams.audioDevice.listen((e) => print(e));
  player.streams.audioDevices.listen((e) => print(e));
  player.streams.track.listen((e) => print(e));
  player.streams.tracks.listen((e) => print(e));
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
  await player.setRate(1.0);
  await player.setVolume(50.0);
  await player.setShuffle(false);
  await player.setPlaylistMode(PlaylistMode.loop);
  await player.open(Playlist(items));
  await Future.delayed(const Duration(seconds: 10));
  await player.next();
  await Future.delayed(const Duration(seconds: 10));
  await player.previous();
  await Future.delayed(const Duration(seconds: 10));
  await player.open(Playlist(items, index: 2), play: false);
  await player.play();
  await Future.delayed(const Duration(seconds: 10));
  await player.open(Playlist(items), play: false);
  await Future.delayed(const Duration(seconds: 10));
  await player.play();
  await Future.delayed(const Duration(seconds: 10));
  await player.dispose();
}
