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

const TAG = "VideoOutput";

export class VideoOutput {
  private id: number = 0;
  private wid: number = 0;
  private textureUpdateCallback: TextureUpdateCallback;
  private surfaceProducer: SurfaceTextureEntry;
  private width: number = 0;
  private height: number = 0;

  constructor(surfaceProducer: SurfaceTextureEntry, textureUpdateCallback: TextureUpdateCallback) {
    this.surfaceProducer = surfaceProducer;
    this.textureUpdateCallback = textureUpdateCallback;
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
      if (!force && this.width == width && this.height == height) {
        return;
      }

      this.width = width;
      this.height = height;

      this.onSurfaceCreated();
    } catch (e) {
      Log.e(TAG, `setSurfaceSize: ${e}`);
    }
  }

  private async onSurfaceCreated(): Promise<void> {
    Log.i(TAG, "onSurfaceCreated");
    this.id = this.surfaceProducer.getTextureId();
    this.wid = this.surfaceProducer.getNativeWindowId();
    this.textureUpdateCallback.onTextureUpdate(this.id, this.wid, this.width, this.height);
  }

  private async onSurfaceDestroyed(): Promise<void> {
    Log.i(TAG, "onSurfaceDestroyed");
    this.textureUpdateCallback.onTextureUpdate(this.id, 0, this.width, this.height);
  }
}