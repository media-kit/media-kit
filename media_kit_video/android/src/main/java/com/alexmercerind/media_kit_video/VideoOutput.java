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
import java.lang.reflect.Method;

import io.flutter.view.TextureRegistry;

public class VideoOutput {
    private final Surface surface;
    private final TextureRegistry.SurfaceTextureEntry surfaceTextureEntry;

    public long id;
    public long wid;

    private final Method newGlobalObjectRef;
    private final Method deleteGlobalObjectRef;

    VideoOutput(TextureRegistry textureRegistryReference) {
        try {
            // com.alexmercerind.mediakitandroidhelper.MediaKitAndroidHelper is part of package:media_kit_libs_android_video & package:media_kit_libs_android_audio packages.
            // Use reflection to invoke methods of com.alexmercerind.mediakitandroidhelper.MediaKitAndroidHelper.
            Class<?> mediaKitAndroidHelperClass = Class.forName("com.alexmercerind.mediakitandroidhelper.MediaKitAndroidHelper");
            newGlobalObjectRef = mediaKitAndroidHelperClass.getDeclaredMethod("newGlobalObjectRef", Object.class);
            deleteGlobalObjectRef = mediaKitAndroidHelperClass.getDeclaredMethod("deleteGlobalObjectRef", long.class);
            newGlobalObjectRef.setAccessible(true);
            deleteGlobalObjectRef.setAccessible(true);
        } catch (Exception e) {
            Log.i("media_kit", "package:media_kit_libs_android_video missing. Make sure you have added it to pubspec.yaml.");
            throw new RuntimeException("Failed to initialize com.alexmercerind.media_kit_video.VideoOutput.");
        }

        surfaceTextureEntry = textureRegistryReference.createSurfaceTexture();
        surface = new Surface(surfaceTextureEntry.surfaceTexture());

        try {
            id = surfaceTextureEntry.id();
            wid = (long) newGlobalObjectRef.invoke(null, surface);
            Log.i("media_kit", String.format(Locale.ENGLISH, "com.alexmercerind.media_kit_video.VideoOutput: id = %d", id));
            Log.i("media_kit", String.format(Locale.ENGLISH, "com.alexmercerind.media_kit_video.VideoOutput: wid = %d", wid));
        } catch (Exception e) {
            e.printStackTrace();
        }
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
            deleteGlobalObjectRef.invoke(null, wid);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
