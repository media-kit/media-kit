# This file is a part of media_kit (https://github.com/media-kit/media-kit).
#
# Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
# All rights reserved.
# Use of this source code is governed by MIT license that can be found in the LICENSE file.

# Keep the minimum version compatible with Flutter plugin clients.
cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME "media_kit_video")
project(${PROJECT_NAME} LANGUAGES CXX)

cmake_policy(VERSION 3.14...3.25)

# Flutter's generated plugin build depends on this target name.
set(PLUGIN_NAME "media_kit_video_plugin")

# These libraries are supplied by package:media_kit_libs_***.
set(LIBMPV_SRC "${CMAKE_BINARY_DIR}/libmpv")
set(LIBMPV_INCLUDE_DIR "${LIBMPV_SRC}/include/mpv")
set(LIBMPV_IMPORT_LIBRARY "${LIBMPV_SRC}/libmpv.dll.a")
set(ANGLE_SRC "${CMAKE_BINARY_DIR}/ANGLE")

set(PLUGIN_SOURCES)
if(MEDIA_KIT_LIBS_AVAILABLE)
  list(APPEND PLUGIN_SOURCES
    "angle_surface_manager.cpp"
    "angle_surface_manager.h"
    "media_kit_video_plugin.cpp"
    "platform_task_runner.cpp"
    "platform_task_runner.h"
    "media_kit_video_plugin.h"
    "thread_pool.h"
    "video_frame_size.h"
    "video_output_manager.cpp"
    "video_output_manager.h"
    "video_output.cpp"
    "video_output.h"
    "utils.cpp"
    "utils.h"
  )
endif()

add_library(${PLUGIN_NAME} SHARED
  "include/media_kit_video/media_kit_video_plugin_c_api.h"
  "media_kit_video_plugin_c_api.cpp"
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
    "${ANGLE_SRC}/include"
  )
  target_link_libraries(${PLUGIN_NAME} PRIVATE
    "${LIBMPV_IMPORT_LIBRARY}"
    "${ANGLE_SRC}/lib/libEGL.dll.lib"
    "${ANGLE_SRC}/lib/libGLESv2.dll.lib"
  )
else()
  message(NOTICE "media_kit: WARNING: package:media_kit_libs_*** not found.")
  target_compile_definitions(${PLUGIN_NAME} PRIVATE MEDIA_KIT_LIBS_NOT_FOUND=1)
endif()

set(media_kit_video_bundled_libraries "" PARENT_SCOPE)

# Like the Flutter plugin template, clients only build tests when opted in.
if(include_media_kit_video_tests)
  enable_testing()
  add_subdirectory(test)
endif()
