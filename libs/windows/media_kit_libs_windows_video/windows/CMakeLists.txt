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

# Find 7zip for extracting the libmpv and ANGLE archives.
find_program(SEVENZ_EXECUTABLE NAMES 7z 7za)

# libmpv 0.41.0 release artifacts.
set(LIBMPV_RELEASE "20261023")
set(LIBMPV_BUILD_DATE "20261023")
set(LIBMPV_REVISION_SHORT "41f6a64506")

if("${FLUTTER_TARGET_PLATFORM}" STREQUAL "windows-x64")
  set(LIBMPV_ARCH "x86_64")
  set(
    LIBMPV_SHA256
    "adc4f9207584eb58b25bda3022db35f3b3e94a17391d56660cfe957e82ac4f03"
  )
elseif("${FLUTTER_TARGET_PLATFORM}" STREQUAL "windows-arm64")
  set(LIBMPV_ARCH "aarch64")
  set(
    LIBMPV_SHA256
    "66b89e6e34d5970f596bb8e4f480b9110652cd3d289b7421e510f1d8fa9c8e8e"
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
  "https://github.com/Carapacik/libmpv-win32-video-cmake/releases/download/${LIBMPV_RELEASE}/${LIBMPV}"
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
  "${LIBMPV_INCLUDE_DIR}/render_gl.h"
  "${LIBMPV_INCLUDE_DIR}/stream_cb.h"
  "${LIBMPV_IMPORT_LIBRARY}"
  "${LIBMPV_RUNTIME_LIBRARY}"
)

# Always recreate staging from the verified archive to prevent stale files.
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

# ANGLE archive containing the pre-built shared libraries & headers.
set(ANGLE_VERSION "8078")
set(ANGLE_REVISION_SHORT "9fe55a5")

if("${FLUTTER_TARGET_PLATFORM}" STREQUAL "windows-x64")
  set(ANGLE_ARCH "x64")
  set(
    ANGLE_SHA256
    "7008390323627647db33eb2112fd4100f46b544389307886db435fe7b10e8a55"
  )
elseif("${FLUTTER_TARGET_PLATFORM}" STREQUAL "windows-arm64")
  set(ANGLE_ARCH "arm64")
  set(
    ANGLE_SHA256
    "f2a2acd39f9d989717d6b6c308230ca0f9f0f2ff4ca082f75836957c4283589b"
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
  "${LIBMPV_RUNTIME_LIBRARY}"
  "${ANGLE_LIB_DIR}/d3dcompiler_47.dll"
  "${ANGLE_LIB_DIR}/libEGL.dll"
  "${ANGLE_LIB_DIR}/libGLESv2.dll"
  "${ANGLE_LIB_DIR}/vulkan-1.dll"
  "${ANGLE_LIB_DIR}/vk_swiftshader.dll"
  "${ANGLE_LIB_DIR}/vk_swiftshader_icd.json"
  PARENT_SCOPE
)
