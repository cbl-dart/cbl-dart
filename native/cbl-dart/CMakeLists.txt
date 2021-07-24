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

set(CBL_DART_INCLUDES
    src
    ${ROOT_DIR}/vendor/dart/include
    ${ROOT_DIR}/vendor/couchbase-lite-C/include
    ${ROOT_DIR}/vendor/couchbase-lite-C/vendor/couchbase-lite-core/vendor/fleece/API
    ${PROJECT_BINARY_DIR}
)

set(CBL_DART_SOURCES 
    src/AsyncCallback.cpp
    src/CBL+Dart.cpp
    src/Fleece+Dart.cpp
    src/Utils.cpp
    ${ROOT_DIR}/vendor/dart/include/dart/dart_api_dl.c
)

add_library(CouchbaseLiteDart
    SHARED 
    ${CBL_DART_SOURCES}
)

set_target_properties(CouchbaseLiteDart 
    PROPERTIES 
    CXX_VISIBILITY_PRESET hidden
    BUILD_WITH_INSTALL_RPATH TRUE
    INSTALL_RPATH "\${ORIGIN}"
)

target_include_directories(CouchbaseLiteDart
    PRIVATE
    ${CBL_DART_INCLUDES}
)

target_link_libraries(CouchbaseLiteDart 
    CouchbaseLiteC
)
