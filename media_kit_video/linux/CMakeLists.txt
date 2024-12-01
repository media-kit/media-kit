# This file is a part of media_kit (https://github.com/media-kit/media-kit).
#
# Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
# All rights reserved.
# Use of this source code is governed by MIT license that can be found in the LICENSE file.

# The file is moded for the purpose of building application with libmpv embeded.
# Copyright © 2024 & Predidit
# All rights reserved.

cmake_minimum_required(VERSION 3.10)

set(PROJECT_NAME "media_kit_video")
set(CMAKE_CXX_STANDARD 17)
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "media_kit_video_plugin")

set(LIBMPV_ZIP_URL "https://github.com/Predidit/libmpv-linux-build/releases/download/20241130/libmpv_x86_64.zip")
set(LIBMPV_ZIP_PATH "${CMAKE_BINARY_DIR}/libmpv_x86_64.zip")
set(LIBMPV_UNZIP_DIR "${CMAKE_BINARY_DIR}/libmpv")

file(DOWNLOAD ${LIBMPV_ZIP_URL} ${LIBMPV_ZIP_PATH} SHOW_PROGRESS)

execute_process(
  COMMAND ${CMAKE_COMMAND} -E remove_directory ${LIBMPV_UNZIP_DIR}  
  COMMAND ${CMAKE_COMMAND} -E make_directory ${LIBMPV_UNZIP_DIR}   
  COMMAND unzip -q ${LIBMPV_ZIP_PATH} -d ${LIBMPV_UNZIP_DIR}        
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
)

set(LIBMPV_PATH "${LIBMPV_UNZIP_DIR}")

if(MEDIA_KIT_LIBS_AVAILABLE)
  add_library(
    ${PLUGIN_NAME} SHARED
    "media_kit_video_plugin.cc"
    "texture_gl.cc"
    "texture_sw.cc"
    "video_output_manager.cc"
    "video_output.cc"
    "utils.cc"
  )

  apply_standard_settings(${PLUGIN_NAME})

  # Check for libmpv & epoxy headers & libraries.
  find_package(PkgConfig REQUIRED)
  pkg_check_modules(mpv IMPORTED_TARGET mpv)
  pkg_check_modules(epoxy IMPORTED_TARGET epoxy)

  set_target_properties(
    ${PLUGIN_NAME} PROPERTIES
    CXX_VISIBILITY_PRESET hidden
  )

  target_compile_definitions(
    ${PLUGIN_NAME} PRIVATE
    FLUTTER_PLUGIN_IMPL
  )

  target_compile_options(${PLUGIN_NAME} PRIVATE "${mpv_CFLAGS_OTHER}")
  target_compile_options(${PLUGIN_NAME} PRIVATE "${epoxy_CFLAGS_OTHER}")

  target_include_directories(
    ${PLUGIN_NAME} INTERFACE
    "${CMAKE_CURRENT_SOURCE_DIR}/include"
    "${mpv_INCLUDE_DIRS}"
    "${epoxy_INCLUDE_DIRS}"
  )

  target_link_libraries(
    ${PLUGIN_NAME} PRIVATE
    flutter
    PkgConfig::GTK
    PkgConfig::mpv
    PkgConfig::epoxy
  )

  set_target_properties(${PLUGIN_NAME} PROPERTIES
    INSTALL_RPATH "${LIBMPV_PATH}"
  )

else()
  message(NOTICE "media_kit: WARNING: package:media_kit_libs_*** not found.")

  add_library(
    ${PLUGIN_NAME} SHARED
    "media_kit_video_plugin.cc"
  )

  apply_standard_settings(${PLUGIN_NAME})

  set_target_properties(
    ${PLUGIN_NAME} PROPERTIES
    CXX_VISIBILITY_PRESET hidden
  )

  target_compile_definitions(
    ${PLUGIN_NAME} PRIVATE
    FLUTTER_PLUGIN_IMPL
    "MEDIA_KIT_LIBS_NOT_FOUND=1"
  )

  target_include_directories(
    ${PLUGIN_NAME} INTERFACE
    "${CMAKE_CURRENT_SOURCE_DIR}/include"
  )

  target_link_libraries(
    ${PLUGIN_NAME} PRIVATE
    flutter
    PkgConfig::GTK
  )
endif()

install(
  FILES "${LIBMPV_PATH}/libmpv.so"
  DESTINATION "${CMAKE_BINARY_DIR}/libmpv"
)

set(
  media_kit_video_bundled_libraries
  "${LIBMPV_PATH}/libmpv.so"
  PARENT_SCOPE
)
