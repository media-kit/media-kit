/**
 * This file is a part of media_kit (https://github.com/media-kit/media-kit).
 * <p>
 * Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by MIT license that can be found in the LICENSE file.
 */
package com.alexmercerind.media_kit_video;

import android.app.Activity;
import android.app.PictureInPictureParams;
import android.os.Build;
import android.util.Log;
import android.util.Rational;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * Bridges {@link android.app.Activity#enterPictureInPictureMode} with
 * {@code com.alexmercerind/media_kit_video/pip} Flutter channels.
 * <p>
 * PiP is available from API 26 (Android 8.0); on older devices every method
 * either returns {@code false}/{@code null} or silently no-ops. The
 * {@link Activity#addOnPictureInPictureModeChangedListener} callback is only
 * available from API 31; on API 26-30 lifecycle events are limited to
 * {@code willStart}.
 */
final class MediaKitPictureInPictureManager {
    private static final String TAG = "MediaKitVideoPiP";
    private static final String METHOD_CHANNEL = "com.alexmercerind/media_kit_video/pip";
    private static final String EVENT_CHANNEL = "com.alexmercerind/media_kit_video/pip/events";

    private final MethodChannel methodChannel;
    private final EventChannel eventChannel;

    @Nullable
    private Activity activity;
    @Nullable
    private EventChannel.EventSink eventSink;

    private boolean autoEnter = false;
    private int preferredWidth = 16;
    private int preferredHeight = 9;

    MediaKitPictureInPictureManager(@NonNull BinaryMessenger messenger) {
        methodChannel = new MethodChannel(messenger, METHOD_CHANNEL);
        eventChannel = new EventChannel(messenger, EVENT_CHANNEL);

        methodChannel.setMethodCallHandler((call, result) -> handleMethodCall(call, result));
        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                eventSink = events;
            }

            @Override
            public void onCancel(Object arguments) {
                eventSink = null;
            }
        });
    }

    void attachActivity(@NonNull Activity activity) {
        this.activity = activity;
        registerModeChangedListener();
    }

    void detachActivity() {
        unregisterModeChangedListener();
        this.activity = null;
    }

    void dispose() {
        unregisterModeChangedListener();
        methodChannel.setMethodCallHandler(null);
        eventChannel.setStreamHandler(null);
        eventSink = null;
        activity = null;
    }

    private void handleMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "isSupported": {
                result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && activityHasPipFeature());
                break;
            }
            case "isActive": {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && activity != null) {
                    result.success(activity.isInPictureInPictureMode());
                } else {
                    result.success(false);
                }
                break;
            }
            case "start": {
                handleStart(call, result);
                break;
            }
            case "stop": {
                // Android has no programmatic way to leave PiP; the system
                // handles it when the user restores the app. We clear local
                // state so subsequent start() re-arms listeners.
                autoEnter = false;
                applyAutoEnter();
                result.success(null);
                break;
            }
            case "setAutoEnter": {
                final Boolean enabled = call.argument("enabled");
                autoEnter = Boolean.TRUE.equals(enabled);
                applyAutoEnter();
                result.success(null);
                break;
            }
            default: {
                result.notImplemented();
                break;
            }
        }
    }

    private void handleStart(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.success(null);
            return;
        }
        if (activity == null) {
            result.error("NO_ACTIVITY", "No host Activity available", null);
            return;
        }

        final Double width = call.argument("width");
        final Double height = call.argument("height");
        final Boolean autoEnterArg = call.argument("autoEnter");
        final Boolean startImmediately = call.argument("startImmediately");

        if (width != null && width > 0 && height != null && height > 0) {
            preferredWidth = clampAspect((int) Math.round(width));
            preferredHeight = clampAspect((int) Math.round(height));
        }
        autoEnter = Boolean.TRUE.equals(autoEnterArg);

        applyAutoEnter();

        if (Boolean.TRUE.equals(startImmediately)) {
            enterPictureInPictureNow();
        }
        result.success(null);
    }

    private void applyAutoEnter() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O || activity == null) {
            return;
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            try {
                final PictureInPictureParams params = new PictureInPictureParams.Builder()
                        .setAspectRatio(new Rational(preferredWidth, preferredHeight))
                        .setAutoEnterEnabled(autoEnter)
                        .build();
                activity.setPictureInPictureParams(params);
            } catch (Throwable t) {
                Log.w(TAG, "Failed to set PictureInPictureParams: " + t.getMessage());
            }
        }
    }

    private void enterPictureInPictureNow() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O || activity == null) {
            return;
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                final PictureInPictureParams params = new PictureInPictureParams.Builder()
                        .setAspectRatio(new Rational(preferredWidth, preferredHeight))
                        .build();
                dispatchEvent("willStart", null);
                final boolean ok = activity.enterPictureInPictureMode(params);
                if (!ok) {
                    dispatchEvent("failed", "enter_pip_rejected");
                }
            }
        } catch (Throwable t) {
            dispatchEvent("failed", t.getMessage() != null ? t.getMessage() : "enter_pip_threw");
        }
    }

    private boolean activityHasPipFeature() {
        if (activity == null) {
            return false;
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            return false;
        }
        return activity.getPackageManager().hasSystemFeature(
                android.content.pm.PackageManager.FEATURE_PICTURE_IN_PICTURE);
    }

    private void registerModeChangedListener() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S || activity == null) {
            return;
        }
        activity.addOnPictureInPictureModeChangedListener(info -> {
            if (info.isInPictureInPictureMode()) {
                dispatchEvent("didStart", null);
            } else {
                dispatchEvent("willStop", null);
                final Activity a = activity;
                if (a != null && a.isFinishing()) {
                    dispatchEvent("closed", null);
                } else {
                    dispatchEvent("didStop", null);
                }
            }
        });
    }

    private void unregisterModeChangedListener() {
        // The Activity cleans up listeners when it is destroyed; detaching
        // our reference is sufficient.
    }

    private void dispatchEvent(@NonNull String name, @Nullable String reason) {
        final EventChannel.EventSink sink = eventSink;
        if (sink == null) return;
        final Map<String, Object> payload = new HashMap<>();
        payload.put("event", name);
        if (reason != null) payload.put("reason", reason);
        sink.success(payload);
    }

    private static int clampAspect(int value) {
        if (value < 1) return 1;
        if (value > 1000) return 1000;
        return value;
    }
}
