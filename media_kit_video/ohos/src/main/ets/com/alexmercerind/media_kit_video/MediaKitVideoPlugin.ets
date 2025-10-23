/**
 * This file is a part of media_kit (https://github.com/media-kit/media-kit).
 *
 * Copyright © 2025 & onwards, Bao Han <erbws@foxmail.com>.
 * All rights reserved.
 * Use of this source code is governed by MIT license that can be found in the LICENSE file.
 */

import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import { TextureUpdateCallback } from './TextureUpdateCallback';
import { Rect, SizeData, Utils } from './Utils';
import { VideoOutputManager } from './VideoOutputManager';

export default class MediaKitVideoPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private videoOutputManager: VideoOutputManager | null = null;

  constructor() {
  }

  getUniqueClassName(): string {
    return "MediaKitVideoPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "com.alexmercerind/media_kit_video");
    this.channel.setMethodCallHandler(this);

    this.videoOutputManager = new VideoOutputManager(binding.getTextureRegistry());
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
    }
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case "VideoOutputManager.Create": {
        const handle = parseInt(call.argument("handle"));
        const textureUpdateCallback: TextureUpdateCallback = {
          onTextureUpdate: (id: number, wid: number, width: number, height: number): void => {
            const rect: Rect = {
              left: 0,
              top: 0,
              width: width,
              height: height,
            }
            const args: SizeData = {
              handle: handle,
              id: id,
              wid: wid,
              rect: rect,
            }
            this.channel?.invokeMethod("VideoOutput.Resize", JSON.stringify(args));
          }
        }
        this.videoOutputManager?.create(handle, textureUpdateCallback);
        result.success(null);
        break;
      }
      case "VideoOutputManager.SetSurfaceSize": {
        const handle = parseInt(call.argument("handle"));
        const width = parseInt(call.argument("width"));
        const height = parseInt(call.argument("height"));
        this.videoOutputManager?.setSurfaceSize(handle, width, height);
        result.success(null);
        break;
      }
      case "VideoOutputManager.Dispose": {
        const handle = parseInt(call.argument("handle"));
        this.videoOutputManager?.dispose(handle);
        result.success(null);
        break;
      }
      case "Utils.IsEmulator": {
        result.success(Utils.isEmulator());
        break;
      }
      default: {
        result.notImplemented();
        break;
      }
    }
  }
}