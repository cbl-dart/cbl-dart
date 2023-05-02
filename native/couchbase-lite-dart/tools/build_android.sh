#!/usr/bin/env bash

# Script that builds Couchbase Lite Dart for Android.
#
# The first argument is the Couchbase Edition (community|enterprise) to build
# for and the second is the build mode (debug|release).

set -e

editions=(community enterprise)
buildModes=(debug release)
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
projectDir="$(cd "$scriptDir/.." && pwd)"
buildDir="$projectDir/build/android"
versionFile="$projectDir/CouchbaseLiteDart.version"
version="$(cat "$versionFile")"
productDir="$buildDir/libcblitedart-$version"
cmakeBuildDir="$buildDir/cmake"
archs=(arm64-v8a armeabi-v7a x86 x86_64)
ndkVersion="23.1.7779620"
cmakeVersion="3.18.1"
defaultSdkLocation=("$HOME/Android/Sdk" "$HOME/Library/Android/sdk")
sdkHome="$ANDROID_HOME"

# Look for Android SDK in default locations
if [ -z "$sdkHome" ]; then
    for location in "${defaultSdkLocation[@]}"; do
        if [ -d "$location" ]; then
            sdkHome="$location"
            break
        fi
    done

    if [ -z "$sdkHome" ]; then
        echo "Could not find Android SDK."
        exit 1
    fi
fi

cmakeDir="${sdkHome}/cmake/${cmakeVersion}/bin"
cmakeBin="${cmakeDir}/cmake"
ninjaBin="${cmakeDir}/ninja"

function _buildArch() {
    local arch="$1"
    local edition="$2"
    local buildMode="$3"
    local cmakeBuildMode=
    case "$buildMode" in
    debug)
        cmakeBuildMode=Debug
        ;;
    release)
        cmakeBuildMode=RelWithDebInfo
        ;;
    esac

    echo "Building artifacts for $arch architectur"

    rm -rf "$cmakeBuildDir"
    mkdir -p "$cmakeBuildDir"

    "$cmakeBin" \
        -B "$cmakeBuildDir" \
        -G Ninja \
        -DCMAKE_BUILD_TYPE="$cmakeBuildMode" \
        -DCMAKE_TOOLCHAIN_FILE="${sdkHome}/ndk/${ndkVersion}/build/cmake/android.toolchain.cmake" \
        -DCMAKE_MAKE_PROGRAM="${ninjaBin}" \
        -DANDROID_NATIVE_API_LEVEL=22 \
        -DANDROID_ABI="$arch" \
        -DCBL_EDITION="$edition" \
        "$projectDir"

    "$cmakeBin" \
        --build "$cmakeBuildDir" \
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

echo "Building Couchbase Lite Dart for Android against $edition edition in $buildMode mode"

rm -rf "$productDir"
mkdir -p "$productDir"

for arch in ${archs[@]}; do
    _buildArch "$arch" "$edition" "$buildMode"
    _copyArtifactsToProductDir
done
