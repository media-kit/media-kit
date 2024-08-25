/**
 * This file is a part of media_kit (https://github.com/media-kit/media-kit).
 * <p>
 * Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by MIT license that can be found in the LICENSE file.
 */
package com.alexmercerind.media_kit_video;

import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.PorterDuff;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.Choreographer;
import android.view.Surface;
import android.view.View;
import android.widget.FrameLayout;

import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Locale;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.TextureRegistry;

public class VideoOutput {
    public long id = 0;
    public long wid = 0;

    private Surface surface;
    private final TextureRegistry.SurfaceProducer surfaceProducer;

    private boolean flutterJNIAPIAvailable;
    private final Method newGlobalObjectRef;
    private final Method deleteGlobalObjectRef;
    private boolean waitUntilFirstFrameRenderedNotify;

    private long handle;
    private MethodChannel channelReference;
    private TextureRegistry textureRegistryReference;

    private final Object lock = new Object();
    private Choreographer.FrameCallback frameCallback;

    VideoOutput(long handle, MethodChannel channelReference, TextureRegistry textureRegistryReference) {
        this.handle = handle;
        this.channelReference = channelReference;
        this.textureRegistryReference = textureRegistryReference;
        try {
            flutterJNIAPIAvailable = false;
            waitUntilFirstFrameRenderedNotify = false;
            // com.alexmercerind.mediakitandroidhelper.MediaKitAndroidHelper is part of package:media_kit_libs_android_video & package:media_kit_libs_android_audio packages.
            // Use reflection to invoke methods of com.alexmercerind.mediakitandroidhelper.MediaKitAndroidHelper.

            Class<?> mediaKitAndroidHelperClass = Class.forName("com.alexmercerind.mediakitandroidhelper.MediaKitAndroidHelper");
            newGlobalObjectRef = mediaKitAndroidHelperClass.getDeclaredMethod("newGlobalObjectRef", Object.class);
            deleteGlobalObjectRef = mediaKitAndroidHelperClass.getDeclaredMethod("deleteGlobalObjectRef", long.class);
            newGlobalObjectRef.setAccessible(true);
            deleteGlobalObjectRef.setAccessible(true);
        } catch (Throwable e) {
            Log.i("media_kit", "package:media_kit_libs_android_video missing. Make sure you have added it to pubspec.yaml.");
            throw new RuntimeException("Failed to initialize com.alexmercerind.media_kit_video.VideoOutput.", e);
        }

        // Initialize the SurfaceProducer using the new API
        surfaceProducer = textureRegistryReference.createSurfaceProducer();
        // If we call setOnFrameAvailableListener after creating surfaceProducer, the texture won't be displayed inside Flutter UI, because callback set by us will override the Flutter engine's own registered callback:
        // https://github.com/flutter/engine/blob/f47e864f2dcb9c299a3a3ed22300a1dcacbdf1fe/shell/platform/android/io/flutter/view/FlutterView.java#L942-L958
        surfaceProducer.setCallback(new TextureRegistry.SurfaceProducer.Callback() {
            @Override
            public void onSurfaceCreated() {
                synchronized (lock) {
                    Log.i("media_kit", "Surface created");

                    try {
                        final Surface newSurface = surfaceProducer.getSurface();
                        if (newSurface.equals(surface)) {
                            return;
                        }

                        cleanupSurface();

                        surface = newSurface;
                        wid = (long) newGlobalObjectRef.invoke(null, surface);
                        Log.i("media_kit", String.format(Locale.ENGLISH, "com.alexmercerind.mediakitandroidhelper.MediaKitAndroidHelper.newGlobalObjectRef: %d", wid));

                        final HashMap<String, Object> data = new HashMap<>();
                        data.put("id", id);
                        data.put("wid", wid);
                        data.put("handle", handle);
                        channelReference.invokeMethod("VideoOutput.SurfaceUpdatedNotify", data);

                    } catch (Throwable e) {
                        e.printStackTrace();
                    }

                }
            }

            @Override
            public void onSurfaceDestroyed() {
                synchronized (lock) {
                    Log.i("media_kit", "Surface destroyed");
                    final Handler mainHandler = new Handler(Looper.getMainLooper());

                    if (surface != null) {
                        final Surface surfaceCopy = surface;

                        clearSurface();
                        mainHandler.postDelayed(() -> {
                            surfaceCopy.release();
                        }, 5000);
                        surface = null;
                    }

                    if (wid != 0) {
                        final long widCopy = wid;

                        mainHandler.postDelayed(() -> {
                            try {
                                // Invoke DeleteGlobalRef after a voluntary delay to eliminate possibility of libmpv referencing it sometime in the near future.
                                Log.i("media_kit", String.format(Locale.ENGLISH, "com.alexmercerind.mediakitandroidhelper.MediaKitAndroidHelper.deleteGlobalObjectRef: %d", widCopy));
                                deleteGlobalObjectRef.invoke(null, widCopy);
                            } catch (Throwable e) {
                                e.printStackTrace();
                            }
                        }, 5000);

                        wid = 0;
                    }

                    final HashMap<String, Object> data = new HashMap<>();
                    data.put("id", id);
                    data.put("wid", wid);
                    data.put("handle", handle);
                    channelReference.invokeMethod("VideoOutput.SurfaceUpdatedNotify", data);
                }
            }
        });

        try {
            if (!flutterJNIAPIAvailable) {
                flutterJNIAPIAvailable = getFlutterJNIReference() != null;
            }
        } catch (Throwable e) {
            e.printStackTrace();
        }

        // Initialize Choreographer FrameCallback for frame updates

        frameCallback = new Choreographer.FrameCallback() {
            @Override
            public void doFrame(long frameTimeNanos) {
                synchronized (lock) {
                    try {
                        if (!waitUntilFirstFrameRenderedNotify) {
                            waitUntilFirstFrameRenderedNotify = true;
                            final HashMap<String, Object> data = new HashMap<>();
                            data.put("handle", handle);
                            channelReference.invokeMethod("VideoOutput.WaitUntilFirstFrameRenderedNotify", data);
                            Log.i("media_kit", String.format(Locale.ENGLISH, "VideoOutput.WaitUntilFirstFrameRenderedNotify = %d", handle));
                        }
                        FlutterJNI flutterJNI = null;
                        while (flutterJNI == null) {
                            flutterJNI = getFlutterJNIReference();
                            flutterJNI.markTextureFrameAvailable(id);
                        }
                    } catch (Throwable e) {
                        e.printStackTrace();
                    }
                }
                Choreographer.getInstance().postFrameCallback(this);
            }
        };

        Log.i("media_kit", String.format(Locale.ENGLISH, "flutterJNIAPIAvailable = %b", flutterJNIAPIAvailable));
        if (flutterJNIAPIAvailable) {
            Choreographer.getInstance().postFrameCallback(frameCallback);
        } else {
            if (!waitUntilFirstFrameRenderedNotify) {
                waitUntilFirstFrameRenderedNotify = true;
                final HashMap<String, Object> data = new HashMap<>();
                data.put("id", id);
                data.put("wid", wid);
                data.put("handle", handle);
                channelReference.invokeMethod("VideoOutput.WaitUntilFirstFrameRenderedNotify", data);
            }
        }

        try {
            id = surfaceProducer.id();
            Log.i("media_kit", String.format(Locale.ENGLISH, "com.alexmercerind.media_kit_video.VideoOutput: id = %d", id));
        } catch (Throwable e) {
            e.printStackTrace();
        }
    }

    public void dispose() {
        synchronized (lock) {
            try {
                Log.i("media_kit", "release surface producer");
                surfaceProducer.release();
            } catch (Throwable e) {
                e.printStackTrace();
            }
            try {
                if (surface != null) {
                    Log.i("media_kit", "release surface");
                    surface.release();
                }
            } catch (Throwable e) {
                e.printStackTrace();
            }

            if (wid != 0) {
                try {
                    final Handler mainHandler = new Handler(Looper.getMainLooper());

                    mainHandler.postDelayed(() -> {
                        try {
                            // Invoke DeleteGlobalRef after a voluntary delay to eliminate possibility of libmpv referencing it sometime in the near future.
                            deleteGlobalObjectRef.invoke(null, wid);
                            Log.i("media_kit", String.format(Locale.ENGLISH, "com.alexmercerind.mediakitandroidhelper.MediaKitAndroidHelper.deleteGlobalObjectRef: %d", wid));
                        } catch (Throwable e) {
                            e.printStackTrace();
                        }
                    }, 5000);
                } catch (Throwable e) {
                    e.printStackTrace();
                }
            }
            // Remove Choreographer callback

            Choreographer.getInstance().removeFrameCallback(frameCallback);
        }
    }

    private void cleanupSurface() {
        try {
            final Handler mainHandler = new Handler(Looper.getMainLooper());

            if (surface != null) {
                final Surface surfaceCopy = this.surface;

                clearSurface();
                mainHandler.postDelayed(() -> {
                    surfaceCopy.release();
                }, 5000);

                surface = null;
            }

            if (wid != 0) {
                final long widCopy = wid;

                mainHandler.postDelayed(() -> {
                    try {
                        // Invoke DeleteGlobalRef after a voluntary delay to eliminate possibility of libmpv referencing it sometime in the near future.
                        Log.i("media_kit", String.format(Locale.ENGLISH, "com.alexmercerind.mediakitandroidhelper.MediaKitAndroidHelper.deleteGlobalObjectRef: %d", widCopy));
                        deleteGlobalObjectRef.invoke(null, widCopy);
                    } catch (Throwable e) {
                        e.printStackTrace();
                    }
                }, 5000);
                wid = 0;
            }
        } catch (Throwable e) {
            e.printStackTrace();
        }
    }
    public long createSurface(int width, int height) {
        synchronized (lock) {
            // Delete previous android.view.Surface & object reference.
            Log.i("media_kit", String.format(Locale.ENGLISH, "createSurface %d x %d", width, height));

            // Create new android.view.Surface & object reference.

            try {
                surfaceProducer.setSize(width, height);
                final Surface newSurface = surfaceProducer.getSurface();
                if (newSurface.equals(surface)) {
                    Log.i("media_kit", String.format(Locale.ENGLISH, "createSurface %d x %d - returning old instance", width, height));
                    return wid;
                }

                cleanupSurface();

                surface = newSurface;
                wid = (long) newGlobalObjectRef.invoke(null, surface);
                Log.i("media_kit", String.format(Locale.ENGLISH, "com.alexmercerind.mediakitandroidhelper.MediaKitAndroidHelper.newGlobalObjectRef: %d", wid));
            } catch (Throwable e) {
                e.printStackTrace();
            }
            return wid;
        }
    }


    private void clearSurface() {
        synchronized (lock) {
            if (surface == null || !surface.isValid()) {
                Log.w("media_kit", "Attempt to clear an invalid or null Surface.");
                return;
            }
            try {
                final Canvas canvas = surface.lockCanvas(null);
                canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR);
                surface.unlockCanvasAndPost(canvas);
            } catch (Throwable e) {
                e.printStackTrace();
            }
        }
    }

    private FlutterJNI getFlutterJNIReference() {
        try {
            FlutterView view = null;
            if (view == null) {
                view = MediaKitVideoPlugin.activity.findViewById(FlutterActivity.FLUTTER_VIEW_ID);
            }
            if (view == null) {
                final FrameLayout layout = (FrameLayout) MediaKitVideoPlugin.activity.findViewById(FlutterFragmentActivity.FRAGMENT_CONTAINER_ID);
                for (int i = 0; i < layout.getChildCount(); i++) {
                    final View child = layout.getChildAt(i);
                    if (child instanceof FlutterView) {
                        view = (FlutterView) child;
                        break;
                    }
                }
            }
            if (view == null) {
                Log.w("media_kit", "FlutterView not found.");
                return null;
            }
            final FlutterEngine engine = view.getAttachedFlutterEngine();
            final Field field = engine.getClass().getDeclaredField("flutterJNI");
            field.setAccessible(true);
            return (FlutterJNI) field.get(engine);
        } catch (Throwable e) {
            e.printStackTrace();
            return null;
        }
    }
}