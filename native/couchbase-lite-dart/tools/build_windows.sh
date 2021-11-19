#!/usr/bin/env bash

# Script that builds Couchbase Lite Dart on for Windows.
#
# The first argument is the Couchbase Edition (community|enterprise) to build
# for and the second is the build mode (debug|release).

set -e

editions=(community enterprise)
buildModes=(debug release)
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
projectDir="$(cd "$scriptDir/.." && pwd)"
buildDir="$projectDir/build/windows"
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
        cmakeBuildMode=RelWithDebInfo
        ;;
    esac

    echo "Building artifacts"

    rm -rf "$cmakeBuildDir"
    mkdir -p "$cmakeBuildDir"

    cmake \
        -B "$cmakeBuildDir" \
        -G "Visual Studio 16 2019" \
        -DCBL_EDITION="$edition" \
        "$projectDir"

    cmake \
        --build "$cmakeBuildDir" \
        --config "$cmakeBuildMode" \
        --target install
}

function _copyArtifactsToProductDir() {
    echo "Copying artifacts to product directory"

    cp -a "$cmakeBuildDir/install/"* "$productDir"
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

echo "Building Couchbase Lite Dart for Windows against $edition edition in $buildMode mode"

rm -rf "$productDir"
mkdir -p "$productDir"

_build "$edition" "$buildMode"
_copyArtifactsToProductDir
