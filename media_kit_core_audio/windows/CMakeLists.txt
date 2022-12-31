# This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
#
# Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
# All rights reserved.
# Use of this source code is governed by MIT license that can be found in the LICENSE file.

cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME "media_kit_core_audio")
project(${PROJECT_NAME} LANGUAGES CXX)

# NOTE: This shared library has no support for various video codecs & formats or video output rendering.
# It is heavily stripped down version of libmpv & compilant with LGPL-2.1 license of FFmpeg & mpv.
# This was created specifically for Harmonoid to leverage audio playback using libmpv.
#
# See:
# https://github.com/harmonoid/harmonoid
# https://github.com/harmonoid/harmonoid-custom-codec
#

# libmpv shared library used for audio playback.
set(LIBMPV "mpv-2.dll")

# Download URL & MD5 hash of the libmpv shared library.
set(LIBMPV_URL "https://github.com/harmonoid/harmonoid-custom-codec/releases/download/0.34.0-196-g4629fe557f/${LIBMPV}")
set(LIBMPV_MD5 "c86dc63fe9340317e8b35b23cccea5ee")

# Download location of the libmpv shared library.
set(LIBMPV_SHARED_LIB "${CMAKE_BINARY_DIR}/${LIBMPV}")

# Download the libmpv archive if it doesn't exist.
if(NOT EXISTS "${LIBMPV_SHARED_LIB}")
  message(STATUS "Downloading ${LIBMPV}...")
  file(DOWNLOAD "${LIBMPV_URL}" "${LIBMPV_SHARED_LIB}")
  message(STATUS "Downloaded ${LIBMPV}...")
endif()

# Match the MD5 hash of the downloaded libmpv archive. Exit on failure.
file(MD5 "${LIBMPV_SHARED_LIB}" LIBMPV_SHARED_LIB_HASH)

if(LIBMPV_MD5 STREQUAL LIBMPV_SHARED_LIB_HASH)
  message(STATUS "${LIBMPV} verification successful.")
else()
  message(FATAL_ERROR "${LIBMPV} seems corrupt.")
endif()

set(
  media_kit_core_audio_bundled_libraries
  "${LIBMPV_SHARED_LIB}"
  PARENT_SCOPE
)
