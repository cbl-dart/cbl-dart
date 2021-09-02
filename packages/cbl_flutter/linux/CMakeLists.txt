cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "cbl_flutter")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "cbl_flutter_plugin")

add_library(${PLUGIN_NAME} SHARED
  "cbl_flutter_plugin.cc"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${PROJECT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)

# Install libraries into `lib`.
set(INSTALL_LIBRARIES_RESULT 0)
execute_process(
  COMMAND "${PROJECT_SOURCE_DIR}/../tool/install_binaries.sh" "linux" 
  RESULT_VARIABLE INSTALL_LIBRARIES_RESULT
)
if(NOT ${INSTALL_LIBRARIES_RESULT} EQUAL 0)
  message(FATAL_ERROR "Failed to install Couchbase Lite libraries.")
endif()

set(cbl_libraries
  "${PROJECT_SOURCE_DIR}/lib/libcblite.so"
  "${PROJECT_SOURCE_DIR}/lib/libcblite.so.3"
  "${PROJECT_SOURCE_DIR}/lib/libcblite.so.3.0.0"
  "${PROJECT_SOURCE_DIR}/lib/libcblitedart.so"
)

if(NOT ${CMAKE_BUILD_TYPE} STREQUAL "Release")
  list(APPEND cbl_libraries
    "${PROJECT_SOURCE_DIR}/lib/libcblite.so.3.0.0.sym"
    "${PROJECT_SOURCE_DIR}/lib/libcblitedart.so.sym"
  )
endif()

# List of absolute paths to libraries that should be bundled with the plugin
set(cbl_flutter_bundled_libraries
  ${cbl_libraries}
  PARENT_SCOPE
)
