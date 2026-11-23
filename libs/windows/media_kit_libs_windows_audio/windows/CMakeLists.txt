# This file is a part of media_kit (https://github.com/media-kit/media-kit).
#
# Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
# All rights reserved.
# Use of this source code is governed by MIT license that can be found in the LICENSE file.

cmake_minimum_required(VERSION 3.14)

# Other media_kit plugins use this option to locate the native libraries.
option(MEDIA_KIT_LIBS_AVAILABLE "package:media_kit libraries are available." ON)

# Project-level configuration.
set(PROJECT_NAME "media_kit_libs_windows_audio")
project(${PROJECT_NAME} LANGUAGES CXX)

cmake_policy(VERSION 3.14...3.25)

# libmpv SDK
function(download_and_verify url sha256 locationForArchive)
  if(EXISTS "${locationForArchive}")
    file(SHA256 "${locationForArchive}" ARCHIVE_SHA256)

    # Download the archive again if its checksum has changed.
    if(NOT sha256 STREQUAL ARCHIVE_SHA256)
      file(REMOVE "${locationForArchive}")
      message(STATUS "SHA-256 mismatch. File deleted.")
    endif()
  endif()

  if(NOT EXISTS "${locationForArchive}")
    message(STATUS "Downloading archive from ${url}...")
    file(DOWNLOAD "${url}" "${locationForArchive}")
    message(STATUS "Downloaded archive to ${locationForArchive}.")

    # Verify the downloaded archive.
    file(SHA256 "${locationForArchive}" ARCHIVE_SHA256)

    if(sha256 STREQUAL ARCHIVE_SHA256)
      message(STATUS "${locationForArchive} Verification successful.")
    else()
      message(FATAL_ERROR "${locationForArchive} Integrity check failed, please try to re-build project again.")
    endif()
  endif()
endfunction()

function(check_directory_exists_and_not_empty dir result_var)
  file(GLOB dir_contents CONFIGURE_DEPENDS "${dir}/*")
  if(dir_contents)
    set(${result_var} TRUE PARENT_SCOPE)
  else()
    set(${result_var} FALSE PARENT_SCOPE)
  endif()
endfunction()

# Thanks to Mitchel Stewart (https://github.com/Quackdoc) for providing patches to generate minimal libmpv & FFmpeg audio specific builds.

set(LIBMPV_RELEASE "20251213")
set(LIBMPV_REVISION "140ec21")

# Select the release archive for the Flutter target.
if(FLUTTER_TARGET_PLATFORM STREQUAL "windows-arm64")
  set(LIBMPV_ARCH "aarch64")
  set(LIBMPV_SHA256 "904062ce25811025af5c96b02fc90612eff9567659378caf30cc13a1953eb654")
elseif(FLUTTER_TARGET_PLATFORM STREQUAL "windows-x64")
  set(LIBMPV_ARCH "x86_64")
  set(LIBMPV_SHA256 "a4d4e82a7bf218ef939e4090e0c19e11a0f660aae9d9297a2973c1582c2239a0")
else()
  message(FATAL_ERROR "Unsupported FLUTTER_TARGET_PLATFORM '${FLUTTER_TARGET_PLATFORM}'. Expected windows-arm64 or windows-x64.")
endif()

set(LIBMPV "mpv-dev-${LIBMPV_ARCH}-${LIBMPV_RELEASE}-git-${LIBMPV_REVISION}.7z")
set(LIBMPV_URL "https://github.com/media-kit/libmpv-win32-audio-cmake/releases/download/${LIBMPV_RELEASE}/${LIBMPV}")
set(LIBMPV_ARCHIVE "${CMAKE_BINARY_DIR}/${LIBMPV}")
set(LIBMPV_SRC "${CMAKE_BINARY_DIR}/libmpv")

download_and_verify(${LIBMPV_URL} ${LIBMPV_SHA256} ${LIBMPV_ARCHIVE})

set(LIBMPV_STAMP "${LIBMPV_SRC}/.extracted-${LIBMPV_SHA256}")
check_directory_exists_and_not_empty("${LIBMPV_SRC}" LIBMPV_SRC_VALID)

# Prefer 7-Zip for .7z archives.
find_program(SEVENZ_EXECUTABLE NAMES 7z 7za)

if(NOT LIBMPV_SRC_VALID OR NOT EXISTS "${LIBMPV_STAMP}"
    OR NOT EXISTS "${LIBMPV_SRC}/include/client.h"
    OR NOT EXISTS "${LIBMPV_SRC}/libmpv.dll.a"
    OR NOT EXISTS "${LIBMPV_SRC}/libmpv-2.dll")
  file(REMOVE_RECURSE "${LIBMPV_SRC}")
  make_directory("${LIBMPV_SRC}")
  add_custom_target("${PROJECT_NAME}_LIBMPV_EXTRACT" ALL)
  add_dependencies(flutter_wrapper_plugin "${PROJECT_NAME}_LIBMPV_EXTRACT")

  if(SEVENZ_EXECUTABLE)
    message(STATUS "Using 7zip for extraction: ${SEVENZ_EXECUTABLE}")
    set(extractor "${SEVENZ_EXECUTABLE}" x -y)
  elseif(LIBMPV_ARCH STREQUAL "aarch64")
    # These .7z archives use the ARM64 filter. Some CMake versions cannot decode it.
    find_program(WINDOWS_TAR_EXECUTABLE NAMES tar.exe
      PATHS "$ENV{SystemRoot}/System32" NO_DEFAULT_PATH)
    if(NOT WINDOWS_TAR_EXECUTABLE)
      message(FATAL_ERROR "Windows tar.exe was not found. Install 7-Zip to extract the ARM64 SDK.")
    endif()
    message(STATUS "Using Windows tar for ARM64 extraction: ${WINDOWS_TAR_EXECUTABLE}")
    set(extractor "${WINDOWS_TAR_EXECUTABLE}" -xf)
  else()
    message(STATUS "7zip not found, falling back to CMake tar")
    set(extractor "${CMAKE_COMMAND}" -E tar xzf)
  endif()

  add_custom_command(TARGET "${PROJECT_NAME}_LIBMPV_EXTRACT" POST_BUILD
    COMMAND ${extractor} "${LIBMPV_ARCHIVE}"
    # Audio consumers include the mpv headers directly from include/.
    COMMAND "${CMAKE_COMMAND}" -E copy_directory "${LIBMPV_SRC}/include/mpv" "${LIBMPV_SRC}/include"
    COMMAND "${CMAKE_COMMAND}" -E remove_directory "${LIBMPV_SRC}/include/mpv"
    COMMAND "${CMAKE_COMMAND}" -E touch "${LIBMPV_STAMP}"
    WORKING_DIRECTORY "${LIBMPV_SRC}"
    VERBATIM
  )
endif()

# Flutter uses this target name in generated builds.
set(PLUGIN_NAME "media_kit_libs_windows_audio_plugin")

add_library(${PLUGIN_NAME} SHARED
  "include/media_kit_libs_windows_audio/media_kit_libs_windows_audio_plugin_c_api.h"
  "media_kit_libs_windows_audio_plugin_c_api.cpp"
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# Libraries to bundle with the plugin.
set(media_kit_libs_windows_audio_bundled_libraries
  "${LIBMPV_SRC}/libmpv-2.dll"
  PARENT_SCOPE
)
