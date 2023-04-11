/**
 * This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
 *
 * Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by MIT license that can be found in the LICENSE file.
 */
package com.alexmercerind.mediakitandroidhelper;

import android.util.Log;
import android.content.Context;

import androidx.annotation.Keep;

@SuppressWarnings("unused")
@Keep()
public class MediaKitAndroidHelper {
    static {
        try {
            System.loadLibrary("mediakitandroidhelper");
        } catch (Exception e) {
            Log.e("media_kit", "WARNING: package:media_kit_libs_*** not found.");
        }
    }

    public static native long newGlobalObjectRef(Object obj);

    public static native void deleteGlobalObjectRef(long ref);

    public static native void setApplicationContext(Context context);

    public static native String copyAssetToExternalFilesDir(String assetName);
}
