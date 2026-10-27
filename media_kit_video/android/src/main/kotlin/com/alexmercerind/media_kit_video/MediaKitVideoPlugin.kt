/**
 * This file is a part of media_kit (https://github.com/media-kit/media-kit).
 *
 * Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by MIT license that can be found in the LICENSE file.
 */
package com.alexmercerind.media_kit_video

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MediaKitVideoPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var videoOutputManager: VideoOutputManager

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel =
            MethodChannel(
                flutterPluginBinding.binaryMessenger,
                "com.alexmercerind/media_kit_video",
            )
        channel.setMethodCallHandler(this)
        videoOutputManager = VideoOutputManager(flutterPluginBinding.textureRegistry)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "VideoOutputManager.Create" -> {
                val handle = call.argument<String>("handle")!!.toLong()
                videoOutputManager.create(handle) { id, wid, width, height ->
                    channel.invokeMethod(
                        "VideoOutput.Resize",
                        hashMapOf<String, Any>(
                            "handle" to handle,
                            "id" to id,
                            "wid" to wid,
                            "rect" to
                                hashMapOf<String, Any>(
                                    "left" to 0,
                                    "top" to 0,
                                    "width" to width,
                                    "height" to height,
                                ),
                        ),
                    )
                }
                result.success(null)
            }

            "VideoOutputManager.SetSurfaceSize" -> {
                val handle = call.argument<String>("handle")!!.toLong()
                val width = call.argument<String>("width")!!.toInt()
                val height = call.argument<String>("height")!!.toInt()
                videoOutputManager.setSurfaceSize(handle, width, height)
                result.success(null)
            }

            "VideoOutputManager.Dispose" -> {
                val handle = call.argument<String>("handle")!!.toLong()
                videoOutputManager.dispose(handle)
                result.success(null)
            }

            "Utils.IsEmulator" -> result.success(Utils.isEmulator())
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
