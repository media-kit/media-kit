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
import android.content.ComponentCallbacks;
import android.content.res.Configuration;
import android.os.Build;
import android.util.Log;
import android.util.Rational;

import androidx.activity.ComponentActivity;
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
 * either returns {@code false}/{@code null} or silently no-ops. Mode-changed
 * events are routed through {@link ComponentActivity}'s listener API, which
 * Flutter's host activity provides on every supported Flutter version.
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

    // Last PiP mode dispatched to Dart, used to de-duplicate transitions that
    // can arrive from more than one source (ComponentActivity listener and the
    // ComponentCallbacks config-change fallback below).
    private boolean lastPipMode = false;

    // Detects PiP enter/exit on a plain Activity. FlutterActivity extends
    // android.app.Activity (NOT androidx ComponentActivity), so the
    // ComponentActivity listener never fires here. Entering/leaving PiP is a
    // configuration change, which a registered ComponentCallbacks receives even
    // on a plain Activity; we then read isInPictureInPictureMode().
    private final ComponentCallbacks pipConfigCallbacks = new ComponentCallbacks() {
        @Override
        public void onConfigurationChanged(@NonNull Configuration newConfig) {
            final Activity a = activity;
            if (a == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
                return;
            }
            handlePipModeChanged(a.isInPictureInPictureMode());
        }

        @Override
        public void onLowMemory() {
        }
    };

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

    /**
     * Invoked by the plugin when the user is about to leave the Activity
     * (e.g. pressed Home).
     * <p>
     * {@link Activity#setPictureInPictureParams} with auto-enter only exists
     * from API 31 (S). On API 26–30 there is no system auto-enter, so the
     * {@code autoEnter} contract is fulfilled here by entering PiP manually on
     * the user-leave signal. On API 31+ this is intentionally a no-op because
     * the system already enters automatically via {@link #applyAutoEnter()},
     * and on pre-26 PiP does not exist — leaving the original behavior on both
     * ends unchanged.
     */
    void onUserLeaveHint() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return;
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // API 31+ relies on setAutoEnterEnabled(); avoid entering twice.
            return;
        }
        if (!autoEnter || activity == null) {
            return;
        }
        enterPictureInPictureNow();
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
            // Store the raw video dimensions. The aspect ratio is derived
            // (and clamped to Android's accepted range) at build time in
            // buildAspectRatio(); clamping each dimension here would distort
            // the shape (e.g. 1920x1080 would collapse to a square).
            preferredWidth = (int) Math.round(width);
            preferredHeight = (int) Math.round(height);
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
                        .setAspectRatio(buildAspectRatio())
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
                        .setAspectRatio(buildAspectRatio())
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
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O || activity == null) {
            return;
        }
        lastPipMode = false;
        // Primary path: works on every Activity (incl. plain FlutterActivity).
        activity.registerComponentCallbacks(pipConfigCallbacks);
        // Forward-compat path: if the host ever becomes a ComponentActivity its
        // listener also routes through handlePipModeChanged(), which de-dupes.
        if (activity instanceof ComponentActivity) {
            ((ComponentActivity) activity).addOnPictureInPictureModeChangedListener(
                    info -> handlePipModeChanged(info.isInPictureInPictureMode()));
        }
    }

    /**
     * Routes a PiP mode transition to Dart exactly once, regardless of which
     * source observed it. Emits {@code didStart} on entry and
     * {@code willStop}+{@code didStop}/{@code closed} on exit.
     */
    private void handlePipModeChanged(boolean inPip) {
        if (inPip == lastPipMode) {
            return;
        }
        lastPipMode = inPip;
        if (inPip) {
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
    }

    private void unregisterModeChangedListener() {
        final Activity a = activity;
        if (a != null) {
            try {
                a.unregisterComponentCallbacks(pipConfigCallbacks);
            } catch (Throwable ignored) {
                // Not registered (e.g. pre-O attach) — safe to ignore.
            }
        }
        lastPipMode = false;
    }

    private void dispatchEvent(@NonNull String name, @Nullable String reason) {
        final EventChannel.EventSink sink = eventSink;
        if (sink == null) return;
        final Map<String, Object> payload = new HashMap<>();
        payload.put("event", name);
        if (reason != null) payload.put("reason", reason);
        sink.success(payload);
    }

    /**
     * Builds the Picture-in-Picture aspect ratio from the preferred video
     * dimensions, preserving the video's shape.
     * <p>
     * {@link Rational} compares by value, so the magnitude of the
     * numerator/denominator is irrelevant — only the ratio matters; the raw
     * pixel dimensions are passed straight through. Android rejects ratios
     * outside roughly {@code 1:2.39}–{@code 2.39:1} with an
     * {@link IllegalArgumentException}, so only the *ratio* is clamped (by
     * adjusting a single dimension), never both dimensions independently.
     */
    private Rational buildAspectRatio() {
        int w = preferredWidth > 0 ? preferredWidth : 16;
        int h = preferredHeight > 0 ? preferredHeight : 9;
        final double maxRatio = 2.39;            // Android's upper bound
        final double minRatio = 1.0 / maxRatio;  // ... and lower bound
        final double ratio = (double) w / (double) h;
        if (ratio > maxRatio) {
            // Too wide: grow height so the ratio drops to <= maxRatio.
            h = (int) Math.ceil(w / maxRatio);
        } else if (ratio < minRatio) {
            // Too tall: grow width so the ratio rises to >= minRatio.
            w = (int) Math.ceil(h * minRatio);
        }
        if (w < 1) w = 1;
        if (h < 1) h = 1;
        return new Rational(w, h);
    }
}
