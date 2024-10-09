# See: https://github.com/flutter/flutter/blob/bc0ec85717de14677a0253814faead368ac2abe8/packages/flutter_tools/templates/app_shared/linux.tmpl/CMakeLists.txt.tmpl
cmake_minimum_required(VERSION 3.20)

set(PROJECT_NAME "gamepads_linux")
project(${PROJECT_NAME} LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)

# This value is used when generating builds using this plugin, so it must not be changed
set(PLUGIN_NAME "${PROJECT_NAME}_plugin")

add_library(${PLUGIN_NAME} SHARED
  "gamepads_linux_plugin.cc"
  "gamepad.h"
  "gamepad.cc"
  "connection_listener.h"
  "connection_listener.cc"
  "utils.h"
  "utils.cc"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden)

# System-level dependencies.
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)
pkg_search_module(GLIB REQUIRED glib-2.0)
include_directories(
  ${GLIB_INCLUDE_DIRS}
  ${CMAKE_CURRENT_SOURCE_DIR}
)
link_directories(
  ${GLIB_LIBRARY_DIRS}
)
target_include_directories(${PLUGIN_NAME} PRIVATE ${GLIB_INCLUDE_DIRS})
target_link_libraries(${PLUGIN_NAME} PRIVATE ${GLIB_LIBRARIES})

target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)

# List of absolute paths to libraries that should be bundled with the plugin
set(gamepads_linux_bundled_libraries "" PARENT_SCOPE)