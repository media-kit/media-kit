cmake_minimum_required(VERSION 3.15)

# ------------------------------------------------------------------------------
function(download_and_verify url sha locationForArchive)
  # Check if the archive exists.
  if(EXISTS "${locationForArchive}")
    file(SHA256 "${locationForArchive}" ARCHIVE_SHA)

    # If SHA256 doesn't match, delete the archive to download again.
    if(NOT sha STREQUAL ARCHIVE_SHA)
      file(REMOVE "${locationForArchive}")
      message(STATUS "MD5 mismatch. File deleted.")
    endif()
  endif()

  # Download the archive if it doesn't exist.
  if(NOT EXISTS "${locationForArchive}")
    message(STATUS "Downloading archive from ${url}...")
    file(DOWNLOAD "${url}" "${locationForArchive}")
    message(STATUS "Downloaded archive to ${locationForArchive}.")

    # Verify SHA256 of the newly downloaded file.
    file(SHA256 "${locationForArchive}" ARCHIVE_SHA)

    if(sha STREQUAL ARCHIVE_SHA)
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

# libmpv archive containing the pre-built shared libraries.
set(LIBMPV "libmpv_aarch64.zip")

# Download URL & SHA256 hash of the libmpv archive.
set(LIBMPV_URL "https://github.com/ErBWs/libmpv-ohos-build/releases/download/20251110/${LIBMPV}")
set(LIBMPV_SHA "5e9c41ef80996c6691f4d860c24278c43933511559d71683f24488a2b5bd6d7d")

# Download location of the libmpv archive.
set(LIBMPV_ARCHIVE "${CMAKE_CURRENT_SOURCE_DIR}/${LIBMPV}")
set(LIBMPV_SRC "${CMAKE_CURRENT_SOURCE_DIR}/../../../libs/arm64-v8a/")

download_and_verify(
  ${LIBMPV_URL}
  ${LIBMPV_SHA}
  ${LIBMPV_ARCHIVE}
)

check_directory_exists_and_not_empty(${LIBMPV_SRC} LIBMPV_SRC_VALID)

# Extract the libmpv archive.
if(NOT LIBMPV_SRC_VALID)
  message(STATUS "Extracting ${LIBMPV}...")
  make_directory("${LIBMPV_SRC}")
  add_custom_target("LIBMPV_EXTRACT" ALL)
  add_custom_command(
    TARGET "LIBMPV_EXTRACT"
    COMMAND "${CMAKE_COMMAND}" -E tar -xf "${LIBMPV_ARCHIVE}"
    WORKING_DIRECTORY "${LIBMPV_SRC}"
  )
endif()
# ------------------------------------------------------------------------------

project(mediakit_libs_ohos)

set(LIBS
    ${CMAKE_CURRENT_SOURCE_DIR}/../../../libs/arm64-v8a/libmpv.so.2)

link_libraries(DART_SHARED_LIB ${LIBS})
