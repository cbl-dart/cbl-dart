#!/usr/bin/env bash

set -e

case "$(uname)" in
MINGW* | CYGWIN* | MSYS*)
    melosBin="melos.bat"
    cbdBin="cbd.bat"
    ;;
*)
    melosBin="melos"
    cbdBin="cbd"
    ;;
esac

editions=(community enterprise)
buildModes=(debug release)
targets=(android ios macos linux-x86_64 windows-x86_64)
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
projectDir="$(cd "$scriptDir/.." && pwd)"
nativeDir="$projectDir/native"
vendorDir="$nativeDir/vendor"
prefetchedPackagesDir="$vendorDir/packages.couchbase.com"
prefetchedPackagesPasswordFile="PREFETCHED_PACKAGES_PASSWORD.txt"
packagesDir="$projectDir/packages"
couchbaseLiteCPrebuiltDir="$nativeDir/vendor/couchbase-lite-C-prebuilt"
couchbaseLiteCRelease="$(cat "$nativeDir/CouchbaseLiteC.release")"
couchbaseLiteDartDir="$nativeDir/couchbase-lite-dart"
couchbaseLiteDartBuildDir="$couchbaseLiteDartDir/build"
couchbaseLiteDartVersion="$(cat "$couchbaseLiteDartDir/CouchbaseLiteDart.version")"
couchbaseLiteVectorSearchRelease="1.0.0"
couchbaseLiteVectorSearchPrebuiltDir="$nativeDir/vendor/couchbase-lite-vector-search-prebuilt"
cblE2eTestsStandaloneDartDir="$packagesDir/cbl_e2e_tests_standalone_dart"
cblE2eTestsStandaloneDartLibDir="$cblE2eTestsStandaloneDartDir/lib"
cblE2eTestsStandaloneDartBinDir="$cblE2eTestsStandaloneDartDir/bin"
cblFlutterLocalDir="$packagesDir/cbl_flutter_local"
cblFlutterLocalAndroidJniLibsDir="$cblFlutterLocalDir/android/src/main/jniLibs"
cblFlutterLocalIosFrameworksDir="$cblFlutterLocalDir/ios/Frameworks"
cblFlutterLocalMacosLibrariesDir="$cblFlutterLocalDir/macos/Libraries"
cblFlutterLocalMacosFrameworksDir="$cblFlutterLocalDir/macos/Frameworks"
cblFlutterLocalLinuxLibDir="$cblFlutterLocalDir/linux/lib"
cblFlutterLocalWindowsBinDir="$cblFlutterLocalDir/windows/bin"

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
            target="linux-x86_64"
            ;;
        Darwin)
            target="macos"
            ;;
        MINGW64* | MSYS* | CYGWIN*)
            target="windows-x86_64"
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

    local os
    case "$target" in
    android)
        os="android"
        ;;
    ios)
        os="iOS"
        ;;
    macos)
        os="macOS"
        ;;
    linux*)
        os="linux"
        ;;
    windows*)
        os="windows"
        ;;
    esac

    "$cbdBin" install-packages \
        --library cblite \
        --edition "$edition" \
        --release "$couchbaseLiteCRelease" \
        --os "$os"

    "$cbdBin" install-packages \
        --library vectorSearch \
        --edition enterprise \
        --release "$couchbaseLiteVectorSearchRelease" \
        --os "$os"

    local couchbaseLiteCArchiveDir="$couchbaseLiteCPrebuiltDir/$couchbaseLiteCRelease-$edition-$target"
    local couchbaseLiteVectorSearchArchiveDir="$couchbaseLiteVectorSearchPrebuiltDir/$couchbaseLiteVectorSearchRelease-$target"

    case "$target" in
    android)
        "$couchbaseLiteDartDir/tools/build_android.sh" "$edition" "$buildMode"

        echo "Copying libraries to cbl_flutter_local"
        rm -rf "$cblFlutterLocalAndroidJniLibsDir"
        mkdir -p "$cblFlutterLocalAndroidJniLibsDir"
        cp -a "$couchbaseLiteCArchiveDir/libcblite-"*"/lib/"* "$cblFlutterLocalAndroidJniLibsDir"
        cp -a "$couchbaseLiteDartBuildDir/android/libcblitedart-"*"/lib/"* "$cblFlutterLocalAndroidJniLibsDir"
        rm -rf "$cblFlutterLocalAndroidJniLibsDir/"*"/cmake"
        mv "$cblFlutterLocalAndroidJniLibsDir/aarch64-linux-android" "$cblFlutterLocalAndroidJniLibsDir/arm64-v8a"
        mv "$cblFlutterLocalAndroidJniLibsDir/arm-linux-androideabi" "$cblFlutterLocalAndroidJniLibsDir/armeabi-v7a"
        mv "$cblFlutterLocalAndroidJniLibsDir/i686-linux-android" "$cblFlutterLocalAndroidJniLibsDir/x86"
        mv "$cblFlutterLocalAndroidJniLibsDir/x86_64-linux-android" "$cblFlutterLocalAndroidJniLibsDir/x86_64"
        cp -a "$couchbaseLiteVectorSearchArchiveDir-arm64/lib/"* "$cblFlutterLocalAndroidJniLibsDir/arm64-v8a"
        cp -a "$couchbaseLiteVectorSearchArchiveDir-x86_64/lib/"* "$cblFlutterLocalAndroidJniLibsDir/x86_64"
        ;;
    ios)
        "$couchbaseLiteDartDir/tools/build_ios.sh" "$edition" "$buildMode"

        echo "Copying libraries to cbl_flutter_local"
        rm -rf "$cblFlutterLocalIosFrameworksDir"
        mkdir -p "$cblFlutterLocalIosFrameworksDir"
        cp -a "$couchbaseLiteCArchiveDir/CouchbaseLite.xcframework"* "$cblFlutterLocalIosFrameworksDir"
        cp -a "$couchbaseLiteDartBuildDir/ios/CouchbaseLiteDart.xcframework"* "$cblFlutterLocalIosFrameworksDir"
        cp -a "$couchbaseLiteVectorSearchArchiveDir/CouchbaseLiteVectorSearch.xcframework"* "$cblFlutterLocalIosFrameworksDir"
        ;;
    macos)
        "$couchbaseLiteDartDir/tools/build_unix.sh" "$edition" "$buildMode"

        echo "Copying libraries to cbl_e2e_tests_standalone_dart"
        rm -rf "$cblE2eTestsStandaloneDartLibDir"
        mkdir -p "$cblE2eTestsStandaloneDartLibDir"
        cp -a "$couchbaseLiteCArchiveDir/libcblite-"*"/lib/libcblite"* "$cblE2eTestsStandaloneDartLibDir"
        cp -a "$couchbaseLiteDartBuildDir/unix/libcblitedart-"*"/lib/libcblitedart"* "$cblE2eTestsStandaloneDartLibDir"
        cp -a "$couchbaseLiteVectorSearchArchiveDir/"* "$cblE2eTestsStandaloneDartLibDir"

        echo "Copying libraries to cbl_flutter_local"
        rm -rf "$cblFlutterLocalMacosLibrariesDir"
        mkdir -p "$cblFlutterLocalMacosLibrariesDir"
        mkdir -p "$cblFlutterLocalMacosFrameworksDir"
        cp -L "$couchbaseLiteCArchiveDir/libcblite-"*"/lib/libcblite."?".dylib" "$cblFlutterLocalMacosLibrariesDir"
        cp -L "$couchbaseLiteDartBuildDir/unix/libcblitedart-"*"/lib/libcblitedart."?".dylib" "$cblFlutterLocalMacosLibrariesDir"
        cp -a "$couchbaseLiteVectorSearchArchiveDir/"* "$cblFlutterLocalMacosFrameworksDir"
        ;;
    linux-x86_64)
        "$couchbaseLiteDartDir/tools/build_unix.sh" "$edition" "$buildMode"

        echo "Copying libraries to cbl_e2e_tests_standalone_dart"
        rm -rf "$cblE2eTestsStandaloneDartLibDir"
        mkdir -p "$cblE2eTestsStandaloneDartLibDir"
        cp -a "$couchbaseLiteCArchiveDir/libcblite-"*"/lib/x86_64-linux-gnu/libcblite"* "$cblE2eTestsStandaloneDartLibDir"
        cp -a "$couchbaseLiteDartBuildDir/unix/libcblitedart-"*"/lib/x86_64-linux-gnu/libcblitedart"* "$cblE2eTestsStandaloneDartLibDir"
        cp -a "$couchbaseLiteVectorSearchArchiveDir/lib/"* "$cblE2eTestsStandaloneDartLibDir"

        echo "Copying libraries to cbl_flutter_local"
        rm -rf "$cblFlutterLocalLinuxLibDir"
        mkdir -p "$cblFlutterLocalLinuxLibDir"
        cp -a "$couchbaseLiteCArchiveDir/libcblite-"*"/lib/x86_64-linux-gnu/libcblite"* "$cblFlutterLocalLinuxLibDir"
        cp -a "$couchbaseLiteDartBuildDir/unix/libcblitedart-"*"/lib/x86_64-linux-gnu/libcblitedart"* "$cblFlutterLocalLinuxLibDir"
        cp -a "$couchbaseLiteVectorSearchArchiveDir/lib/"* "$cblFlutterLocalLinuxLibDir"
        ;;
    windows-x86_64)
        "$couchbaseLiteDartDir/tools/build_windows.sh" "$edition" "$buildMode"

        echo "Copying libraries to cbl_e2e_tests_standalone_dart"
        rm -rf "$cblE2eTestsStandaloneDartBinDir"
        mkdir -p "$cblE2eTestsStandaloneDartBinDir"
        cp -a "$couchbaseLiteCArchiveDir/libcblite-"*"/bin/cblite"* "$cblE2eTestsStandaloneDartBinDir"
        cp -a "$couchbaseLiteDartBuildDir/windows/libcblitedart-"*"/bin/cblitedart"* "$cblE2eTestsStandaloneDartBinDir"
        cp -a "$couchbaseLiteVectorSearchArchiveDir/bin/"* "$cblE2eTestsStandaloneDartBinDir"

        echo "Copying libraries to cbl_flutter_local"
        rm -rf "$cblFlutterLocalWindowsBinDir"
        mkdir -p "$cblFlutterLocalWindowsBinDir"
        cp -L "$couchbaseLiteCArchiveDir/libcblite-"*"/bin/cblite"* "$cblFlutterLocalWindowsBinDir"
        cp -L "$couchbaseLiteDartBuildDir/windows/libcblitedart-"*"/bin/cblitedart"* "$cblFlutterLocalWindowsBinDir"
        cp -L "$couchbaseLiteVectorSearchArchiveDir/bin/"* "$cblFlutterLocalWindowsBinDir"
        ;;
    esac
}

function packPrefetchedPackages() {
    local PREFETCHED_PACKAGES_PASSWORD="$1"
    if [[ -z "$PREFETCHED_PACKAGES_PASSWORD" ]]; then
        echo "PREFETCHED_PACKAGES_PASSWORD is not set"
        exit 1
    fi

    echo "Archiving pre-fetched packages"
    (cd "$vendorDir" && zip -r "$prefetchedPackagesDir.zip" "$(basename "$prefetchedPackagesDir")")

    echo "Encrypting pre-fetched packages"
    echo "$PREFETCHED_PACKAGES_PASSWORD" >"$prefetchedPackagesPasswordFile"
    openssl enc -aes-256-cbc -pbkdf2 -salt -pass "file:$prefetchedPackagesPasswordFile" \
        -in "$prefetchedPackagesDir.zip" \
        -out "$prefetchedPackagesDir.zip.enc"
    rm "$prefetchedPackagesPasswordFile"
    rm "$prefetchedPackagesDir.zip"
}

function unpackPrefetchedPackages() {
    local PREFETCHED_PACKAGES_PASSWORD="$1"
    if [[ -z "$PREFETCHED_PACKAGES_PASSWORD" ]]; then
        echo "PREFETCHED_PACKAGES_PASSWORD is not set"
        exit 1
    fi

    echo "Decrypting pre-fetched packages"
    echo "$PREFETCHED_PACKAGES_PASSWORD" >"$prefetchedPackagesPasswordFile"
    openssl enc -aes-256-cbc -pbkdf2 -d -pass "file:$prefetchedPackagesPasswordFile" \
        -in "$prefetchedPackagesDir.zip.enc" \
        -out "$prefetchedPackagesDir.zip"
    rm "$prefetchedPackagesPasswordFile"

    echo "Unpacking pre-fetched packages"
    unzip "$prefetchedPackagesDir.zip" -d "$vendorDir"
    rm "$prefetchedPackagesDir.zip"
}

function bootstrap() {
    if [[ -f "$prefetchedPackagesDir.zip.enc" && -n "$PREFETCHED_PACKAGES_PASSWORD" && ! -d "$prefetchedPackagesDir" ]]; then
        unpackPrefetchedPackages "$PREFETCHED_PACKAGES_PASSWORD"
    fi

    $melosBin bootstrap
}

"$@"
