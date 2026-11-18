/**
 * This file is a part of media_kit (https://github.com/media-kit/media-kit).
 *
 * Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by MIT license that can be found in the LICENSE file.
 */
package com.alexmercerind.media_kit_libs_android_video

import android.util.Log
import com.alexmercerind.mediakitandroidhelper.MediaKitAndroidHelper
import io.flutter.embedding.engine.plugins.FlutterPlugin

class MediaKitLibsAndroidVideoPlugin : FlutterPlugin {
    companion object {
        init {
            // DynamicLibrary.open on the Dart side may not work on some ancient devices
            // unless System.loadLibrary is called first.
            try {
                System.loadLibrary("mpv")
            } catch (error: Throwable) {
                error.printStackTrace()
            }
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Log.i("media_kit", "package:media_kit_libs_android_video attached.")
        try {
            // Save android.content.Context for access later within MediaKitAndroidHelper.
            MediaKitAndroidHelper.setApplicationContextJava(flutterPluginBinding.applicationContext)
            Log.i("media_kit", "Saved application context.")
        } catch (error: Throwable) {
            error.printStackTrace()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.i("media_kit", "package:media_kit_libs_android_video detached.")
    }
}
