#!/usr/bin/env bash

set -e

# === Android SDK ===

sdkHome="$ANDROID_HOME"

# Look for Android SDK in default locations
defaultSdkLocation=("$HOME/Android/Sdk" "$HOME/Library/Android/sdk")

if [ -z "$sdkHome" ]; then
    for location in "${defaultSdkLocation[@]}"; do
        if [ -d "$location" ]; then
            sdkHome="$location"
            break
        fi
    done

    if [ -z "$sdkHome" ]; then
        echo "Could not find Android SDK."
    fi
fi

# === Parse args ===

cmd="$1"

if [ -z "$cmd" ]; then
    echo "You have to provide the command to run as the second argument."
    exit 1
fi

# === Constants ===

projectDir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
buildDir="$projectDir/build/android"
libsDir="$buildDir/libs"
cblFlutterLibsDir="$projectDir/packages/cbl_flutter_android/android/libs"

ndk_ver="22.0.7026061"
cmake_ver="3.10.2.4988404"
cmake_path="${sdkHome}/cmake/${cmake_ver}/bin"

archs=(arm64-v8a armeabi-v7a x86 x86_64)

# === Commands ===

function buildArch() {
    local arch=$1
    local archDir="$buildDir/$arch"

    mkdir -p "$archDir"
    cd "$archDir"

    local options=""

    if command -v ccache >/dev/null 2>&1; then
        echo "Using ccache to speed up build"
        options="$options -DCMAKE_C_COMPILER_LAUNCHER=ccache"
        options="$options -DCMAKE_CXX_COMPILER_LAUNCHER=ccache"
    fi

    "${cmake_path}/cmake" \
        -G Ninja \
        -D CMAKE_TOOLCHAIN_FILE="${sdkHome}/ndk/${ndk_ver}/build/cmake/android.toolchain.cmake" \
        -D CMAKE_MAKE_PROGRAM="${cmake_path}/ninja" \
        -D ANDROID_NATIVE_API_LEVEL=19 \
        -D ANDROID_ABI="$arch" \
        -D CMAKE_BUILD_TYPE=RelWithDebInfo \
        $options \
        ../../..

    "${cmake_path}/cmake" --build . --target CouchbaseLiteDart
}

function copyArchToLibs() {
    local arch=$1
    local buildArchDir="$buildDir/$arch"
    local libsArchDir="$libsDir/$arch"

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
    cp -a "$libsDir/"* "$cblFlutterLibsDir/"
}

function clean() {
    rm -rf "$buildDir"
}

"$cmd"
