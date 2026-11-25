# This file is a part of media_kit (https://github.com/media-kit/media-kit).
#
# Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
# All rights reserved.
# Use of this source code is governed by MIT license that can be found in the LICENSE file.

# Support Flutter projects that use CMake 3.14.
cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME "media_kit_video")
project(${PROJECT_NAME} LANGUAGES CXX)

cmake_policy(VERSION 3.14...3.25)

# Flutter uses this target name in its plugin build.
set(PLUGIN_NAME "media_kit_video_plugin")

# The Windows video libraries package supplies the libmpv SDK.
set(LIBMPV_SRC "${CMAKE_BINARY_DIR}/libmpv")
set(LIBMPV_INCLUDE_DIR "${LIBMPV_SRC}/include/mpv")
set(LIBMPV_IMPORT_LIBRARY "${LIBMPV_SRC}/libmpv.dll.a")

set(PLUGIN_SOURCES)
if(MEDIA_KIT_LIBS_AVAILABLE)
  list(APPEND PLUGIN_SOURCES
    "d3d11_surface_manager.cc"
    "d3d11_surface_manager.h"
    "media_kit_video_plugin.cc"
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
target_compile_definitions(${PLUGIN_NAME} PRIVATE
  FLUTTER_PLUGIN_IMPL
  _DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR
)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

if(MEDIA_KIT_LIBS_AVAILABLE)
  target_include_directories(${PLUGIN_NAME} PRIVATE
    "${LIBMPV_INCLUDE_DIR}"
  )
  target_link_libraries(${PLUGIN_NAME} PRIVATE
    "${LIBMPV_IMPORT_LIBRARY}"
    d3d11 dxgi
  )
else()
  message(NOTICE "media_kit: WARNING: package:media_kit_libs_*** not found.")
  target_compile_definitions(${PLUGIN_NAME} PRIVATE MEDIA_KIT_LIBS_NOT_FOUND=1)
endif()

set(media_kit_video_bundled_libraries "" PARENT_SCOPE)
