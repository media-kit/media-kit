import 'package:flutter/foundation.dart';
import 'package:media_kit_video/media_kit_video.dart';

final configuration = ValueNotifier<VideoControllerConfiguration>(
  const VideoControllerConfiguration(enableHardwareAcceleration: true),
);
