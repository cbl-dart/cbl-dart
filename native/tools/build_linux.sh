#!/usr/bin/env bash

set -e

# === Constants ===

toolsDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nativeDir="$(cd "$toolsDir/.." && pwd)"
projectDir="$(cd "$nativeDir/.." && pwd)"
buildDir="$projectDir/build/linux"
libDir="$projectDir/build/linux/lib"

# === Commands ===

function clean() {
    rm -rf "$buildDir"
}

function build() {
    local buildMode="${1:-RelWithDebInfo}"
    _configure "$buildMode"
    _build
    _createLinksForDev
}

function _configure() {
    local buildType="$1"

    # If build dir has already been configured, skip configuring it again.
    if [ -d "$buildDir" ]; then
        echo "Skiping configuring build dir"
        return 0
    fi

    CC=clang-10 \
        CXX=clang++-10 \
        cmake \
        -B "$buildDir" \
        -G Ninja \
        -DCMAKE_C_COMPILER_LAUNCHER=ccache \
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
        -DCMAKE_INCLUDE_PATH=/usr/lib/llvm-10 \
        -DCMAKE_BUILD_TYPE="$buildType" \
        "$nativeDir"
}

function _build() {
    cmake --build "$buildDir"
    _copyToLib
}

function _copyToLib() {
    mkdir -p "$libDir"

    cp \
        "$buildDir/cbl-dart/libCouchbaseLiteDart.so" \
        "$buildDir/vendor/couchbase-lite-C/libCouchbaseLiteC.so" \
        "$libDir"
}

function _createLinksForDev() {
    cd "$projectDir/packages/cbl_e2e_tests_standalone_dart"
    rm -f lib
    ln -s "$libDir"
}

"$@"
