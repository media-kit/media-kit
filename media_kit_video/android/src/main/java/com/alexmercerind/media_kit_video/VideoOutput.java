/**
 * This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
 *
 * Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by MIT license that can be found in the LICENSE file.
 */
package com.alexmercerind.media_kit_video;

import android.util.Log;
import android.view.Surface;

import java.util.Locale;

import io.flutter.view.TextureRegistry;

import com.alexmercerind.mediakitandroidhelper.MediaKitAndroidHelper;

public class VideoOutput {
    private final Surface surface;
    private final TextureRegistry.SurfaceTextureEntry surfaceTextureEntry;

    public final long id;
    public final long wid;

    VideoOutput(TextureRegistry textureRegistryReference) {
        surfaceTextureEntry = textureRegistryReference.createSurfaceTexture();
        surface = new Surface(surfaceTextureEntry.surfaceTexture());
        id = surfaceTextureEntry.id();
        wid = MediaKitAndroidHelper.newGlobalObjectRef(surface);
        Log.i("media_kit", String.format(Locale.ENGLISH, "com.alexmercerind.media_kit_video.VideoOutput: id = %d", id));
        Log.i("media_kit", String.format(Locale.ENGLISH, "com.alexmercerind.media_kit_video.VideoOutput: wid = %d", wid));
    }

    public void dispose() {
        try {
            surfaceTextureEntry.release();
        } catch (Exception e) {
            e.printStackTrace();
        }
        try {
            surface.release();
        } catch (Exception e) {
            e.printStackTrace();
        }
        try {
            MediaKitAndroidHelper.deleteGlobalObjectRef(wid);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
