
import 'media_kit_core_video_platform_interface.dart';

class MediaKitCoreVideo {
  Future<String?> getPlatformVersion() {
    return MediaKitCoreVideoPlatform.instance.getPlatformVersion();
  }
}
