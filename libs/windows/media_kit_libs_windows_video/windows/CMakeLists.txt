# This file is a part of media_kit (https://github.com/media-kit/media-kit).
#
# Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
# All rights reserved.
# Use of this source code is governed by MIT license that can be found in the LICENSE file.

cmake_minimum_required(VERSION 3.14)

# Other media_kit plugins read this option to find the native libraries.
option(MEDIA_KIT_LIBS_AVAILABLE "package:media_kit libraries are available." ON)

set(PROJECT_NAME "media_kit_libs_windows_video")
project(${PROJECT_NAME} LANGUAGES CXX)

# Use policies through CMake 3.25 when available.
# Keep compatibility with CMake 3.14.
cmake_policy(VERSION 3.14...3.25)

# ------------------------------------------------------------------------------
function(download_and_verify_sha256 url sha256 locationForArchive)
  if(EXISTS "${locationForArchive}")
    file(SHA256 "${locationForArchive}" ARCHIVE_SHA256)

    if(NOT "${sha256}" STREQUAL "${ARCHIVE_SHA256}")
      file(REMOVE "${locationForArchive}")
      message(STATUS "SHA-256 mismatch. File deleted.")
    endif()
  endif()

  if(NOT EXISTS "${locationForArchive}")
    message(STATUS "Downloading archive from ${url}...")
    file(
      DOWNLOAD
      "${url}"
      "${locationForArchive}"
      EXPECTED_HASH "SHA256=${sha256}"
      STATUS DOWNLOAD_STATUS
    )
    list(GET DOWNLOAD_STATUS 0 DOWNLOAD_STATUS_CODE)
    list(GET DOWNLOAD_STATUS 1 DOWNLOAD_STATUS_MESSAGE)

    if(NOT DOWNLOAD_STATUS_CODE EQUAL 0)
      file(REMOVE "${locationForArchive}")
      message(
        FATAL_ERROR
        "Failed to download ${url}: ${DOWNLOAD_STATUS_MESSAGE}"
      )
    endif()
  endif()

  file(SHA256 "${locationForArchive}" ARCHIVE_SHA256)

  if(NOT "${sha256}" STREQUAL "${ARCHIVE_SHA256}")
    message(
      FATAL_ERROR
      "${locationForArchive} SHA-256 verification failed."
    )
  endif()

  message(STATUS "${locationForArchive} SHA-256 verification successful.")
endfunction()

# Use 7-Zip if available. Otherwise, use CMake to extract the archive.
find_program(SEVENZ_EXECUTABLE NAMES 7z 7za)

# Select the libmpv SDK for the target architecture.
set(LIBMPV_RELEASE "20261123")
set(LIBMPV_BUILD_DATE "20261123")
set(LIBMPV_REVISION_SHORT "b0841e8c4d")

if("${FLUTTER_TARGET_PLATFORM}" STREQUAL "windows-x64")
  set(LIBMPV_ARCH "x86_64")
  set(
    LIBMPV_SHA256
    "437191bc801cd6f9f87c24e79a7f4afd117d07f609d196184a031634bcc1dcd3"
  )
elseif("${FLUTTER_TARGET_PLATFORM}" STREQUAL "windows-arm64")
  set(LIBMPV_ARCH "aarch64")
  set(
    LIBMPV_SHA256
    "872992724225bc772353546acdc5ff0194f9d9013feb8b1960a7b7c76bbed738"
  )
else()
  message(
    FATAL_ERROR
    "Unsupported FLUTTER_TARGET_PLATFORM for libmpv: "
    "${FLUTTER_TARGET_PLATFORM}. Expected windows-x64 or windows-arm64."
  )
endif()

set(
  LIBMPV
  "mpv-dev-${LIBMPV_ARCH}-${LIBMPV_BUILD_DATE}-git-${LIBMPV_REVISION_SHORT}.7z"
)
set(
  LIBMPV_URL
  "https://github.com/media-kit/libmpv-win32-video-cmake/releases/download/${LIBMPV_RELEASE}/${LIBMPV}"
)

set(LIBMPV_ARCHIVE "${CMAKE_BINARY_DIR}/${LIBMPV}")
set(LIBMPV_SRC "${CMAKE_BINARY_DIR}/libmpv")
set(LIBMPV_INCLUDE_DIR "${LIBMPV_SRC}/include/mpv")
set(LIBMPV_IMPORT_LIBRARY "${LIBMPV_SRC}/libmpv.dll.a")
set(LIBMPV_RUNTIME_LIBRARY "${LIBMPV_SRC}/libmpv-2.dll")

download_and_verify_sha256(
  "${LIBMPV_URL}"
  "${LIBMPV_SHA256}"
  "${LIBMPV_ARCHIVE}"
)

set(
  LIBMPV_REQUIRED_FILES
  "${LIBMPV_INCLUDE_DIR}/client.h"
  "${LIBMPV_INCLUDE_DIR}/render.h"
  "${LIBMPV_INCLUDE_DIR}/render_d3d11.h"
  "${LIBMPV_INCLUDE_DIR}/stream_cb.h"
  "${LIBMPV_IMPORT_LIBRARY}"
  "${LIBMPV_RUNTIME_LIBRARY}"
)

# Extract the verified SDK into an empty directory.
message(STATUS "Extracting ${LIBMPV}...")
file(REMOVE_RECURSE "${LIBMPV_SRC}")
file(MAKE_DIRECTORY "${LIBMPV_SRC}")

if(SEVENZ_EXECUTABLE)
  message(STATUS "Using 7zip for extraction: ${SEVENZ_EXECUTABLE}")
  execute_process(
    COMMAND "${SEVENZ_EXECUTABLE}" x -y "${LIBMPV_ARCHIVE}"
    WORKING_DIRECTORY "${LIBMPV_SRC}"
    RESULT_VARIABLE LIBMPV_EXTRACT_RESULT
    OUTPUT_VARIABLE LIBMPV_EXTRACT_OUTPUT
    ERROR_VARIABLE LIBMPV_EXTRACT_ERROR
  )
else()
  message(STATUS "7zip not found, falling back to CMake tar")
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E tar xvf "${LIBMPV_ARCHIVE}"
    WORKING_DIRECTORY "${LIBMPV_SRC}"
    RESULT_VARIABLE LIBMPV_EXTRACT_RESULT
    OUTPUT_VARIABLE LIBMPV_EXTRACT_OUTPUT
    ERROR_VARIABLE LIBMPV_EXTRACT_ERROR
  )
endif()

if(NOT LIBMPV_EXTRACT_RESULT EQUAL 0)
  file(REMOVE_RECURSE "${LIBMPV_SRC}")
  message(
    FATAL_ERROR
    "Failed to extract ${LIBMPV_ARCHIVE}:\n"
    "${LIBMPV_EXTRACT_OUTPUT}\n${LIBMPV_EXTRACT_ERROR}"
  )
endif()

foreach(LIBMPV_REQUIRED_FILE IN LISTS LIBMPV_REQUIRED_FILES)
  if(NOT EXISTS "${LIBMPV_REQUIRED_FILE}")
    file(REMOVE_RECURSE "${LIBMPV_SRC}")
    message(
      FATAL_ERROR
      "libmpv archive is missing required file: ${LIBMPV_REQUIRED_FILE}"
    )
  endif()
endforeach()

# ------------------------------------------------------------------------------

# Flutter uses this target name in its plugin build.
set(PLUGIN_NAME "media_kit_libs_windows_video_plugin")

add_library(${PLUGIN_NAME} SHARED
  "include/media_kit_libs_windows_video/media_kit_libs_windows_video_plugin_c_api.h"
  "media_kit_libs_windows_video_plugin_c_api.cpp"
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE
  FLUTTER_PLUGIN_IMPL
  _DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR
)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

set(
  media_kit_libs_windows_video_bundled_libraries
  "${LIBMPV_RUNTIME_LIBRARY}"
  PARENT_SCOPE
)
