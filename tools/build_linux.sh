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
        -DCMAKE_C_COMPILER_LAUNCHER=ccache \
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
        -DCMAKE_INCLUDE_PATH=/usr/lib/llvm-10 \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        .

    cmake --build "$buildDir"
}

function copyToLibs() {
    mkdir -p "$libsDir"
    cp "$buildDir/cbl-dart/libCouchbaseLiteDart.so" "$libsDir"
    cp "$buildDir/vendor/couchbase-lite-C/libCouchbaseLiteC.so" "$libsDir"
}

"$@"
