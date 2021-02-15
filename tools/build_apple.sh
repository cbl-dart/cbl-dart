#!/usr/bin/env bash

set -e

# === Parse args ===

cmd="$1"

if [ -z "$cmd" ]; then
    echo "You have to provide a command to run."
    exit 1
fi

# === Constans ===

developmentTeam="$DEVELOPMENT_TEAM"
projectDir=$(cd "$(dirname ${BASH_SOURCE[0]})/.." && pwd)
archivesDir="$projectDir/build/apple/archives"
cblFlutterFrameworksDir="$projectDir/packages/cbl_flutter_apple/Frameworks"

scheme=CBL_Dart_All
frameworks=(CouchbaseLiteDart CouchbaseLite)
declare -A platforms=([ios]=iOS [ios_simulator]="iOS Simulator" [macos]=macOS)

# === Commands ===

function buildPlatform() {
    if [ -z "$developmentTeam" ]; then
        echo "You have to set the DEVELOPMENT_TEAM environment variable."
        exit 1
    fi

    local platformId="$1"
    local platform="${platforms[$platformId]}"

    echo Building platform "$platform"

    local destination="generic/platform=$platform"

    xcodebuild archive \
        -scheme "$scheme" \
        -destination "$destination" \
        -archivePath "$archivesDir/$platformId" \
        SKIP_INSTALL=NO \
        BUILD_FOR_DISTRIBUTION=YES \
        DEVELOPMENT_TEAM=$developmentTeam \
        CODE_SIGN_IDENTITY="Apple Development" \
        CODE_SIGN_STYLE=Manual \
        CMAKE_OPTS="-DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache" \
        CC="/usr/local/opt/ccache/libexec/clang" \
        CXX="/usr/local/opt/ccache/libexec/clang++"
}

function createXcframework() {
    local archivesDir="$1"
    local frameworksDir="$2"
    local framework="$3"

    echo Creating xcframework "$framework"

    local frameworksArgs=()

    for platformId in "${!platforms[@]}"; do
        local archive="$archivesDir/$platformId.xcarchive"

        if [ ! -e "$archive" ]; then
            continue
        fi

        frameworksArgs+=(
            "-framework"
            "$archive/Products/Library/Frameworks/$framework.framework"
            "-debug-symbols"
            "$archive/dSYMs/$framework.framework.dSYM"
        )
    done

    xcodebuild -create-xcframework \
        "${frameworksArgs[@]}" \
        -output "$frameworksDir/$framework.xcframework"
}

function buildAllPlatforms() {
    for platformId in "${!platforms[@]}"; do
        buildPlatform "$platformId"
    done
}

function createXcframeworks() {
    local archivesDir="$1"
    local frameworksDir="$2"

    for framework in "${frameworks[@]}"; do
        createXcframework "$archivesDir" "$frameworksDir" "$framework"
    done
}

"$@"
