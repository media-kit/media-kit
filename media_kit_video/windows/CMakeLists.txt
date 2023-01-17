# This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
#
# Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
# All rights reserved.
# Use of this source code is governed by MIT license that can be found in the LICENSE file.

cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME "media_kit_video")
set(CMAKE_CXX_STANDARD 17)
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "media_kit_video_plugin")

# Set the path to libmpv & ANGLE source code.
# Must be built before this CMake project.
set(LIBMPV_SRC "${CMAKE_BINARY_DIR}/libmpv")
set(ANGLE_SRC "${CMAKE_BINARY_DIR}/ANGLE")

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
  "media_kit_video_plugin_c_api.cc"
  "media_kit_video_plugin.cc"
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
  media_kit_video_bundled_libraries
  ""
  PARENT_SCOPE
)
