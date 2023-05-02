#!/usr/bin/env bash

# Script that builds release archives of Couchbase Lite Dart.
#
# The first argument is the version of the release and the second is the target
# to build a release for.

set -e

TAR=tar

case "$(uname -s)" in
MINGW* | CYGWIN* | MSYS*)
    # Use bsd tar, which comes with Windows 10 and not gnu tar from git-bash.
    TAR="$SYSTEMROOT\system32\tar.exe"
    ;;
esac

scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
projectDir="$(cd "$scriptDir/.." && pwd)"
buildDir="$projectDir/build/release"
editions=(community enterprise)
targets=(android ios macos linux-x86_64 windows-x86_64)

function _buildArchive() {
    local edition="$1"
    local release="$2"
    local targetBuildDir=
    local productDirPrefix="libcblitedart-"
    local archiveExt=zip

    echo "Building release archive for $edition edition"

    cd "$projectDir"

    case "$target" in
    android)
        ./tools/build_android.sh "$edition" release
        targetBuildDir="$projectDir/build/android"
        ;;
    macos)
        ./tools/build_unix.sh "$edition" release
        targetBuildDir="$projectDir/build/unix"
        ;;
    ios)
        ./tools/build_ios.sh "$edition" release
        targetBuildDir="$projectDir/build/ios"
        productDirPrefix="CouchbaseLiteDart.xcframework"
        ;;
    linux-x86_64)
        ./tools/build_unix.sh "$edition" release
        targetBuildDir="$projectDir/build/unix"
        archiveExt=tar.gz
        ;;
    windows-x86_64)
        ./tools/build_windows.sh "$edition" release
        targetBuildDir="$projectDir/build/windows"
        ;;
    esac

    local archiveFile="$buildDir/couchbase-lite-dart-$release-$edition-$target.$archiveExt"

    rm -f "$archiveFile"

    cd "$targetBuildDir"

    case "$archiveExt" in
    zip)
        case "$(uname -s)" in
        MINGW* | CYGWIN* | MSYS*)
            # Windows 10 does not have zip available, but has bsdtar which can
            # create zip archives.
            $TAR -caf "$archiveFile" "$productDirPrefix"*
            ;;
        *)
            zip -r "$archiveFile" "$productDirPrefix"*
            ;;
        esac
        ;;
    tar.gz)
        $TAR -czf "$archiveFile" "$productDirPrefix"*
        ;;
    *)
        echo "Unknown archive extension: $archiveExt"
        exit 1
        ;;
    esac
}

release="$1"
target="$2"

if [[ -z "$release" ]]; then
    echo "Please provide a name for this release"
    exit 1
fi

if [[ ! " ${targets[*]} " =~ " $target " ]]; then
    echo "Invalid target: $target"
    exit 1
fi

echo "Building Couchbase Lite Dart release $release for $target"

mkdir -p "$buildDir"

for edition in ${editions[@]}; do
    _buildArchive "$edition" "$release"
done
