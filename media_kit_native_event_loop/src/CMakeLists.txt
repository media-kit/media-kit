# This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
#
# Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
# All rights reserved.
# Use of this source code is governed by MIT license that can be found in the LICENSE file.

cmake_minimum_required(VERSION 3.10)

set(TARGET_NAME media_kit_native_event_loop)
set(CMAKE_CXX_STANDARD 17)

project(
  ${TARGET_NAME}_library
  VERSION 1.0.0 LANGUAGES CXX
)

add_library(
  ${TARGET_NAME} SHARED
  "${TARGET_NAME}.cc"
  "dart_api/dart_api_dl.cc"
)

if(${CMAKE_SYSTEM_NAME} MATCHES "Windows")
  # Set the path to libmpv & ANGLE source code.
  # Must be built before this CMake project.
  set(LIBMPV_SRC "${CMAKE_BINARY_DIR}/libmpv")

  # Include libmpv headers & link to the library.
  include_directories(
    "${LIBMPV_SRC}/include"
  )
  target_link_libraries(
    ${TARGET_NAME} PRIVATE
    "${LIBMPV_SRC}/libmpv.dll.a"
  )
elseif(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  # TODO: Add support for Linux.
elseif(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
  # TODO: Add support for macOS.
endif()

set_target_properties(
  ${TARGET_NAME} PROPERTIES
  PUBLIC_HEADER ${TARGET_NAME}.h
  OUTPUT_NAME "${TARGET_NAME}"
)

target_compile_definitions(${TARGET_NAME} PUBLIC DART_SHARED_LIB)
