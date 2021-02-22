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
toolsDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nativeDir="$(cd "$toolsDir/.." && pwd)"
projectDir="$(cd "$nativeDir/.." && pwd)"
archivesDir="$projectDir/build/apple/archives"
xcframeworksDir="$projectDir/build/apple/Xcframeworks"

scheme=CBL_Dart_All
frameworks=(CouchbaseLiteDart CouchbaseLite)
declare -A platforms=([ios]=iOS [ios_simulator]="iOS Simulator" [macos]=macOS)

# === Commands ===

function buildPlatform() {
    if [ -z "$developmentTeam" ]; then
        echo "You have to set the DEVELOPMENT_TEAM environment variable."
        exit 1
    fi

    cd "$nativeDir"

    local platformId="$1"
    local platform="${platforms[$platformId]}"

    echo Building platform "$platform"

    local destination="generic/platform=$platform"

    export CCACHE_SLOPPINESS=include_file_ctime,include_file_mtime,pch_defines,time_macros

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
    local framework="$1"

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
        -output "$xcframeworksDir/$framework.xcframework"
}

function buildAllPlatforms() {
    for platformId in "${!platforms[@]}"; do
        buildPlatform "$platformId"
    done
}

function createXcframeworks() {
    for framework in "${frameworks[@]}"; do
        createXcframework "$framework"
    done
}

function createLinksForDev() {
    cd "$projectDir/packages/cbl_e2e_tests_standalone_dart"
    rm -f Frameworks
    ln -s "$archivesDir/macos.xcarchive/Products/Library/Frameworks"

    cd "$projectDir/packages/cbl_flutter_apple"
    rm -f Xcframeworks
    ln -s "$xcframeworksDir"
}

"$@"
