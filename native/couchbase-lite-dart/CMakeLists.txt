cmake_minimum_required(VERSION 3.12)
cmake_policy(SET CMP0095 OLD)

get_filename_component(NATIVE_DIR ../ ABSOLUTE)

file(READ CouchbaseLiteDart.version CBL_DART_VERSION)

set(CMAKE_OSX_DEPLOYMENT_TARGET 10.15 CACHE STRING "Apple Deployment Target")
set(CMAKE_OSX_ARCHITECTURES x86_64 arm64 CACHE STRING "Apple Target Architectures")

project(CouchbaseLite_Dart VERSION ${CBL_DART_VERSION})

set(CBL_DART_LIB_VERSION ${CouchbaseLite_Dart_VERSION})
set(CBL_DART_API_VERSION ${CouchbaseLite_Dart_VERSION_MAJOR})

if(NOT DEFINED CBL_EDITION)
    set(CBL_EDITION community)
endif()

if(NOT DEFINED CBL_VERSION)
    file(READ ${NATIVE_DIR}/CouchbaseLite.version CBL_VERSION)
endif()

if(${CMAKE_SYSTEM_NAME} STREQUAL Darwin)
    set(CBL_TARGET macos)
elseif(${CMAKE_SYSTEM_NAME} STREQUAL Android)
    set(CBL_TARGET android)
elseif(${CMAKE_SYSTEM_NAME} STREQUAL Linux)
    # The only currently supported Linux target. 
    set(CBL_TARGET ubuntu20.04-x86_64)
endif()

file(GLOB CBL_PREBUILT_DIR  
    ${NATIVE_DIR}/vendor/couchbase-lite-C-prebuilt/${CBL_VERSION}-${CBL_EDITION}-${CBL_TARGET}/libcblite-*
)

find_package(CouchbaseLite 
    REQUIRED
    NO_CMAKE_FIND_ROOT_PATH
    NO_DEFAULT_PATH
    PATHS ${CBL_PREBUILT_DIR}
)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_VISIBILITY_PRESET hidden)
# Ensure that we always build with debug symbols. RelWithDebugInfo with macos
# does not by default. Debug symbols are stripped out in a seperate step.
set(CMAKE_CXX_FLAGS -g)

add_compile_definitions($<$<CONFIG:Debug>:DEBUG>)
if(${CBL_EDITION} STREQUAL enterprise)
    add_compile_definitions(COUCHBASE_ENTERPRISE)
endif()

add_library(cblitedart
    SHARED
    src/AsyncCallback.cpp
    src/CBL+Dart.cpp
    src/Fleece+Dart.cpp
    src/Utils.cpp
    ${NATIVE_DIR}/vendor/dart/include/dart/dart_api_dl.c
)

target_include_directories(cblitedart
    PRIVATE
    include
    src
    ${NATIVE_DIR}/vendor/dart/include
)

set_target_properties(cblitedart 
    PROPERTIES
    VERSION "${CBL_DART_LIB_VERSION}" 
    SOVERSION "${CBL_DART_API_VERSION}"
)

target_link_libraries(cblitedart 
    cblite
)

set(CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR}/install)
install(TARGETS cblitedart
    LIBRARY DESTINATION lib/${CMAKE_LIBRARY_ARCHITECTURE}
)