#!/usr/bin/env bash

set -e

# === Environment ===

developmentTeam="$DEVELOPMENT_TEAM"

if [ -z "$developmentTeam" ]; then
    echo "You have to set the DEVELOPMENT_TEAM environment variable."
    exit 1
fi

# === Parse args ===

cmd="$1"

if [ -z "$cmd" ]; then
    echo "You have to provide a command to run."
    exit 1
fi

# === Constans ===

projectDir=$(cd "$(dirname ${BASH_SOURCE[0]})/.." && pwd)
archivesDir="$projectDir/build/xcode/archives"
xcframeworksDir="$projectDir/build/xcode/xcframeworks"
cblFlutterFrameworksDir="$projectDir/packages/cbl_flutter_apple/Frameworks"

scheme=CBL_Dart_All
frameworks=(CouchbaseLiteDart CouchbaseLite)
platforms=(iOS "iOS Simulator" macOS)

# === Commands ===

function buildArchives() {
    for platform in "${platforms[@]}"; do
        echo Building platform "$platform"

        local destination="generic/platform=$platform"

        xcodebuild archive \
            -scheme "$scheme" \
            -destination "$destination" \
            -archivePath "$archivesDir/$scheme-$platform" \
            SKIP_INSTALL=NO \
            BUILD_FOR_DISTRIBUTION=YES \
            DEVELOPMENT_TEAM=$developmentTeam \
            CODE_SIGN_IDENTITY="Apple Development" \
            CODE_SIGN_STYLE=Manual \
            CMAKE_OPTS="-DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache" \
            CC="/usr/local/opt/ccache/libexec/clang" \
            CXX="/usr/local/opt/ccache/libexec/clang++"
    done
}

function createXcframeworks() {
    for framework in "${frameworks[@]}"; do
        echo Creating xcframework "$framework"

        local frameworksArgs=()

        for platform in "${platforms[@]}"; do
            frameworksArgs+=(
                "-framework"
                "$archivesDir/$scheme-$platform.xcarchive/Products/Library/Frameworks/$framework.framework"
                "-debug-symbols"
                "$archivesDir/$scheme-$platform.xcarchive/dSYMs/$framework.framework.dSYM"
            )
        done

        xcodebuild -create-xcframework \
            "${frameworksArgs[@]}" \
            -output "$xcframeworksDir/$framework.xcframework"
    done
}

function copyToCblFlutter() {
    rm -rf "$cblFlutterFrameworksDir"
    mkdir -p "$cblFlutterFrameworksDir"

    for framework in "${frameworks[@]}"; do
        local srcPath="$xcframeworksDir/$framework.xcframework"

        cp -a "$srcPath" "$cblFlutterFrameworksDir"
    done
}

"$cmd"
