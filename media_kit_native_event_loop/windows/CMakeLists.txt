# # This file is a part of media_kit (https://github.com/media-kit/media-kit).
# #
# # Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
# # All rights reserved.
# # Use of this source code is governed by MIT license that can be found in the LICENSE file.

# cmake_minimum_required(VERSION 3.14)

# set(PROJECT_NAME "media_kit_native_event_loop")
# project(${PROJECT_NAME} LANGUAGES CXX)

# add_subdirectory(
#   "${CMAKE_CURRENT_SOURCE_DIR}/../src"
#   "${CMAKE_CURRENT_BINARY_DIR}/shared"
# )

# if(MEDIA_KIT_LIBS_AVAILABLE)
#   set(
#     media_kit_native_event_loop_bundled_libraries
#     $<TARGET_FILE:media_kit_native_event_loop>
#     PARENT_SCOPE
#   )
# else()
#   set(
#     media_kit_native_event_loop_bundled_libraries
#     ""
#     PARENT_SCOPE
#   )
# endif()
