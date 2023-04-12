package com.alexmercerind.media_kit_libs_android_video;

import android.util.Log;
import androidx.annotation.NonNull;

import com.alexmercerind.mediakitandroidhelper.MediaKitAndroidHelper;

import io.flutter.embedding.engine.plugins.FlutterPlugin;

/** MediaKitLibsAndroidVideoPlugin */
public class MediaKitLibsAndroidVideoPlugin implements FlutterPlugin {
    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        Log.i("media_kit", "package:media_kit_libs_android_video attached.");
        try {
            // Save android.content.Context for access later within MediaKitAndroidHelpers e.g. loading bundled assets.
            MediaKitAndroidHelper.setApplicationContext(flutterPluginBinding.getApplicationContext());
            Log.i("media_kit", "Saved application context.");
        } catch (Throwable e) {
            e.printStackTrace();
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        Log.i("media_kit", "package:media_kit_libs_android_video detached.");
    }
}
