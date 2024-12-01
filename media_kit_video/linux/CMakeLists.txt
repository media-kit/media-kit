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
set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

set(LIBMPV_ZIP_URL "https://github.com/Predidit/libmpv-linux-build/releases/download/20241130/libmpv_x86_64.zip")
set(LIBMPV_ZIP_PATH "${CMAKE_BINARY_DIR}/libmpv_x86_64.zip")
set(LIBMPV_UNZIP_DIR "${CMAKE_BINARY_DIR}/mpv")

make_directory("${LIBMPV_UNZIP_DIR}") 
message(STATUS "create libmpv unzip directory ${LIBMPV_UNZIP_DIR}")

message(STATUS "downloading libmpv from ${LIBMPV_ZIP_URL} to ${LIBMPV_ZIP_PATH}")
file(DOWNLOAD ${LIBMPV_ZIP_URL} ${LIBMPV_ZIP_PATH} SHOW_PROGRESS STATUS download_status)

list(GET download_status 0 download_status_code)
if(NOT download_status_code EQUAL 0)
  message(FATAL_ERROR "libmpv download failed. err: ${download_status_code}")
else()
  message(STATUS "libmpv download completed.")
endif()

message(STATUS "unzip libmpv to ${LIBMPV_UNZIP_DIR}")
execute_process(
  COMMAND unzip -q ${LIBMPV_ZIP_PATH} -d ${LIBMPV_UNZIP_DIR}
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
  RESULT_VARIABLE unzip_result
)

if(NOT unzip_result EQUAL 0)
  message(FATAL_ERROR "unzip libmpv failed, err: ${unzip_result}")
else()
  message(STATUS "unzip libmpv success.")
endif()

set(LIBMPV_PATH "${LIBMPV_UNZIP_DIR}")

if(EXISTS "${LIBMPV_PATH}/libmpv.so")
  message(STATUS "libmpv.so founded ${LIBMPV_PATH}/libmpv.so")
else()
  message(FATAL_ERROR "libmpv.so not founded ${LIBMPV_PATH}")
endif()

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
  PkgConfig::epoxy
)

message(STATUS "create libmpv install directory ${CMAKE_BINARY_DIR}/mpv")
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/mpv")

set(
  media_kit_video_bundled_libraries
  "${LIBMPV_PATH}/libmpv.so"
  PARENT_SCOPE
)
