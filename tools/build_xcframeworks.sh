#!/usr/bin/env bash

set -e

projectDir=$(cd "$(dirname ${BASH_SOURCE[0]})/.." && pwd)

developmentTeam=T8KNKMR8GY

archivesDir="$projectDir/build/xcode/archives"
xcframeworksDir="$projectDir/build/xcode/xcframeworks"

scheme=CBL_Dart_All
frameworks=(CBLDart CouchbaseLite)
platforms=(iOS "iOS Simulator" macOS)

function buildArchives() {
    for platform in "${platforms[@]}"
    do
        echo Building platform "$platform"
        destination="generic/platform=$platform"
        xcodebuild archive \
            -scheme "$scheme" \
            -destination "$destination" \
            -archivePath "$archivesDir/$scheme-$platform" \
            SKIP_INSTALL=NO \
            BUILD_FOR_DISTRIBUTION=YES \
            DEVELOPMENT_TEAM=$developmentTeam \
            CODE_SIGN_IDENTITY="Apple Development" \
            CODE_SIGN_STYLE=Automatic
    done    
}

function createXcframeworks() {
    for framework in "${frameworks[@]}"
    do
        echo Creating xcframework "$framework"

        frameworksArgs=()
        for platform in "${platforms[@]}"
        do
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

"$@"
