#!/usr/bin/env bash

set -e

projectDir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
buildDir="$projectDir/build/android"
libsDir="$buildDir/libs"
cblFlutterLibsDir="$projectDir/packages/cbl_flutter_android/android/libs"

SDK_HOME=/Users/gabriel/Library/Android/sdk
NDK_VER="22.0.7026061"
CMAKE_VER="3.10.2.4988404"
CMAKE_PATH="${SDK_HOME}/cmake/${CMAKE_VER}/bin" 

archs=(arm64-v8a armeabi-v7a x86 x86_64)

function buildArch()  {
    arch=$1
    archDir="$buildDir/$arch"
    mkdir -p "$archDir"
    cd "$archDir"

    "${CMAKE_PATH}/cmake" \
        -G Ninja \
        -DCMAKE_TOOLCHAIN_FILE="${SDK_HOME}/ndk/${NDK_VER}/build/cmake/android.toolchain.cmake" \
        -DCMAKE_MAKE_PROGRAM="${CMAKE_PATH}/ninja" \
        -DANDROID_NATIVE_API_LEVEL=19 \
        -DANDROID_ABI="$arch" \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        ../../..

    "${CMAKE_PATH}/cmake" --build . --target CouchbaseLiteDart
}

function copyArchToLibs() {
    arch=$1
    buildArchDir="$buildDir/$arch"
    libsArchDir="$libsDir/$arch"

    rm -rf "$libsArchDir"
    mkdir -p "$libsArchDir"
    
    cp "$buildArchDir/cbl-dart/libCouchbaseLiteDart.so" "$libsArchDir/libCouchbaseLiteDart.so"
    cp "$buildArchDir/vendor/couchbase-lite-C/libCouchbaseLiteC.so" "$libsArchDir/libCouchbaseLiteC.so"
}

function buildAllArchs() {
    for arch in "${archs[@]}"; do
        buildArch "$arch"
    done
}

function copyAllArchsToLibs() {
    for arch in "${archs[@]}"; do
        copyArchToLibs "$arch"
    done
}

function copyLibsToCblFlutter() {
    rm -rf "$cblFlutterLibsDir"
    mkdir -p "$cblFlutterLibsDir"
    cp -a "$libsDir/" "$cblFlutterLibsDir/"
}

function clean() {
    rm -rf "$buildDir"
}

"$@"
