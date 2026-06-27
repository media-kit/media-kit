import {
  FlutterPlugin,
  FlutterPluginBinding,
} from "@ohos/flutter_ohos";

export default class MediaKitLibsOhosPlugin implements FlutterPlugin {
  getUniqueClassName(): string {
    return "MediaKitLibsOhosPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
  }
}