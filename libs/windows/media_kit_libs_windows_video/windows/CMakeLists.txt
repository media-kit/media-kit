# This file is a part of media_kit (https://github.com/media-kit/media-kit).
#
# Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
# All rights reserved.
# Use of this source code is governed by MIT license that can be found in the LICENSE file.

cmake_minimum_required(VERSION 3.14)
cmake_policy(SET CMP0175 NEW)

# This option is read by the other packages which are part of package:media_kit.
option(MEDIA_KIT_LIBS_AVAILABLE "package:media_kit libraries are available." ON)

set(PROJECT_NAME "media_kit_libs_windows_video")
project(${PROJECT_NAME} LANGUAGES CXX)

# Deal with MSVC incompatiblity
add_compile_definitions(_DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR)

# ------------------------------------------------------------------------------
function(download_and_verify url md5 locationForArchive)
  # Check if the archive exists.
  if(EXISTS "${locationForArchive}")
    file(MD5 "${locationForArchive}" ARCHIVE_MD5)

    # If MD5 doesn't match, delete the archive to download again.
    if(NOT md5 STREQUAL ARCHIVE_MD5)
      file(REMOVE "${locationForArchive}")
      message(STATUS "MD5 mismatch. File deleted.")
    endif()
  endif()

  # Download the archive if it doesn't exist.
  if(NOT EXISTS "${locationForArchive}")
    message(STATUS "Downloading archive from ${url}...")
    file(DOWNLOAD "${url}" "${locationForArchive}")
    message(STATUS "Downloaded archive to ${locationForArchive}.")

    # Verify MD5 of the newly downloaded file.
    file(MD5 "${locationForArchive}" ARCHIVE_MD5)

    if(md5 STREQUAL ARCHIVE_MD5)
      message(STATUS "${locationForArchive} Verification successful.")
    else()
      message(FATAL_ERROR "${locationForArchive} Integrity check failed, please try to re-build project again.")
    endif()
  endif()
endfunction()

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
      TLS_VERIFY ON
      TIMEOUT 300
      INACTIVITY_TIMEOUT 30
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

function(check_directory_exists_and_not_empty dir result_var)
  # Check if the directory exists
  if(EXISTS "${dir}")
    # Check if the directory is not empty
    file(GLOB dir_contents "${dir}/*")

    if(dir_contents)
      set(${result_var} TRUE PARENT_SCOPE)
    else()
      set(${result_var} FALSE PARENT_SCOPE)
      message(STATUS "Directory ${dir} exists but is empty!")
    endif()
  else()
    set(${result_var} FALSE PARENT_SCOPE)
    message(STATUS "Directory ${dir} does not exist!")
  endif()
endfunction()

# Detect architecture and set appropriate libmpv archive
if(${FLUTTER_TARGET_PLATFORM} STREQUAL "windows-x64")
  set(LIBMPV_ARCH "x86_64")
  set(LIBMPV "mpv-dev-x86_64-20241021-git-0f78584.7z")
  set(LIBMPV_MD5 "6ecf18e85b093c3f7edb16f3ee6603f3")
else()
  set(LIBMPV_ARCH "aarch64")
  set(LIBMPV "mpv-dev-aarch64-20241021-git-0f78584.7z")
  set(LIBMPV_MD5 "5b507a35db13eee6cb7eb21e8be7c83d")
endif()

# Download URL for the libmpv archive from the latest release
set(LIBMPV_URL "https://github.com/media-kit/libmpv-win32-video-cmake/releases/download/20241021/${LIBMPV}")

# Download location of the libmpv archive.
set(LIBMPV_ARCHIVE "${CMAKE_BINARY_DIR}/${LIBMPV}")
set(LIBMPV_SRC "${CMAKE_BINARY_DIR}/libmpv")

download_and_verify(
  ${LIBMPV_URL}
  ${LIBMPV_MD5}
  ${LIBMPV_ARCHIVE}
)

check_directory_exists_and_not_empty(${LIBMPV_SRC} LIBMPV_SRC_VALID)

# Find 7zip for extraction (preferred for .7z files)
find_program(SEVENZ_EXECUTABLE NAMES 7z 7za)

# Extract the libmpv archive.
if(NOT LIBMPV_SRC_VALID)
  message(STATUS "Extracting ${LIBMPV}...")
  make_directory("${LIBMPV_SRC}")
  add_custom_target("${PROJECT_NAME}_LIBMPV_EXTRACT" ALL)
  
  if(SEVENZ_EXECUTABLE)
    message(STATUS "Using 7zip for extraction: ${SEVENZ_EXECUTABLE}")
    add_custom_command(
      TARGET "${PROJECT_NAME}_LIBMPV_EXTRACT"
      POST_BUILD
      COMMAND "${SEVENZ_EXECUTABLE}" x -y "\"${LIBMPV_ARCHIVE}\""
      COMMAND xcopy "\"${LIBMPV_SRC}/include/mpv\"" "\"${LIBMPV_SRC}/mpv\"" /E /H /C /I
      COMMAND rmdir "\"${LIBMPV_SRC}/include\"" /S /Q
      COMMAND ren "\"${LIBMPV_SRC}/mpv\"" "\"include\""
      WORKING_DIRECTORY "${LIBMPV_SRC}"
    )
  else()
    message(STATUS "7zip not found, falling back to CMake tar")
    add_custom_command(
      TARGET "${PROJECT_NAME}_LIBMPV_EXTRACT"
      POST_BUILD
      COMMAND "${CMAKE_COMMAND}" -E tar xzf "\"${LIBMPV_ARCHIVE}\""
      COMMAND xcopy "\"${LIBMPV_SRC}/include/mpv\"" "\"${LIBMPV_SRC}/mpv\"" /E /H /C /I
      COMMAND rmdir "\"${LIBMPV_SRC}/include\"" /S /Q
      COMMAND ren "\"${LIBMPV_SRC}/mpv\"" "\"include\""
      WORKING_DIRECTORY "${LIBMPV_SRC}"
    )
  endif()
endif()

# ------------------------------------------------------------------------------

# ANGLE archive containing the pre-built shared libraries & headers.
set(ANGLE_VERSION "1.1.0")
set(ANGLE_REVISION_SHORT "d10b3bd2324e")

if("${FLUTTER_TARGET_PLATFORM}" STREQUAL "windows-x64")
  set(ANGLE_ARCH "x64")
  set(
    ANGLE_SHA256
    "81005450bf6968524776a967b9f9d640a77990a273dbc42dc1d050fcb65fdc97"
  )
elseif("${FLUTTER_TARGET_PLATFORM}" STREQUAL "windows-arm64")
  set(ANGLE_ARCH "arm64")
  set(
    ANGLE_SHA256
    "886e8c78c87e670a2681198574092585ef9a7d95a8a5d94c5aa06e27d03dc38c"
  )
else()
  message(
    FATAL_ERROR
    "Unsupported FLUTTER_TARGET_PLATFORM for ANGLE: "
    "${FLUTTER_TARGET_PLATFORM}. Expected windows-x64 or windows-arm64."
  )
endif()

set(ANGLE "ANGLE-${ANGLE_REVISION_SHORT}-windows-${ANGLE_ARCH}.7z")
set(
  ANGLE_URL
  "https://github.com/Carapacik/flutter-windows-ANGLE-OpenGL-ES/releases/download/v${ANGLE_VERSION}/${ANGLE}"
)

# Download location of the ANGLE archive.
set(ANGLE_ARCHIVE "${CMAKE_BINARY_DIR}/${ANGLE}")
set(ANGLE_SRC "${CMAKE_BINARY_DIR}/ANGLE")
set(ANGLE_INCLUDE_DIR "${ANGLE_SRC}/include")
set(ANGLE_LIB_DIR "${ANGLE_SRC}/lib")

download_and_verify_sha256(
  "${ANGLE_URL}"
  "${ANGLE_SHA256}"
  "${ANGLE_ARCHIVE}"
)

set(
  ANGLE_REQUIRED_FILES
  "${ANGLE_INCLUDE_DIR}/EGL/egl.h"
  "${ANGLE_INCLUDE_DIR}/GLES2/gl2.h"
  "${ANGLE_INCLUDE_DIR}/GLES3/gl3.h"
  "${ANGLE_INCLUDE_DIR}/KHR/khrplatform.h"
  "${ANGLE_LIB_DIR}/d3dcompiler_47.dll"
  "${ANGLE_LIB_DIR}/libEGL.dll"
  "${ANGLE_LIB_DIR}/libGLESv2.dll"
  "${ANGLE_LIB_DIR}/vulkan-1.dll"
  "${ANGLE_LIB_DIR}/vk_swiftshader.dll"
  "${ANGLE_LIB_DIR}/vk_swiftshader_icd.json"
  "${ANGLE_LIB_DIR}/libEGL.dll.lib"
  "${ANGLE_LIB_DIR}/libGLESv2.dll.lib"
)

# Always recreate staging from the verified archive to prevent stale files.
message(STATUS "Extracting ${ANGLE}...")
file(REMOVE_RECURSE "${ANGLE_SRC}")
file(MAKE_DIRECTORY "${ANGLE_SRC}")

if(SEVENZ_EXECUTABLE)
  message(STATUS "Using 7zip for extraction: ${SEVENZ_EXECUTABLE}")
  execute_process(
    COMMAND "${SEVENZ_EXECUTABLE}" x -y "${ANGLE_ARCHIVE}"
    WORKING_DIRECTORY "${ANGLE_SRC}"
    RESULT_VARIABLE ANGLE_EXTRACT_RESULT
    OUTPUT_VARIABLE ANGLE_EXTRACT_OUTPUT
    ERROR_VARIABLE ANGLE_EXTRACT_ERROR
  )
else()
  message(STATUS "7zip not found, falling back to CMake tar")
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E tar xvf "${ANGLE_ARCHIVE}"
    WORKING_DIRECTORY "${ANGLE_SRC}"
    RESULT_VARIABLE ANGLE_EXTRACT_RESULT
    OUTPUT_VARIABLE ANGLE_EXTRACT_OUTPUT
    ERROR_VARIABLE ANGLE_EXTRACT_ERROR
  )
endif()

if(NOT ANGLE_EXTRACT_RESULT EQUAL 0)
  file(REMOVE_RECURSE "${ANGLE_SRC}")
  message(
    FATAL_ERROR
    "Failed to extract ${ANGLE_ARCHIVE}:\n"
    "${ANGLE_EXTRACT_OUTPUT}\n${ANGLE_EXTRACT_ERROR}"
  )
endif()

file(
  REMOVE
  "${ANGLE_LIB_DIR}/zlib.dll"
  "${ANGLE_LIB_DIR}/libc++.dll"
)

foreach(ANGLE_REQUIRED_FILE IN LISTS ANGLE_REQUIRED_FILES)
  if(NOT EXISTS "${ANGLE_REQUIRED_FILE}")
    file(REMOVE_RECURSE "${ANGLE_SRC}")
    message(
      FATAL_ERROR
      "ANGLE archive is missing required file: ${ANGLE_REQUIRED_FILE}"
    )
  endif()
endforeach()

# ------------------------------------------------------------------------------
set(PLUGIN_NAME "media_kit_libs_windows_video_plugin")

add_library(
  ${PLUGIN_NAME} SHARED
  "include/media_kit_libs_windows_video/media_kit_libs_windows_video_plugin_c_api.h"
  "media_kit_libs_windows_video_plugin_c_api.cpp"
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(
  ${PLUGIN_NAME}
  PROPERTIES
  CXX_VISIBILITY_PRESET
  hidden
)
target_compile_definitions(
  ${PLUGIN_NAME}
  PRIVATE
  FLUTTER_PLUGIN_IMPL
)

target_include_directories(
  ${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
)
target_link_libraries(
  ${PLUGIN_NAME}
  PRIVATE
  flutter
  flutter_wrapper_plugin
)

set(
  media_kit_libs_windows_video_bundled_libraries
  "${LIBMPV_SRC}/libmpv-2.dll"
  "${ANGLE_LIB_DIR}/d3dcompiler_47.dll"
  "${ANGLE_LIB_DIR}/libEGL.dll"
  "${ANGLE_LIB_DIR}/libGLESv2.dll"
  "${ANGLE_LIB_DIR}/vulkan-1.dll"
  "${ANGLE_LIB_DIR}/vk_swiftshader.dll"
  "${ANGLE_LIB_DIR}/vk_swiftshader_icd.json"
  PARENT_SCOPE
)
