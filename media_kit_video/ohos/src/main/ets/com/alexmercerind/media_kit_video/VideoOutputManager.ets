/**
 * This file is a part of media_kit (https://github.com/media-kit/media-kit).
 *
 * Copyright © 2025 & onwards, Bao Han <erbws@foxmail.com>.
 * All rights reserved.
 * Use of this source code is governed by MIT license that can be found in the LICENSE file.
 */

import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { TextureRegistry } from '@ohos/flutter_ohos';
import { VideoOutput } from './VideoOutput';
import { TextureUpdateCallback } from './TextureUpdateCallback';
import { common } from '@kit.AbilityKit';

const TAG = "VideoOutputManager";

export class VideoOutputManager {
  private videoOutputs: Map<number, VideoOutput> = new Map();
  private textureRegistryReference: TextureRegistry;
  context: common.UIAbilityContext;

  constructor(textureRegistryReference: TextureRegistry, context: common.UIAbilityContext) {
    this.textureRegistryReference = textureRegistryReference;
    this.context = context;
  }

  async create(handle: number, textureUpdateCallback: TextureUpdateCallback): Promise<void> {
    Log.i(TAG, `com.alexmercerind.media_kit_video.VideoOutputManager.create: ${handle}`);

    if (!this.videoOutputs.has(handle)) {
      const textureId = this.textureRegistryReference.getTextureId();
      const videoOutput =
        new VideoOutput(this.textureRegistryReference, this.textureRegistryReference.registerTexture(textureId), textureUpdateCallback, this.context);
      this.videoOutputs.set(handle, videoOutput);
    }
  }

  async dispose(handle: number): Promise<void> {
    Log.i(TAG, `com.alexmercerind.media_kit_video.VideoOutputManager.dispose: ${handle}`);

    if (this.videoOutputs.has(handle)) {
      this.videoOutputs.get(handle)?.dispose();
      this.videoOutputs.delete(handle);
    }
  }

  async setSurfaceSize(handle: number, width: number, height: number): Promise<void> {
    Log.i(TAG, `com.alexmercerind.media_kit_video.VideoOutputManager.setSurfaceSize: ${handle} ${width} ${height}`);

    if (this.videoOutputs.has(handle)) {
      this.videoOutputs.get(handle)?.setSurfaceSize(width, height);
    }
  }
}