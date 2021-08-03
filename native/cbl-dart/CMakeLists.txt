cmake_minimum_required (VERSION 3.1)
cmake_policy(VERSION 3.1)

project(CouchbaseLite_Dart)

get_filename_component(ROOT_DIR ../ ABSOLUTE)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS
    $<$<CONFIG:Debug>:DEBUG>
)
if(APPLE)
    set(CBL_DART_INSTALL_RPATH "@loader_path")
else()
    set(CBL_DART_INSTALL_RPATH "\${ORIGIN}")
endif()

set(CBL_DART_INCLUDES
    src
    ${ROOT_DIR}/vendor/dart/include
    ${PROJECT_BINARY_DIR}
)

set(CBL_DART_SOURCES 
    src/AsyncCallback.cpp
    src/CBL+Dart.cpp
    src/Fleece+Dart.cpp
    src/Utils.cpp
    ${ROOT_DIR}/vendor/dart/include/dart/dart_api_dl.c
)

add_library(cblitedart
    SHARED 
    ${CBL_DART_SOURCES}
)

set_target_properties(cblitedart 
    PROPERTIES 
    CXX_VISIBILITY_PRESET hidden
    BUILD_WITH_INSTALL_RPATH TRUE
    INSTALL_RPATH ${CBL_DART_INSTALL_RPATH}
)

target_include_directories(cblitedart
    PRIVATE
    ${CBL_DART_INCLUDES}
)

target_link_libraries(cblitedart 
    cblite
)
