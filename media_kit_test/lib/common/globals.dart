import 'package:flutter/foundation.dart';
import 'package:media_kit_video/media_kit_video.dart';

final configuration = ValueNotifier<VideoControllerConfiguration>(
  const VideoControllerConfiguration(
    // PLEASE USE auto-safe IN PRODUCTION.
    hwdec: 'auto',
    enableHardwareAcceleration: true,
  ),
);
