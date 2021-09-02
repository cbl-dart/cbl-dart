cmake_minimum_required (VERSION 3.1)
cmake_policy(VERSION 3.1)

project(Root)

if(CBLDART_STATIC_CXX)
    message(STATUS "Building with static C++ library")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static-libstdc++")
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--exclude-libs=libstdc++")
endif()

add_subdirectory(vendor/couchbase-lite-C)

add_subdirectory(cbl-dart)
