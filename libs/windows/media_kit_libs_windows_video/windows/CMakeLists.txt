# This file is a part of media_kit (https://github.com/media-kit/media-kit).
#
# Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
# All rights reserved.
# Use of this source code is governed by MIT license that can be found in the LICENSE file.

cmake_minimum_required(VERSION 3.14)

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

# libmpv archive containing the pre-built shared libraries & headers.
set(LIBMPV "mpv-dev-x86_64-20230924-git-652a1dd.7z")

# Download URL & MD5 hash of the libmpv archive.
set(LIBMPV_URL "https://github.com/media-kit/libmpv-win32-video-build/releases/download/2023-09-24/${LIBMPV}")
set(LIBMPV_MD5 "a832ef24b3a6ff97cd2560b5b9d04cd8")

# Download location of the libmpv archive.
set(LIBMPV_ARCHIVE "${CMAKE_BINARY_DIR}/${LIBMPV}")
set(LIBMPV_SRC "${CMAKE_BINARY_DIR}/libmpv")

download_and_verify(
  ${LIBMPV_URL}
  ${LIBMPV_MD5}
  ${LIBMPV_ARCHIVE}
)

check_directory_exists_and_not_empty(${LIBMPV_SRC} LIBMPV_SRC_VALID)

# Extract the libmpv archive.
if(NOT LIBMPV_SRC_VALID)
  message(STATUS "Extracting ${LIBMPV}...")
  make_directory("${LIBMPV_SRC}")
  add_custom_target("${PROJECT_NAME}_LIBMPV_EXTRACT" ALL)
  add_custom_command(
    TARGET "${PROJECT_NAME}_LIBMPV_EXTRACT"
    COMMAND "${CMAKE_COMMAND}" -E tar xzf "\"${LIBMPV_ARCHIVE}\""
    COMMAND xcopy "\"${LIBMPV_SRC}/include/mpv\"" "\"${LIBMPV_SRC}/mpv\"" /E /H /C /I
    COMMAND rmdir "\"${LIBMPV_SRC}/include\"" /S /Q
    COMMAND ren "\"${LIBMPV_SRC}/mpv\"" "\"include\""
    WORKING_DIRECTORY "${LIBMPV_SRC}"
  )
endif()

# ------------------------------------------------------------------------------

# ANGLE archive containing the pre-built shared libraries & headers.
set(ANGLE "ANGLE.7z")

# Download URL & MD5 hash of the ANGLE archive.
set(ANGLE_URL "https://github.com/alexmercerind/flutter-windows-ANGLE-OpenGL-ES/releases/download/v1.0.0/ANGLE.7z")
set(ANGLE_MD5 "e5be38d0e1c5cbe5f70e53701ea8b6c9")

# Download location of the ANGLE archive.
set(ANGLE_ARCHIVE "${CMAKE_BINARY_DIR}/${ANGLE}")
set(ANGLE_SRC "${CMAKE_BINARY_DIR}/ANGLE")

download_and_verify(
  ${ANGLE_URL}
  ${ANGLE_MD5}
  ${ANGLE_ARCHIVE}
)

check_directory_exists_and_not_empty(${ANGLE_SRC} ANGLE_SRC_VALID)

# Extract the ANGLE archive.
if(NOT ANGLE_SRC_VALID)
  message(STATUS "Extracting ${ANGLE}...")
  make_directory("${ANGLE_SRC}")
  add_custom_target("${PROJECT_NAME}_ANGLE_EXTRACT" ALL)
  add_custom_command(
    TARGET "${PROJECT_NAME}_ANGLE_EXTRACT"
    COMMAND "${CMAKE_COMMAND}" -E tar xzf "\"${ANGLE_ARCHIVE}\""
    WORKING_DIRECTORY "${ANGLE_SRC}"
  )
endif()

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
  "${ANGLE_SRC}/api-ms-win-core-console-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-console-l1-2-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-datetime-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-debug-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-errorhandling-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-fibers-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-file-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-file-l1-2-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-file-l2-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-handle-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-heap-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-interlocked-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-libraryloader-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-localization-l1-2-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-memory-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-namedpipe-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-processenvironment-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-processthreads-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-processthreads-l1-1-1.dll"
  "${ANGLE_SRC}/api-ms-win-core-profile-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-rtlsupport-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-string-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-synch-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-synch-l1-2-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-sysinfo-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-timezone-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-core-util-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-conio-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-convert-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-environment-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-filesystem-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-heap-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-locale-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-math-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-multibyte-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-private-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-process-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-runtime-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-stdio-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-string-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-time-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-crt-utility-l1-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-downlevel-kernel32-l2-1-0.dll"
  "${ANGLE_SRC}/api-ms-win-eventing-provider-l1-1-0.dll"
  "${ANGLE_SRC}/concrt140.dll"
  "${ANGLE_SRC}/d3dcompiler_47.dll"
  "${ANGLE_SRC}/libc++.dll"
  "${ANGLE_SRC}/libEGL.dll"
  "${ANGLE_SRC}/libGLESv2.dll"
  "${ANGLE_SRC}/msvcp140.dll"
  "${ANGLE_SRC}/msvcp140_1.dll"
  "${ANGLE_SRC}/msvcp140_2.dll"
  "${ANGLE_SRC}/msvcp140_atomic_wait.dll"
  "${ANGLE_SRC}/msvcp140_codecvt_ids.dll"
  "${ANGLE_SRC}/ucrtbase.dll"
  "${ANGLE_SRC}/ucrtbased.dll"
  "${ANGLE_SRC}/vccorlib140.dll"
  "${ANGLE_SRC}/vccorlib140d.dll"
  "${ANGLE_SRC}/vcruntime140.dll"
  "${ANGLE_SRC}/vcruntime140d.dll"
  "${ANGLE_SRC}/vcruntime140_1.dll"
  "${ANGLE_SRC}/vcruntime140_1d.dll"
  "${ANGLE_SRC}/vk_swiftshader.dll"
  "${ANGLE_SRC}/vulkan-1.dll"
  "${ANGLE_SRC}/zlib.dll"
  PARENT_SCOPE
)
