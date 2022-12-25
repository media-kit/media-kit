# This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
#
# Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
# All rights reserved.
# Use of this source code is governed by MIT license that can be found in the LICENSE file.

cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME "media_kit_core_video")
set(CMAKE_CXX_STANDARD 17)
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "media_kit_core_video_plugin")

# libmpv archive containing the pre-built shared libraries & headers.
set(LIBMPV "mpv-dev-x86_64-20221218-git-f9d0b0c.7z")

# Download URL & MD5 hash of the libmpv archive.
set(LIBMPV_URL "https://github.com/alexmercerind/mpv-win32-build/releases/download/2022-12-18/${LIBMPV}")
set(LIBMPV_MD5 "ca9a6ae5cae420e43c04a292082c9651")

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
  message(FATAL_ERROR "${LIBMPV} seems corrupt.")
endif()

# Extract the libmpv archive.
if(NOT EXISTS "${LIBMPV_SRC}")
  message(STATUS "Extracting ${LIBMPV}...")
  make_directory("${LIBMPV_SRC}")
  add_custom_target("${PROJECT_NAME}_LIBMPV_EXTRACT" ALL)
  add_custom_command(
    TARGET "${PROJECT_NAME}_LIBMPV_EXTRACT" PRE_BUILD
    COMMAND "${CMAKE_COMMAND}" -E tar xzf "${LIBMPV_ARCHIVE}"
    WORKING_DIRECTORY "${LIBMPV_SRC}"
    DEPENDS "${LIBMPV_ARCHIVE}"
  )
endif()

# ANGLE archive containing the pre-built shared libraries & headers.
set(ANGLE "ANGLE.7z")

# Download URL & MD5 hash of the ANGLE archive.
set(ANGLE_URL "https://github.com/alexmercerind/flutter-windows-ANGLE-OpenGL-Direct3D-Interop/releases/download/v1.0.0/${ANGLE}")
set(ANGLE_MD5 "e5be38d0e1c5cbe5f70e53701ea8b6c9")

# Download location of the ANGLE archive.
set(ANGLE_ARCHIVE "${CMAKE_BINARY_DIR}/${ANGLE}")
set(ANGLE_SRC "${CMAKE_BINARY_DIR}/ANGLE")

# Download the ANGLE archive if it doesn't exist.
if(NOT EXISTS "${ANGLE_ARCHIVE}")
  message(STATUS "Downloading ${ANGLE}...")
  file(DOWNLOAD "${ANGLE_URL}" "${ANGLE_ARCHIVE}")
  message(STATUS "Downloaded ${ANGLE}...")
endif()

# Match the MD5 hash of the downloaded ANGLE archive. Exit on failure.
file(MD5 "${ANGLE_ARCHIVE}" ANGLE_ARCHIVE_MD5)

if(ANGLE_MD5 STREQUAL ANGLE_ARCHIVE_MD5)
  message(STATUS "${ANGLE} verification successful.")
else()
  message(FATAL_ERROR "${ANGLE} seems corrupt.")
endif()

# Extract the ANGLE archive.
if(NOT EXISTS "${ANGLE_SRC}")
  message(STATUS "Extracting ${ANGLE}...")
  make_directory("${ANGLE_SRC}")
  add_custom_target("${PROJECT_NAME}_ANGLE_EXTRACT" ALL)
  add_custom_command(
    TARGET "${PROJECT_NAME}_ANGLE_EXTRACT" PRE_BUILD
    COMMAND "${CMAKE_COMMAND}" -E tar xzf "${ANGLE_ARCHIVE}"
    WORKING_DIRECTORY "${ANGLE_SRC}"
    DEPENDS "${ANGLE_ARCHIVE}"
  )
endif()

# Add libmpv & ANGLE headers to the include path.
include_directories(
  "${LIBMPV_SRC}/include"
  "${ANGLE_SRC}/include"
)

add_library(
  ${PLUGIN_NAME} SHARED
  "angle_surface_manager.cc"
  "media_kit_core_video_plugin_c_api.cc"
  "media_kit_core_video_plugin.cc"
  "video_output_manager.cc"
  "video_output.cc"
  ${PLUGIN_SOURCES}
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(
  ${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden
)
target_compile_definitions(
  ${PLUGIN_NAME} PRIVATE
  FLUTTER_PLUGIN_IMPL
)
target_include_directories(
  ${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
)
target_link_libraries(
  ${PLUGIN_NAME} PRIVATE
  flutter
  flutter_wrapper_plugin
  "${LIBMPV_SRC}/libmpv.dll.a"
  "${ANGLE_SRC}/lib/libEGL.dll.lib"
  "${ANGLE_SRC}/lib/libGLESv2.dll.lib"
)

set(media_kit_core_video_bundled_libraries
  ""
  PARENT_SCOPE
)
