#!/usr/bin/env bash

set -e

editions=(community enterprise)
buildModes=(debug release)
targets=(android ios macos ubuntu20.04-x86_64)
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
projectDir="$(cd "$scriptDir/.." && pwd)"
nativeDir="$projectDir/native"
couchbaseLiteCPrebuiltDir="$nativeDir/vendor/couchbase-lite-C-prebuilt"
couchbaseLiteDartDir="$nativeDir/couchbase-lite-dart"
couchbaseLiteDartBuildDir="$couchbaseLiteDartDir/build"
couchbaseLiteVersion="$(cat "$nativeDir/CouchbaseLite.version")"
couchbaseLiteDartVersion="$(cat "$couchbaseLiteDartDir/CouchbaseLiteDart.version")"
cblE2eTestsStandaloneDartDir="$projectDir/packages/cbl_e2e_tests_standalone_dart"
cblE2eTestsStandaloneDartLibDir="$cblE2eTestsStandaloneDartDir/lib"
cblFlutterDir="$projectDir/packages/cbl_flutter"
cblFlutterAndroidLibDir="$cblFlutterDir/android/lib"
cblFlutterXcframeworksDir="$cblFlutterDir/Xcframeworks"
cblFlutterLinuxLibDir="$cblFlutterDir/linux/lib"

function prepareNativeLibraries() {
    local edition="${1:-enterprise}"
    local buildMode="${2:-debug}"
    local target="$3"

    if [[ ! " ${editions[*]} " =~ " $edition " ]]; then
        echo "Invalid edition: $edition"
        exit 1
    fi

    if [[ ! " ${buildModes[*]} " =~ " $buildMode " ]]; then
        echo "Invalid build mode: $buildMode"
        exit 1
    fi

    # If no target is given, use the host as the target.
    if [[ -z "$target" ]]; then
        case "$(uname)" in
        Linux)
            target="ubuntu20.04-x86_64"
            ;;
        Darwin)
            target="macos"
            ;;
        *)
            echo "Unsupported host platform: $(uname)"
            exit 1
            ;;
        esac
    fi

    if [[ ! " ${targets[*]} " =~ " $target " ]]; then
        echo "Invalid target: $target"
        exit 1
    fi

    "$nativeDir/tools/download_prebuilt_binaries.sh" "$target"

    local couchbaseLiteCArchiveDir="$couchbaseLiteCPrebuiltDir/$couchbaseLiteVersion-$edition-$target"

    case "$target" in
    android)
        "$couchbaseLiteDartDir/tools/build_android.sh" "$edition" "$buildMode"

        # Copy Couchbase Lite C + Dart binaries to cbl_flutter/android
        rm -rf "$cblFlutterAndroidLibDir"
        mkdir -p "$cblFlutterAndroidLibDir"
        cp -a "$couchbaseLiteCArchiveDir/libcblite-"*"/lib/"* "$cblFlutterAndroidLibDir"
        cp -a "$couchbaseLiteDartBuildDir/android/libcblitedart-"*"/lib/"* "$cblFlutterAndroidLibDir"
        mv "$cblFlutterAndroidLibDir/aarch64-linux-android" "$cblFlutterAndroidLibDir/arm64-v8a"
        mv "$cblFlutterAndroidLibDir/arm-linux-androideabi" "$cblFlutterAndroidLibDir/armeabi-v7a"
        mv "$cblFlutterAndroidLibDir/i686-linux-android" "$cblFlutterAndroidLibDir/x86"
        mv "$cblFlutterAndroidLibDir/x86_64-linux-android" "$cblFlutterAndroidLibDir/x86_64"
        ;;
    ios)
        "$couchbaseLiteDartDir/tools/build_ios.sh" "$edition" "$buildMode"

        # Copy Couchbase Lite C + Dart binaries to cbl_flutter/Xcframeworks
        rm -rf "$cblFlutterXcframeworksDir"
        mkdir -p "$cblFlutterXcframeworksDir"
        cp -a "$couchbaseLiteCArchiveDir/CouchbaseLite.xcframework"* "$cblFlutterXcframeworksDir"
        cp -a "$couchbaseLiteDartBuildDir/CouchbaseLiteDart.xcframework"* "$cblFlutterXcframeworksDir"
        ;;
    macos)
        "$couchbaseLiteDartDir/tools/build_unix.sh" "$edition" "$buildMode"

        # Copy Couchbase Lite C + Dart binaries to standalone dart test package
        rm -rf "$cblE2eTestsStandaloneDartLibDir"
        mkdir -p "$cblE2eTestsStandaloneDartLibDir"
        cp -a "$couchbaseLiteCArchiveDir/libcblite-"*"/lib/libcblite"* "$cblE2eTestsStandaloneDartLibDir"
        cp -a "$couchbaseLiteDartBuildDir/unix/libcblitedart-"*"/lib/libcblitedart"* "$cblE2eTestsStandaloneDartLibDir"

        # TODO flutter
        ;;
    ubuntu20.04-x86_64)
        "$couchbaseLiteDartDir/tools/build_unix.sh" "$edition" "$buildMode"

        # Copy Couchbase Lite C + Dart binaries to standalone dart test package
        rm -rf "$cblE2eTestsStandaloneDartLibDir"
        mkdir -p "$cblE2eTestsStandaloneDartLibDir"
        cp -a "$couchbaseLiteCArchiveDir/libcblite-"*"/lib/x86_64-linux-gnu/libcblite"* "$cblE2eTestsStandaloneDartLibDir"
        cp -a "$couchbaseLiteDartBuildDir/unix/libcblitedart-"*"/lib/x86_64-linux-gnu/libcblitedart"* "$cblE2eTestsStandaloneDartLibDir"

        # TODO flutter
        ;;
    esac
}

"$@"
