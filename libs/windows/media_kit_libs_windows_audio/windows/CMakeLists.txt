# This file is a part of media_kit (https://github.com/media-kit/media-kit).
#
# Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
# All rights reserved.
# Use of this source code is governed by MIT license that can be found in the LICENSE file.

cmake_minimum_required(VERSION 3.14)

# This option is read by the other packages which are part of package:media_kit.
option(MEDIA_KIT_LIBS_AVAILABLE "package:media_kit libraries are available." ON)

set(PROJECT_NAME "media_kit_libs_windows_audio")
project(${PROJECT_NAME} LANGUAGES CXX)

# ------------------------------------------------------------------------------

# Thanks to Mitchel Stewart (https://github.com/Quackdoc) for providing patches to generate minimal libmpv & FFmpeg audio specific builds.

# libmpv archive containing the pre-built shared libraries & headers.
set(LIBMPV "mpv-dev-x86_64-20230811-git-140ec21.7z")

# Download URL & MD5 hash of the libmpv archive.
set(LIBMPV_URL "https://github.com/media-kit/libmpv-win32-audio-build/releases/download/2023-08-11/${LIBMPV}")
set(LIBMPV_MD5 "8884ccad06b6888967ff5c034259378f")

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

# inflatecpp archive containing headers.
set(INFLATECPP "inflatecpp-a70d5fbbbfb2bd403f6d56796cebc0833ba04195")

# Download URL & MD5 hash of the inflatecpp archive.
set(INFLATECPP_URL "https://github.com/media-kit/inflatecpp/archive/a70d5fbbbfb2bd403f6d56796cebc0833ba04195.zip")
set(INFLATECPP_MD5 "a80999592d3288cdbf80e77ecf616282")

# Download location of the inflatecpp archive.
set(INFLATECPP_ARCHIVE "${CMAKE_BINARY_DIR}/${INFLATECPP}.zip")
set(INFLATECPP_SRC "${CMAKE_BINARY_DIR}/inflatecpp")

# Download the inflatecpp archive if it doesn't exist.
if(NOT EXISTS "${INFLATECPP_ARCHIVE}")
  message(STATUS "Downloading ${INFLATECPP}...")
  file(DOWNLOAD "${INFLATECPP_URL}" "${INFLATECPP_ARCHIVE}")
  message(STATUS "Downloaded ${INFLATECPP}...")
endif()

# Match the MD5 hash of the downloaded inflatecpp archive. Exit on failure.
file(MD5 "${INFLATECPP_ARCHIVE}" INFLATECPP_ARCHIVE_MD5)

if(INFLATECPP_MD5 STREQUAL INFLATECPP_ARCHIVE_MD5)
  message(STATUS "${INFLATECPP} verification successful.")
else()
  message(FATAL_ERROR "${INFLATECPP} integrity check failed.")
endif()

# Extract the inflatecpp archive.
if(NOT EXISTS "${INFLATECPP_SRC}")
  message(STATUS "Extracting ${INFLATECPP}...")
  make_directory("${INFLATECPP_SRC}")
  add_custom_target("${PROJECT_NAME}_INFLATECPP_EXTRACT" ALL)
  add_custom_command(
    TARGET "${PROJECT_NAME}_INFLATECPP_EXTRACT"
    COMMAND "${CMAKE_COMMAND}" -E tar xzf "\"${INFLATECPP_ARCHIVE}\""
    COMMAND "${CMAKE_COMMAND}" -E copy_directory "${INFLATECPP_SRC}/${INFLATECPP}" "${INFLATECPP_SRC}"
    WORKING_DIRECTORY "${INFLATECPP_SRC}"
  )
endif()

# ------------------------------------------------------------------------------
include_directories("${INFLATECPP_SRC}/include")

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

set(
  media_kit_libs_windows_audio_bundled_libraries
  "${LIBMPV_SRC}/libmpv-2.dll"
  PARENT_SCOPE
)
