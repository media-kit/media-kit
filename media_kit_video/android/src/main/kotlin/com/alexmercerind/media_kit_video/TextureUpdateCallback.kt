package com.alexmercerind.media_kit_video

fun interface TextureUpdateCallback {
    fun onTextureUpdate(id: Long, wid: Long, width: Int, height: Int)
}
