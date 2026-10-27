/**
 * This file is a part of media_kit (https://github.com/media-kit/media-kit).
 *
 * Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by MIT license that can be found in the LICENSE file.
 */
package com.alexmercerind.mediakitandroidhelper

import android.content.Context
import android.net.Uri
import androidx.annotation.Keep

@Keep
class MediaKitAndroidHelper private constructor() {
    companion object {
        init {
            System.loadLibrary("mediakitandroidhelper")
        }

        // Store android.content.Context for access in openFileDescriptorJava.
        private lateinit var applicationContext: Context

        @JvmStatic external fun newGlobalObjectRef(obj: Any): Long

        @JvmStatic external fun deleteGlobalObjectRef(ref: Long)

        @JvmStatic external fun copyAssetToFilesDir(assetName: String): String

        @JvmStatic private external fun setApplicationContextNative(context: Context)

        @JvmStatic
        fun setApplicationContextJava(context: Context) {
            applicationContext = context
            setApplicationContextNative(context)
        }

        @JvmStatic external fun openFileDescriptorNative(uri: String): Int

        @JvmStatic
        fun openFileDescriptorJava(uri: String): Int =
            try {
                applicationContext.contentResolver.openFileDescriptor(Uri.parse(uri), "r")!!.detachFd()
            } catch (error: Throwable) {
                error.printStackTrace()
                -1
            }
    }
}
