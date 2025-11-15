/**
 * This file is a part of media_kit (https://github.com/media-kit/media-kit).
 *
 * Copyright © 2025 & onwards, Bao Han <erbws@foxmail.com>.
 * All rights reserved.
 * Use of this source code is governed by MIT license that can be found in the LICENSE file.
 */

import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { SurfaceTextureEntry } from '@ohos/flutter_ohos';
import { TextureUpdateCallback } from './TextureUpdateCallback';
import { TextureRegistry } from '@ohos/flutter_ohos';
import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

const TAG = "VideoOutput";

export class VideoOutput {
  private id: number = 0;
  private wid: number = 0;
  private textureUpdateCallback: TextureUpdateCallback;
  private textureRegistry: TextureRegistry;
  private surfaceProducer: SurfaceTextureEntry;
  context: common.UIAbilityContext;

  constructor(textureRegistry: TextureRegistry, surfaceProducer: SurfaceTextureEntry, textureUpdateCallback: TextureUpdateCallback,
    context: common.UIAbilityContext) {
    this.surfaceProducer = surfaceProducer;
    this.textureUpdateCallback = textureUpdateCallback;
    this.context = context;
    this.textureRegistry = textureRegistry;
    this.setSurfaceSize(1, 1, true);
  }

  dispose(): void {
    try {
      this.surfaceProducer.release();
      this.onSurfaceDestroyed();
    } catch (e) {
      Log.e(TAG, `dispose: ${e}`);
    }
  }

  async setSurfaceSize(width: number, height: number, force: boolean = false): Promise<void> {
    try {
      let windowProperty = await window.getLastWindow(this.context);
      const w = windowProperty.getWindowProperties().windowRect.width;
      const h = windowProperty.getWindowProperties().windowRect.height;
      
      // 检查是否需要更新大小
      if (!force && w == width && h == height) {
        return;
      }
      
      // 先调整窗口大小
      windowProperty.resize(width, height);

      this.textureRegistry.setTextureBufferSize(this.id, width, height);
      
      // 确保surface创建并通知更新
      this.onSurfaceCreated();
    } catch (e) {
      Log.e(TAG, `setSurfaceSize error: ${e}`);
    }
  }

  private async onSurfaceCreated(): Promise<void> {
    Log.i(TAG, "onSurfaceCreated");
    try {
      this.id = this.surfaceProducer.getTextureId();
      this.wid = this.surfaceProducer.getSurfaceId();
      let windowProperty = await window.getLastWindow(this.context);
      const width = windowProperty.getWindowProperties().windowRect.width;
      const height = windowProperty.getWindowProperties().windowRect.height;
      this.textureUpdateCallback.onTextureUpdate(this.id, this.wid, width, height);
    } catch (e) {
      Log.e(TAG, `onSurfaceCreated error: ${e}`);
    }
  }

  private async onSurfaceDestroyed(): Promise<void> {
    Log.i(TAG, "onSurfaceDestroyed");
    this.textureUpdateCallback.onTextureUpdate(this.id, 0, 0, 0);
    this.surfaceProducer.release();
  }
}