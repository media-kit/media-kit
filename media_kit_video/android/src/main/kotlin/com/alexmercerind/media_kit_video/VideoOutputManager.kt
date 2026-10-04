/**
 * This file is a part of media_kit (https://github.com/media-kit/media-kit).
 *
 * Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by MIT license that can be found in the LICENSE file.
 */
package com.alexmercerind.media_kit_video

import android.util.Log
import io.flutter.view.TextureRegistry
import java.util.Locale

internal class VideoOutputManager(
    private val textureRegistryReference: TextureRegistry,
) {
    companion object {
        private const val TAG = "VideoOutputManager"
    }

    private val videoOutputs = HashMap<Long, VideoOutput>()
    private val lock = Any()

    fun create(handle: Long, textureUpdateCallback: TextureUpdateCallback) {
        synchronized(lock) {
            Log.i(
                TAG,
                String.format(
                    Locale.ENGLISH,
                    "com.alexmercerind.media_kit_video.VideoOutputManager.create: %d",
                    handle,
                ),
            )
            if (!videoOutputs.containsKey(handle)) {
                videoOutputs[handle] = VideoOutput(textureRegistryReference, textureUpdateCallback)
            }
        }
    }

    fun dispose(handle: Long) {
        synchronized(lock) {
            Log.i(
                TAG,
                String.format(
                    Locale.ENGLISH,
                    "com.alexmercerind.media_kit_video.VideoOutputManager.dispose: %d",
                    handle,
                ),
            )
            if (videoOutputs.containsKey(handle)) {
                videoOutputs[handle]!!.dispose()
                videoOutputs.remove(handle)
            }
        }
    }

    fun setSurfaceSize(handle: Long, width: Int, height: Int) {
        synchronized(lock) {
            Log.i(
                TAG,
                String.format(
                    Locale.ENGLISH,
                    "com.alexmercerind.media_kit_video.VideoOutputManager.setSurfaceSize: %d %d %d",
                    handle,
                    width,
                    height,
                ),
            )
            if (videoOutputs.containsKey(handle)) {
                videoOutputs[handle]!!.setSurfaceSize(width, height)
            }
        }
    }
}
