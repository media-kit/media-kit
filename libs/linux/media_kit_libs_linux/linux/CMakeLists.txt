# This file is a part of media_kit (https://github.com/media-kit/media-kit).
#
# Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
# All rights reserved.
# Use of this source code is governed by MIT license that can be found in the LICENSE file.

cmake_minimum_required(VERSION 3.10)

# This option is read by the other packages which are part of package:media_kit.
option(MEDIA_KIT_LIBS_AVAILABLE "package:media_kit libraries are available." ON)

set(PROJECT_NAME "media_kit_libs_linux")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "media_kit_libs_linux_plugin")

add_library(
  ${PLUGIN_NAME} SHARED
  "media_kit_libs_linux_plugin.cc"
)

apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(
  ${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
)

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)

set(
  media_kit_libs_linux_bundled_libraries
  ""
  PARENT_SCOPE
)


# We use the mimalloc's object file (mimalloc.o) & link the final executable with it.
# This ensures that the standard malloc interface resolves to the mimalloc library.
#
# Refer to "Static Override" section in mimalloc's documentation:
# https://github.com/microsoft/mimalloc#static-override

# ------------------------------------------------------------------------------

set(MIMALLOC "mimalloc-2.1.2.tar.gz")

set(MIMALLOC_URL "https://github.com/microsoft/mimalloc/archive/refs/tags/v2.1.2.tar.gz")
set(MIMALLOC_MD5 "5179c8f5cf1237d2300e2d8559a7bc55")

set(MIMALLOC_ARCHIVE "${CMAKE_BINARY_DIR}/${MIMALLOC}")
set(MIMALLOC_SRC "${CMAKE_BINARY_DIR}/mimalloc")

# Download
if(NOT EXISTS ${MIMALLOC_ARCHIVE})
  message(STATUS "Downloading ${MIMALLOC}...")
  file(DOWNLOAD ${MIMALLOC_URL} ${MIMALLOC_ARCHIVE})
  message(STATUS "Downloaded ${MIMALLOC}...")
endif()

# Verify
file(MD5 ${MIMALLOC_ARCHIVE} MIMALLOC_ARCHIVE_MD5)

if(MIMALLOC_MD5 STREQUAL MIMALLOC_ARCHIVE_MD5)
  message(STATUS "${MIMALLOC} verification successful.")
else()
  message(FATAL_ERROR "${MIMALLOC} integrity check failed.")
endif()

# Extract
# https://stackoverflow.com/a/19859882/12825435
set(MIMALLOC_LIB "${MIMALLOC_SRC}/out/release/mimalloc.o" CACHE INTERNAL "")

if(NOT EXISTS ${MIMALLOC_SRC})
  message(STATUS "Extracting ${MIMALLOC}...")
  make_directory("${MIMALLOC_SRC}")
  add_custom_command(
    OUTPUT ${MIMALLOC_LIB}
    COMMAND "${CMAKE_COMMAND}" -E tar xzf "\"${MIMALLOC_ARCHIVE}\""
    # add_subdirectory() is too much work. Alternatively building it through command line.
    COMMAND "mkdir" "-p" "out/release"
    COMMAND "cd" "out/release"
    COMMAND "${CMAKE_COMMAND}" "../../mimalloc-2.1.2"
    COMMAND "make"
    WORKING_DIRECTORY "${MIMALLOC_SRC}"
  )
endif()

# ------------------------------------------------------------------------------

add_custom_target("MIMALLOC_TARGET" ALL DEPENDS ${MIMALLOC_LIB})
