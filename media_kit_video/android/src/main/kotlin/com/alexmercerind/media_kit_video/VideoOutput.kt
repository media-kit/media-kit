/**
 * This file is a part of media_kit (https://github.com/media-kit/media-kit).
 *
 * Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by MIT license that can be found in the LICENSE file.
 */
package com.alexmercerind.media_kit_video

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.view.TextureRegistry
import java.lang.reflect.Method
import java.util.Locale

internal class VideoOutput(
    textureRegistryReference: TextureRegistry,
    private val textureUpdateCallback: TextureUpdateCallback,
) : TextureRegistry.SurfaceProducer.Callback {
    companion object {
        private const val TAG = "VideoOutput"
        private val newGlobalObjectRefMethod: Method
        private val deleteGlobalObjectRefMethod: Method
        private val deletedGlobalObjectRefs = HashSet<Long>()
        private val handler = Handler(Looper.getMainLooper())

        init {
            try {
                // MediaKitAndroidHelper is part of the Android video and audio library packages.
                val mediaKitAndroidHelperClass =
                    Class.forName("com.alexmercerind.mediakitandroidhelper.MediaKitAndroidHelper")
                newGlobalObjectRefMethod =
                    mediaKitAndroidHelperClass.getDeclaredMethod(
                        "newGlobalObjectRef",
                        Any::class.java,
                    )
                deleteGlobalObjectRefMethod =
                    mediaKitAndroidHelperClass.getDeclaredMethod(
                        "deleteGlobalObjectRef",
                        java.lang.Long.TYPE,
                    )
                newGlobalObjectRefMethod.isAccessible = true
                deleteGlobalObjectRefMethod.isAccessible = true
            } catch (error: Throwable) {
                Log.i(
                    "media_kit",
                    "package:media_kit_libs_android_video missing. " +
                        "Make sure you have added it to pubspec.yaml.",
                )
                throw RuntimeException(
                    "Failed to initialize com.alexmercerind.media_kit_video.VideoOutput.",
                )
            }
        }

        private fun newGlobalObjectRef(value: Any): Long {
            Log.i(TAG, String.format(Locale.ENGLISH, "newGlobalRef: object = %s", value))
            return try {
                newGlobalObjectRefMethod.invoke(null, value) as Long
            } catch (error: Throwable) {
                Log.e(TAG, "newGlobalRef", error)
                0
            }
        }

        private fun deleteGlobalObjectRef(ref: Long) {
            if (deletedGlobalObjectRefs.contains(ref)) {
                Log.i(
                    TAG,
                    String.format(
                        Locale.ENGLISH,
                        "deleteGlobalObjectRef: ref = %d ALREADY DELETED",
                        ref,
                    ),
                )
                return
            }
            if (deletedGlobalObjectRefs.size > 100) {
                deletedGlobalObjectRefs.clear()
            }
            deletedGlobalObjectRefs.add(ref)
            Log.i(
                TAG,
                String.format(Locale.ENGLISH, "deleteGlobalObjectRef: ref = %d", ref),
            )
            try {
                deleteGlobalObjectRefMethod.invoke(null, ref)
            } catch (error: Throwable) {
                Log.e(TAG, "deleteGlobalObjectRef", error)
            }
        }
    }

    private var id = 0L
    private var wid = 0L
    private val surfaceProducer = textureRegistryReference.createSurfaceProducer()
    private val lock = Any()

    init {
        surfaceProducer.setCallback(this)
    }

    fun dispose() {
        synchronized(lock) {
            try {
                surfaceProducer.surface.release()
            } catch (error: Throwable) {
                Log.e(TAG, "dispose", error)
            }
            try {
                surfaceProducer.release()
            } catch (error: Throwable) {
                Log.e(TAG, "dispose", error)
            }
            onSurfaceCleanup()
        }
    }

    fun setSurfaceSize(width: Int, height: Int) {
        setSurfaceSize(width, height, false)
    }

    private fun setSurfaceSize(width: Int, height: Int, force: Boolean) {
        synchronized(lock) {
            try {
                if (!force && surfaceProducer.width == width && surfaceProducer.height == height) {
                    return
                }
                surfaceProducer.setSize(width, height)
                onSurfaceAvailable()
            } catch (error: Throwable) {
                Log.e(TAG, "setSurfaceSize", error)
            }
        }
    }

    override fun onSurfaceAvailable() {
        synchronized(lock) {
            Log.i(TAG, "onSurfaceAvailable")
            id = surfaceProducer.id()
            wid = newGlobalObjectRef(surfaceProducer.surface)
            textureUpdateCallback.onTextureUpdate(
                id,
                wid,
                surfaceProducer.width,
                surfaceProducer.height,
            )
        }
    }

    override fun onSurfaceCleanup() {
        synchronized(lock) {
            Log.i(TAG, "onSurfaceCleanup")
            textureUpdateCallback.onTextureUpdate(
                id,
                0,
                surfaceProducer.width,
                surfaceProducer.height,
            )
            if (wid != 0L) {
                val widReference = wid
                handler.postDelayed({ deleteGlobalObjectRef(widReference) }, 5000L)
            }
        }
    }
}
