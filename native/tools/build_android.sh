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

toolsDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nativeDir="$(cd "$toolsDir/.." && pwd)"
projectDir="$(cd "$nativeDir/.." && pwd)"
buildDir="$projectDir/build/android"
libDir="$buildDir/lib"
cblFlutterLibDir="$projectDir/packages/cbl_flutter/android/lib"

ndk_ver="21.4.7075529"
cmake_ver="3.18.1"
cmake_path="${sdkHome}/cmake/${cmake_ver}/bin"

archs=(arm64-v8a armeabi-v7a x86 x86_64)

# === Commands ===

function clean() {
    rm -rf "$buildDir"
}

function build() {
    local buildMode="${1:-RelWithDebInfo}"
    _configureAllArchs "$buildMode"
    _buildAllArchs
    _createLinksForDev
}

function _configureAllArchs() {
    local buildType="$1"
    local override="$2"

    for arch in "${archs[@]}"; do
        _configureArch "$arch" "$buildType" "$override"
    done
}

function _buildAllArchs() {
    for arch in "${archs[@]}"; do
        _buildArch "$arch"
    done
}

function _configureArch() {
    local arch=$1
    local buildType="$2"
    local archDir="$buildDir/$arch"

    # If build dir has already been configured, skip configuring it again.
    if [ -d "$archDir" ]; then
        echo "Skiping configuring build dir for $arch"
        return 0
    fi

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
        -DCMAKE_INSTALL_PREFIX="$buildDir/install" \
        -DCMAKE_TOOLCHAIN_FILE="${sdkHome}/ndk/${ndk_ver}/build/cmake/android.toolchain.cmake" \
        -DCMAKE_MAKE_PROGRAM="${cmake_path}/ninja" \
        -DANDROID_NATIVE_API_LEVEL=19 \
        -DANDROID_ABI="$arch" \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        $options \
        "$nativeDir"
}

function _buildArch() {
    local arch=$1
    local archDir="$buildDir/$arch"

    cd "$archDir"

    "${cmake_path}/cmake" --build . --target cblitedart

    _copyArchToLib $arch
}

function _copyArchToLib() {
    local arch=$1
    local buildArchDir="$buildDir/$arch"
    local libArchDir="$libDir/$arch"

    rm -rf "$libArchDir"
    mkdir -p "$libArchDir"

    cp -d \
        "$buildArchDir/cbl-dart/libcblitedart.so" \
        "$buildArchDir/vendor/couchbase-lite-C/libcblite.so"* \
        "$libArchDir"
}

function _createLinksForDev() {
    cd "$projectDir/packages/cbl_flutter/android"
    rm -f lib
    ln -s "$libDir"
}

"$@"
