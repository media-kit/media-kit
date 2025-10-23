import {
  FlutterPlugin,
  FlutterPluginBinding,
} from "@ohos/flutter_ohos";

export class MediaKitLibsOhOSVideoPlugin implements FlutterPlugin {
  getUniqueClassName(): string {
    return "MediaKitLibsOhOSVideoPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
  }
}