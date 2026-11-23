# This file is a part of media_kit (https://github.com/media-kit/media-kit).
#
# Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
# All rights reserved.
# Use of this source code is governed by MIT license that can be found in the LICENSE file.

cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "media_kit_video")
project(${PROJECT_NAME} LANGUAGES CXX)

cmake_policy(VERSION 3.14...3.25)

# Flutter uses this target name in generated builds.
set(PLUGIN_NAME "media_kit_video_plugin")

# Build the renderer when the libmpv SDK is available.
set(PLUGIN_SOURCES)
if(MEDIA_KIT_LIBS_AVAILABLE)
  list(APPEND PLUGIN_SOURCES
    "d3d11_surface_manager.cc"
    "d3d11_surface_manager.h"
    "media_kit_video_plugin.cc"
    "platform_task_runner.cc"
    "platform_task_runner.h"
    "media_kit_video_plugin.h"
    "thread_pool.h"
    "video_frame_size.h"
    "video_output_manager.cc"
    "video_output_manager.h"
    "video_output.cc"
    "video_output.h"
    "utils.cc"
    "utils.h"
  )
endif()

add_library(${PLUGIN_NAME} SHARED
  "include/media_kit_video/media_kit_video_plugin_c_api.h"
  "media_kit_video_plugin_c_api.cc"
  ${PLUGIN_SOURCES}
)

apply_standard_settings(${PLUGIN_NAME})
target_compile_features(${PLUGIN_NAME} PRIVATE cxx_std_17)

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

if(MEDIA_KIT_LIBS_AVAILABLE)
  set(LIBMPV_SRC "${CMAKE_BINARY_DIR}/libmpv")
  target_include_directories(${PLUGIN_NAME} PRIVATE
    "${LIBMPV_SRC}/include/mpv"
  )
  target_link_libraries(${PLUGIN_NAME} PRIVATE
    "${LIBMPV_SRC}/libmpv.dll.a"
    d3d11 dxgi
  )
else()
  message(NOTICE "media_kit: WARNING: package:media_kit_libs_*** not found.")
  target_compile_definitions(${PLUGIN_NAME} PRIVATE MEDIA_KIT_LIBS_NOT_FOUND=1)
endif()

# The Windows video libraries package bundles the libmpv DLL.
set(media_kit_video_bundled_libraries
  ""
  PARENT_SCOPE
)
