#!/usr/bin/env bash

# Script that builds Couchbase Lite Dart on UNIX systems with the host as the
# target.
#
# The first argument is the Couchbase Edition (community|enterprise) to build
# for and the second is the build mode (debug|release).

set -e

editions=(community enterprise)
buildModes=(debug release)
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
projectDir="$(cd "$scriptDir/.." && pwd)"
buildDir="$projectDir/build/unix"
versionFile="$projectDir/CouchbaseLiteDart.version"
version="$(cat "$versionFile")"
productDir="$buildDir/libcblitedart-$version"
cmakeBuildDir="$buildDir/cmake"

function _build() {
    local edition="$1"
    local buildMode="$2"
    local cmakeBuildMode=
    case "$buildMode" in
    debug)
        cmakeBuildMode=Debug
        ;;
    release)
        cmakeBuildMode=RelWithDebugInfo
        ;;
    esac

    echo "Building artifacts"

    rm -rf "$cmakeBuildDir"
    mkdir -p "$cmakeBuildDir"

    cmake \
        -B "$cmakeBuildDir" \
        -G Ninja \
        -DCMAKE_BUILD_TYPE="$cmakeBuildMode" \
        -DCBL_EDITION="$edition" \
        "$projectDir"

    cmake \
        --build "$cmakeBuildDir" \
        --target install
}

function _copyArtifactsToProductDir() {
    echo "Copying artifacts to product directory"

    cp -a "$cmakeBuildDir/install/"* "$productDir"
}

function _stripSymbolsLinux() {
    local libraryPath="$1"
    local libraryDir="$(dirname "$libraryPath")"
    local libraryName="$(basename "$libraryPath")"
    local librarySym="$libraryName.sym"
    cd "$libraryDir"
    objcopy --only-keep-debug "$libraryName" "$librarySym"
    strip --strip-unneeded "$libraryName"
    objcopy --add-gnu-debuglink "$librarySym" "$libraryName"
}

function _stripSymbolsMacOS() {
    local libraryPath="$1"
    dsymutil "${libraryPath}" -o "$libraryPath.dSYM"
    strip -x "${libraryPath}"
}

function _stipSymbols() {
    echo "Striping symbols from binaries"

    case "$(uname)" in
    Linux)
        _stripSymbolsLinux "$productDir/lib/"*"/libcblitedart.so.$version"
        ;;
    Darwin)
        _stripSymbolsMacOS "$productDir/lib/libcblitedart.$version.dylib"
        ;;
    esac
}

edition="${1:-community}"
buildMode="${2:-debug}"

if [[ ! " ${editions[*]} " =~ " $edition " ]]; then
    echo "Invalid edition: $edition"
    exit 1
fi

if [[ ! " ${buildModes[*]} " =~ " $buildMode " ]]; then
    echo "Invalid build mode: $buildMode"
    exit 1
fi

echo "Building Couchbase Lite Dart for UNIX against $edition edition in $buildMode mode"

rm -rf "$productDir"
mkdir -p "$productDir"

_build "$edition" "$buildMode"
_copyArtifactsToProductDir

# Since it makes debugging easier and the library is small, we leave debug
# symbols in, for now. With dart's FFI capabilities becoming better, even less
# code will be needed in this library.
# _stipSymbols
