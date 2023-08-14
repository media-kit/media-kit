# This file is a part of media_kit (https://github.com/media-kit/media-kit).
#
# Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
# All rights reserved.
# Use of this source code is governed by MIT license that can be found in the LICENSE file.

cmake_minimum_required(VERSION 3.14)

# This option is read by the other packages which are part of package:media_kit.
option(MEDIA_KIT_LIBS_AVAILABLE "package:media_kit libraries are available." ON)

set(PROJECT_NAME "media_kit_libs_windows_video")
project(${PROJECT_NAME} LANGUAGES CXX)

# ------------------------------------------------------------------------------

# libmpv archive containing the pre-built shared libraries & headers.
set(LIBMPV "mpv-dev-x86_64-20230811-git-140ec21.7z")

# Download URL & MD5 hash of the libmpv archive.
set(LIBMPV_URL "https://github.com/media-kit/libmpv-win32-video-build/releases/download/2023-08-11/${LIBMPV}")
set(LIBMPV_MD5 "c7d1d766a6404d58a876aca403e0f53a")

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

# ANGLE archive containing the pre-built shared libraries & headers.
set(ANGLE "ANGLE.7z")

# Download URL & MD5 hash of the ANGLE archive.
set(ANGLE_URL "https://github.com/alexmercerind/flutter-windows-ANGLE-OpenGL-ES/releases/download/v1.0.0/ANGLE.7z")
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
  message(FATAL_ERROR "${ANGLE} integrity check failed.")
endif()

# Extract the ANGLE archive.
if(NOT EXISTS "${ANGLE_SRC}")
  message(STATUS "Extracting ${ANGLE}...")
  make_directory("${ANGLE_SRC}")
  add_custom_target("${PROJECT_NAME}_ANGLE_EXTRACT" ALL)
  add_custom_command(
    TARGET "${PROJECT_NAME}_ANGLE_EXTRACT"
    COMMAND "${CMAKE_COMMAND}" -E tar xzf "\"${ANGLE_ARCHIVE}\""
    WORKING_DIRECTORY "${ANGLE_SRC}"
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

set(PLUGIN_NAME "media_kit_libs_windows_video_plugin")

add_library(
  ${PLUGIN_NAME} SHARED
  "include/media_kit_libs_windows_video/media_kit_libs_windows_video_plugin_c_api.h"
  "media_kit_libs_windows_video_plugin_c_api.cpp"
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
  media_kit_libs_windows_video_bundled_libraries
  "${LIBMPV_SRC}/libmpv-2.dll"
  "${ANGLE_SRC}/api-ms-win-core-console-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-console-l1-2-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-datetime-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-debug-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-errorhandling-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-fibers-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-file-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-file-l1-2-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-file-l2-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-handle-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-heap-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-interlocked-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-libraryloader-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-localization-l1-2-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-memory-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-namedpipe-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-processenvironment-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-processthreads-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-processthreads-l1-1-1.dll"
  "${ANGLE_SRC}/api-ms-win-core-profile-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-rtlsupport-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-string-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-synch-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-synch-l1-2-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-sysinfo-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-timezone-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-util-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-conio-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-convert-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-environment-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-filesystem-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-heap-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-locale-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-math-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-multibyte-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-private-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-process-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-runtime-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-stdio-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-string-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-time-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-utility-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-downlevel-kernel32-l2-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-eventing-provider-l1-1-0.dll"
  "${ANGLE_SRC}/concrt140.dll"
  "${ANGLE_SRC}/d3dcompiler_47.dll"
  "${ANGLE_SRC}/libc++.dll"
  "${ANGLE_SRC}/libEGL.dll"
  "${ANGLE_SRC}/libGLESv2.dll"
  "${ANGLE_SRC}/msvcp140.dll"
  "${ANGLE_SRC}/msvcp140_1.dll"
  "${ANGLE_SRC}/msvcp140_2.dll"
  "${ANGLE_SRC}/msvcp140_atomic_wait.dll"
  "${ANGLE_SRC}/msvcp140_codecvt_ids.dll"
  "${ANGLE_SRC}/ucrtbase.dll"
  "${ANGLE_SRC}/ucrtbased.dll"
  "${ANGLE_SRC}/vccorlib140.dll"
  "${ANGLE_SRC}/vccorlib140d.dll"
  "${ANGLE_SRC}/vcruntime140.dll"
  "${ANGLE_SRC}/vcruntime140d.dll"
  "${ANGLE_SRC}/vcruntime140_1.dll"
  "${ANGLE_SRC}/vcruntime140_1d.dll"
  "${ANGLE_SRC}/vk_swiftshader.dll"
  "${ANGLE_SRC}/vulkan-1.dll"
  "${ANGLE_SRC}/zlib.dll"
  PARENT_SCOPE
)
