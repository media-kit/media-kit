# This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
#
# Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
# All rights reserved.
# Use of this source code is governed by MIT license that can be found in the LICENSE file.

cmake_minimum_required(VERSION 3.14)

# This option is read by the other packages which are part of package:media_kit.
option(MEDIA_KIT_LIBS_AVAILABLE "package:media_kit libraries are available." ON)

set(PROJECT_NAME "media_kit_libs_windows_audio")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "media_kit_libs_windows_audio_plugin")

add_library(
  ${PLUGIN_NAME} SHARED
  "include/media_kit_libs_windows_audio/media_kit_libs_windows_audio_plugin_c_api.h"
  "media_kit_libs_windows_audio_plugin_c_api.cpp"
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(
  ${PLUGIN_NAME}
  PROPERTIES
  CXX_VISIBILITY_PRESET
  hidden
)
target_compile_definitions(
  ${PLUGIN_NAME}
  PRIVATE
  FLUTTER_PLUGIN_IMPL
)

target_include_directories(
  ${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
)
target_link_libraries(
  ${PLUGIN_NAME}
  PRIVATE
  flutter
  flutter_wrapper_plugin
)

# ------------------------------------------------------------------------------
option(MEDIA_KIT_LIBS_AVAILABLE "package:media_kit libraries are available." ON)

# Thanks to Mitchel Stewart (https://github.com/Quackdoc) for providing patches to generate minimal libmpv & FFmpeg audio specific builds.

# libmpv archive containing the pre-built shared libraries & headers.
set(LIBMPV "mpv-dev-x86_64-20230404-git-68b3239.7z")

# Download URL & MD5 hash of the libmpv archive.
set(LIBMPV_URL "https://github.com/media-kit/libmpv-win32-audio-build/releases/download/2023-07-18/${LIBMPV}")
set(LIBMPV_MD5 "6bc6adbcbc14744838e0a38923ef893a")

# Download location of the libmpv archive.
set(LIBMPV_ARCHIVE "${CMAKE_BINARY_DIR}/${LIBMPV}")
set(LIBMPV_SRC "${CMAKE_BINARY_DIR}/libmpv")

# Download the libmpv archive if it doesn't exist.
if(NOT EXISTS "${LIBMPV_ARCHIVE}")
  message(STATUS "Downloading ${LIBMPV}...")
  file(DOWNLOAD "${LIBMPV_URL}" "${LIBMPV_ARCHIVE}")
  message(STATUS "Downloaded ${LIBMPV}...")
endif()

# Match the MD5 hash of the downloaded libmpv archive. Exit on failure.
file(MD5 "${LIBMPV_ARCHIVE}" LIBMPV_ARCHIVE_MD5)

if(LIBMPV_MD5 STREQUAL LIBMPV_ARCHIVE_MD5)
  message(STATUS "${LIBMPV} verification successful.")
else()
  message(FATAL_ERROR "${LIBMPV} integrity check failed.")
endif()

# Extract the libmpv archive.
if(NOT EXISTS "${LIBMPV_SRC}")
  message(STATUS "Extracting ${LIBMPV}...")
  make_directory("${LIBMPV_SRC}")
  add_custom_target("${PROJECT_NAME}_LIBMPV_EXTRACT" ALL)
  add_custom_command(
    TARGET "${PROJECT_NAME}_LIBMPV_EXTRACT"
    COMMAND "${CMAKE_COMMAND}" -E tar xzf "\"${LIBMPV_ARCHIVE}\""
    COMMAND xcopy "\"${LIBMPV_SRC}/include/mpv\"" "\"${LIBMPV_SRC}/mpv\"" /E /H /C /I
    COMMAND rmdir "\"${LIBMPV_SRC}/include\"" /S /Q
    COMMAND ren "\"${LIBMPV_SRC}/mpv\"" "\"include\""
    WORKING_DIRECTORY "${LIBMPV_SRC}"
  )
endif()

# ------------------------------------------------------------------------------
set(
  media_kit_libs_windows_audio_bundled_libraries
  "${LIBMPV_SRC}/libmpv-2.dll"
  PARENT_SCOPE
)
