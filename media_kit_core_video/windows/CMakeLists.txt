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
set(LIBMPV "mpv-dev-x86_64-20230116-git-50169e0.7z")

# Download URL & MD5 hash of the libmpv archive.
set(LIBMPV_URL "https://github.com/alexmercerind/mpv-win32-build/releases/download/2023-01-16/${LIBMPV}")
set(LIBMPV_MD5 "b05146e43a9c47a30d551f0ad57788cc")

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
    TARGET "${PROJECT_NAME}_LIBMPV_EXTRACT"
    COMMAND "${CMAKE_COMMAND}" -E tar xzf "${LIBMPV_ARCHIVE}"
    WORKING_DIRECTORY "${LIBMPV_SRC}"
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
    TARGET "${PROJECT_NAME}_ANGLE_EXTRACT"
    COMMAND "${CMAKE_COMMAND}" -E tar xzf "${ANGLE_ARCHIVE}"
    WORKING_DIRECTORY "${ANGLE_SRC}"
  )
endif()

# Some GPUs/Hardware seem to experience black flickering when rendering with hardware acceleration.
# Calling |glFinish| eliminates this. This seems to be some sort of synchronization problem between Flutter / Monitor / mpv etc.
# Now there are bunch of |glFinish| calls inside |ANGLESurfaceManager| & |VideoOutput| classes which fix any flickering issues.
# There doesn't seem to be any better alternative for OpenGL ES 2.0. See:
#
# * https://github.com/alexmercerind/media_kit/issues/10
# * https://github.com/alexmercerind/media_kit/pull/11
# * https://stackoverflow.com/a/12157120/12825435
#
# Though |glFinish| is not optimal, it is still way-way better in terms of performance as compared to software rendering.
# Personally, my budget machine with AMD Ryzen 3 2200U with integrated Radeon Vega 3 Mobile Graphics never experienced this issue.
# At most, 4K 30FPS or 1080p 60FPS videos play flawlessly without any major load on the hardware. 4K 60FPS videos certainly experience some frame drops. But nothing that can be referred as flicker.
add_definitions(-DENABLE_GL_FINISH_SAFEGUARD)

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

set(
  media_kit_core_video_bundled_libraries
  "${LIBMPV_SRC}/mpv-2.dll"
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
  "${ANGLE_SRC}/d3dcompiler_47.dll"
  "${ANGLE_SRC}/libc++.dll"
  "${ANGLE_SRC}/libEGL.dll"
  "${ANGLE_SRC}/libGLESv2.dll"
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
