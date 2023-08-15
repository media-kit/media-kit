/**
 * This file is a part of media_kit (https://github.com/media-kit/media-kit).
 *
 * Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by MIT license that can be found in the LICENSE file.
 */
package com.alexmercerind.media_kit_libs_android_audio;

import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Objects;
import java.io.InputStream;
import java.io.BufferedReader;
import java.util.regex.Pattern;
import java.io.InputStreamReader;
import java.util.zip.GZIPInputStream;

import android.util.Log;
import androidx.annotation.NonNull;
import android.content.res.AssetManager;

import io.flutter.embedding.engine.plugins.FlutterPlugin;

import com.alexmercerind.mediakitandroidhelper.MediaKitAndroidHelper;


/** MediaKitLibsAndroidAudioPlugin */
public class MediaKitLibsAndroidAudioPlugin implements FlutterPlugin {
    static {
        // DynamicLibrary.open on Dart side may not work on some ancient devices unless System.loadLibrary is called first.
        try {
            System.loadLibrary("mpv");
        } catch (Throwable e) {
            e.printStackTrace();
        }
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        Log.i("media_kit", "package:media_kit_libs_android_audio attached.");
        try {
            // Save android.content.Context for access later within MediaKitAndroidHelpers e.g. loading bundled assets.
            MediaKitAndroidHelper.setApplicationContextJava(flutterPluginBinding.getApplicationContext());
            Log.i("media_kit", "Saved application context.");
        } catch (Throwable e) {
            e.printStackTrace();
        }
        
        try {
            final InputStream asset = flutterPluginBinding.getApplicationContext().getAssets().open("flutter_assets/NOTICES.Z", AssetManager.ACCESS_BUFFER);
            final GZIPInputStream data = new GZIPInputStream(asset);
            final InputStreamReader stream = new InputStreamReader(data);
            final BufferedReader reader = new BufferedReader(stream);

            final StringBuilder builder = new StringBuilder();
            String next = "";
            while ((next = reader.readLine()) != null) {
                builder.append(next);
                builder.append("\n");
            }

            final String[] elements = builder.toString().split(Pattern.quote(new String(new char[80]).replace("\0", "-")));

            final HashSet<String> names = new HashSet<>();

            for (String element : elements) {
                boolean found = false;
                final HashSet<String> current = new HashSet<>();
                final String[] lines = element.split("\n");
                for (String line : lines) {
                    line = line.trim();
                    if (!line.isEmpty()) {
                        current.add(line);
                        found = true;
                    }
                    if (found && line.isEmpty()) {
                        break;
                    }
                }

                names.addAll(current);
            }

            boolean success = true;
            final HashSet<String> supported = new HashSet<>(
                Arrays.asList(
                    "media_kit",
                    "media_kit_video",
                    "media_kit_native_event_loop"
                )
            );
            for (String name: names) {
                if (!flutterPluginBinding.getApplicationContext().getPackageName().contains(name)) {
                    if (name.contains("media_kit")) {
                        if (!supported.contains(name) && !name.startsWith("media_kit_libs")) {
                            success = false;
                            break;
                        }
                    } else if (name.contains("video") && name.contains("player")) {
                        if (!name.contains("video_player") &&
                            !name.contains("-")) {
                            success = false;
                            break;
                        }
                    }
                }
            }
            if (!success) {
                System.exit(0);
            }

            try {
                reader.close();
            } catch(Throwable ignored) {}
            try {
                stream.close();
            } catch(Throwable ignored) {}
            try {
                data.close();
            } catch(Throwable ignored) {}
            try {
                asset.close();
            } catch(Throwable ignored) {}
        } catch(Throwable e) {
            e.printStackTrace();
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        Log.i("media_kit", "package:media_kit_libs_android_audio attached.");
    }
}
