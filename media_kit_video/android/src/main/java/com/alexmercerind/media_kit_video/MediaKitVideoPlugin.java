/**
 * This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
 *
 * Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by MIT license that can be found in the LICENSE file.
 */
package com.alexmercerind.media_kit_video;

import androidx.annotation.NonNull;

import com.alexmercerind.mediakitandroidhelper.MediaKitAndroidHelper;

import java.util.HashMap;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import is.xyz.mpv.MPVLib;

public class MediaKitVideoPlugin implements FlutterPlugin, MethodCallHandler {
    private MethodChannel channel;
    private VideoOutputManager videoOutputManager;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "com.alexmercerind/media_kit_video");
        channel.setMethodCallHandler(this);
        try {
            if (videoOutputManager == null) {
                videoOutputManager = new VideoOutputManager(flutterPluginBinding.getTextureRegistry());
                // It seems that it is necessary to do some JNI initialization for using the libmpv native shared library from mpv for Android.
                // Since we are not using MPVLib JNI binding for any implementation, destroying it right away. Also, it only allows singleton usage.
                // We have our own abstraction & more capable implementation in package:media_kit.
                MPVLib.create(flutterPluginBinding.getApplicationContext());
                MPVLib.destroy();
                // Save android.content.Context for access later within MediaKitAndroidHelpers e.g. loading bundled assets.
                MediaKitAndroidHelper.setApplicationContext(flutterPluginBinding.getApplicationContext());
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals("VideoOutputManager.Create")) {
            final String handle = call.argument("handle");
            if (handle != null) {
                final VideoOutput videoOutput = videoOutputManager.create(Long.parseLong(handle));
                final HashMap<String, Long> data = new HashMap<>();
                data.put("id", videoOutput.id);
                data.put("wid", videoOutput.wid);
                result.success(data);
            } else {
                result.success(null);
            }

        } else if (call.method.equals("VideoOutputManager.Dispose")) {
            final String handle = call.argument("handle");
            if (handle != null) {
                videoOutputManager.dispose(Long.parseLong(handle));
            }
            result.success(null);
        } else {
            result.notImplemented();
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }
}
