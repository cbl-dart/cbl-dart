#!/usr/bin/env bash

# Script that builds Couchbase Lite Dart for iOS.
#
# The first argument is the Couchbase Edition (community|enterprise) to build
# for and the second is the build mode (debug|release).

set -e

editions=(community enterprise)
buildModes=(debug release)
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
projectDir="$(cd "$scriptDir/.." && pwd)"
nativeDir="$(cd "$projectDir/.." && pwd)"
vendorDir="$nativeDir/vendor"
couchbaseLiteCRelease="$(cat "$nativeDir/CouchbaseLiteC.release")"
buildDir="$projectDir/build/ios"
archivesDir="$buildDir/archives"
versionFile="$projectDir/CouchbaseLiteDart.version"
version="$(cat "$versionFile")"
productDir="$buildDir"
scheme="CBL_Dart"
platformIds=(ios ios_simulator)

function _platformFromId() {
    local id="$1"
    case "$id" in
    ios)
        echo 'iOS'
        ;;
    ios_simulator)
        echo 'iOS Simulator'
        ;;
    esac
}

function _configurationFromBuildMode() {
    local buildMode="$1"
    case "$buildMode" in
    debug)
        echo 'Debug'
        ;;
    release)
        echo 'Release'
        ;;
    esac
}

function _linkCouchbaseLiteFramework() {
    local edition="$1"
    local frameworkPath="$vendorDir/couchbase-lite-C-prebuilt/$couchbaseLiteCRelease-$edition-ios/CouchbaseLite.xcframework"

    echo "Setting up to build against Couchbase Lite C $edition edition"

    cd "$projectDir/Xcode"
    ln -F -s "$frameworkPath"
}

function _buildFramework() {
    cd "$projectDir"

    local edition="$1"
    local buildMode="$2"
    local platformId="$3"
    local platform="$(_platformFromId "$platformId")"
    local destination="generic/platform=$platform"
    local configuration="$(_configurationFromBuildMode "$buildMode")"

    echo "Building artifacts for $platform platform"

    xcodebuild archive \
        -scheme "$scheme" \
        -destination "$destination" \
        -configuration "$configuration" \
        -archivePath "$archivesDir/$platformId" \
        CURRENT_PROJECT_VERSION=1 \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        CODE_SIGNING_ALLOWED="NO" |
        xcpretty

    return ${PIPESTATUS[0]}
}

function _buildXcframework() {
    local buildMode="$1"
    local output="$productDir/CouchbaseLiteDart.xcframework"

    echo "Building Xcframework"

    local frameworksArgs=()

    for platformId in "${platformIds[@]}"; do
        local archive="$archivesDir/$platformId.xcarchive"

        if [ ! -e "$archive" ]; then
            continue
        fi

        frameworksArgs+=(
            "-framework"
            "$archive/Products/Library/Frameworks/CouchbaseLiteDart.framework"
        )

        if [[ "$buildMode" == "release" ]]; then
            frameworksArgs+=(
                "-debug-symbols"
                "$archive/dSYMs/CouchbaseLiteDart.framework.dSYM"
            )
        fi
    done

    rm -rf "$output"

    xcodebuild -create-xcframework \
        "${frameworksArgs[@]}" \
        -output "$output" |
        xcpretty

    return ${PIPESTATUS[0]}
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

echo "Building Couchbase Lite Dart for iOS against $edition edition in $buildMode mode"

_linkCouchbaseLiteFramework "$edition"

for platformId in "${platformIds[@]}"; do
    _buildFramework "$edition" "$buildMode" "$platformId"
done

_buildXcframework "$buildMode"
