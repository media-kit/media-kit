# This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
#
# Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
# All rights reserved.
# Use of this source code is governed by MIT license that can be found in the LICENSE file.

cmake_minimum_required(VERSION 3.10)

project(
  media_kit_native_event_loop_library
  VERSION 1.0.0 LANGUAGES CXX
)

add_library(
  media_kit_native_event_loop SHARED
  "media_kit_native_event_loop.c"
)

set_target_properties(
  media_kit_native_event_loop PROPERTIES
  PUBLIC_HEADER media_kit_native_event_loop.h
  OUTPUT_NAME "media_kit_native_event_loop"
)

target_compile_definitions(media_kit_native_event_loop PUBLIC DART_SHARED_LIB)
