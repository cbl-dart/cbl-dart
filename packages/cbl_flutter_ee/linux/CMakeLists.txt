cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "cbl_flutter_ee")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "cbl_flutter_ee_plugin")

add_library(${PLUGIN_NAME} SHARED
  "cbl_flutter_ee.cc"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)

execute_process(
  COMMAND "${PROJECT_SOURCE_DIR}/../tool/install_libraries.sh" linux-x86_64
  RESULT_VARIABLE INSTALL_LIBRARIES_RESULT
  OUTPUT_VARIABLE INSTALL_LIBRARIES_OUTPUT
  ERROR_VARIABLE INSTALL_LIBRARIES_ERROR
)

if(NOT ${INSTALL_LIBRARIES_RESULT} EQUAL 0)
  message(FATAL_ERROR "Could not install Couchbase Lite native libraries:\n${INSTALL_LIBRARIES_OUTPUT}\n${INSTALL_LIBRARIES_ERROR}")
endif()

file(GLOB cbl_flutter_ee_cbl_libraries "lib/*")

# List of absolute paths to libraries that should be bundled with the plugin
set(cbl_flutter_ee_bundled_libraries
  ${cbl_flutter_ee_cbl_libraries}
  PARENT_SCOPE
)
