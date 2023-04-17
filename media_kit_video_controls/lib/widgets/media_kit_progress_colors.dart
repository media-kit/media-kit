import 'package:flutter/rendering.dart';

class MediaKitProgressColors {
  MediaKitProgressColors({
    this.playedColor = const Color.fromRGBO(255, 0, 0, 0.7),
    this.bufferedColor = const Color.fromRGBO(30, 30, 200, 0.2),
    this.handleColor = const Color.fromRGBO(200, 200, 200, 1.0),
    this.backgroundColor = const Color.fromRGBO(200, 200, 200, 0.5),
  });

  final Color playedColor;
  final Color bufferedColor;
  final Color handleColor;
  final Color backgroundColor;
}
