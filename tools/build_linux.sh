#!/usr/bin/env bash

set -e

# === Constants ===

scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
projectDir="$(cd "$scriptDir/.." && pwd)"
buildDir="$projectDir/build/linux"
libsDir="$projectDir/build/linux/libs"

# === Commands ===

function build() {
    export CC=clang-10
    export CXX=clang++-10

    cmake \
        -B "$buildDir" \
        -G Ninja \
        -D CMAKE_C_COMPILER_LAUNCHER=ccache \
        -D CMAKE_CXX_COMPILER_LAUNCHER=ccache \
        -D CMAKE_INCLUDE_PATH=/usr/lib/llvm-10 \
        -D CMAKE_BUILD_TYPE=RelWithDebInfo \
        .

    cmake --build "$buildDir"
}

function copyToLibs() {
    mkdir -p "$libsDir"
    cp "$buildDir/cbl-dart/libCouchbaseLiteDart.so" "$libsDir"
    cp "$buildDir/vendor/couchbase-lite-C/libCouchbaseLiteC.so" "$libsDir"
}

"$@"
