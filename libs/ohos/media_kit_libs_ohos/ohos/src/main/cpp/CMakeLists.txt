# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(mediakit_libs_ohos)

set(LIBS
    ${CMAKE_CURRENT_SOURCE_DIR}/../../../libs/arm64-v8a/libmpv.so.2)

link_libraries(DART_SHARED_LIB ${LIBS})
