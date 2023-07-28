/**
 * This file is a part of media_kit (https://github.com/media-kit/media-kit).
 *
 * Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by MIT license that can be found in the LICENSE file.
 */
package com.alexmercerind.media_kit_video;

import androidx.annotation.NonNull;

import java.util.HashMap;
import java.util.Objects;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;

/**
 * MediaKitVideoPlugin
 */
public class MediaKitVideoPlugin implements FlutterPlugin, MethodCallHandler {
    private MethodChannel channel;
    private VideoOutputManager videoOutputManager;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "com.alexmercerind/media_kit_video");
        videoOutputManager = new VideoOutputManager(flutterPluginBinding.getTextureRegistry());
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "VideoOutputManager.Create": {
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
                break;
            }
            case "VideoOutputManager.SetSurfaceTextureSize": {
                final String handle = call.argument("handle");
                final String width = call.argument("width");
                final String height = call.argument("height");
                if (handle != null) {
                    videoOutputManager.setSurfaceTextureSize(
                            Long.parseLong(handle),
                            Integer.parseInt(Objects.requireNonNull(width)),
                            Integer.parseInt(Objects.requireNonNull(height))
                    );
                }
                result.success(null);
                break;
            }
            case "VideoOutputManager.Dispose": {
                final String handle = call.argument("handle");
                if (handle != null) {
                    videoOutputManager.dispose(Long.parseLong(handle));
                }
                result.success(null);
                break;
            }
            case "Utils.IsEmulator": {
                result.success(Utils.isEmulator());
                break;
            }
            default: {
                result.notImplemented();
                break;
            }
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }
}
