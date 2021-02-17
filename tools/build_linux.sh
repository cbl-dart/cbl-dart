#!/usr/bin/env bash

set -e

# === Constants ===

scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
projectDir="$(cd "$scriptDir/.." && pwd)"
buildDir="$projectDir/build/linux"
libDir="$projectDir/build/linux/lib"

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

function copyToLib() {
    mkdir -p "$libDir"

    cp \
        "$buildDir/cbl-dart/libCouchbaseLiteDart.so" \
        "$buildDir/vendor/couchbase-lite-C/libCouchbaseLiteC.so" \
        "$libDir"
}

function createLinksForDev() {
    cd "$projectDir/packages/cbl_e2e_tests_standalone_dart"
    rm -f lib
    ln -s "../../build/linux/lib"
}

"$@"
