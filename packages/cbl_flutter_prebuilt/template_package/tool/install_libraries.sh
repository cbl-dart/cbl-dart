#!/usr/bin/env bash

set -e

error() {
    local sourceFile=$1
    local lineno=$2
    echo "Error in line $lineno in file $sourceFile"
}

trap 'error "${BASH_SOURCE[0]}" "${LINENO}"' ERR

TAR="tar"

case "$(uname)" in
MINGW* | CYGWIN* | MSYS*)
    # Use bsd tar, which comes with Windows 10 and not gnu tar from git-bash.
    TAR="$SYSTEMROOT\system32\tar.exe"
    ;;
esac

targets=(android ios macos linux-x86_64 windows-x86_64)
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
packageDir="$(cd "$scriptDir/.." && pwd)"
androidJniLibsDir="$packageDir/android/src/main/jniLibs"
iosFrameworksDir="$packageDir/ios/Frameworks"
macosLibrariesDir="$packageDir/macos/Libraries"
linuxLibDir="$packageDir/linux/lib"
windowsBinDir="$packageDir/windows/bin"

source "$scriptDir/library_versions"

function _installDir() {
    local target="$1"

    case "$target" in
    android)
        echo "$androidJniLibsDir"
        ;;
    ios)
        echo "$iosFrameworksDir"
        ;;
    macos)
        echo "$macosLibrariesDir"
        ;;
    linux*)
        echo "$linuxLibDir"
        ;;
    windows*)
        echo "$windowsBinDir"
        ;;
    esac
}

function _librariesAreInstalled() {
    local target="$1"

    if [ -d "$(_installDir "$target")" ]; then
        return 0
    fi

    return 1
}

# Outputs the extension of the archives for the given target.
function _archiveExt() {
    local target="$1"

    case "$target" in
    linux*)
        echo tar.gz
        ;;
    *)
        echo zip
        ;;

    esac
}

# Outputs the URL of the archive for the given edition, release and
# target of Couchbase Lite C.
function _couchbaseLiteCDownloadUrl() {
    local edition="$1"
    local release="$2"
    local target="$3"
    echo "https://packages.couchbase.com/releases/couchbase-lite-c/$release/couchbase-lite-c-$edition-$release-$target.$(_archiveExt $target)"
}

# Outputs the URL of the archive for the given edition, release and
# target of Couchbase Lite Dart.
function _couchbaseLiteDartDownloadUrl() {
    local edition="$1"
    local release="$2"
    local target="$3"
    echo "https://github.com/cbl-dart/cbl-dart/releases/download/libcblitedart-v$release/couchbase-lite-dart-$release-$edition-$target.$(_archiveExt $target)"
}

target="$1"

if [[ ! " ${targets[*]} " =~ " $target " ]]; then
    echo "Invalid target: $target"
    exit 1
fi

if _librariesAreInstalled "$target"; then
    echo "Native libraries for Couchbase Lite for $target are already installed"
    exit 0
fi

echo "Installing native libraries for Couchbase Lite for $target"

# Create a tmp dir
tmpDir="$(mktemp -d 2>/dev/null || mktemp -d -t 'cbl_flutter_prebuilt')"

# Download archives
couchbaseLiteCArchiveFile="$tmpDir/couchbase-lite-c.$(_archiveExt "$target")"
couchbaseLiteDartArchiveFile="$tmpDir/couchbase-lite-dart.$(_archiveExt "$target")"

curl "$(
    _couchbaseLiteCDownloadUrl \
        "$COUCHBASE_EDITION" \
        "$COUCHBASE_LITE_C_RELEASE" \
        "$target"
)" \
    --silent \
    --fail \
    --retry 5 \
    --retry-max-time 30 \
    --output "$couchbaseLiteCArchiveFile"

curl "$(
    _couchbaseLiteDartDownloadUrl \
        "$COUCHBASE_EDITION" \
        "$COUCHBASE_LITE_DART_RELEASE" \
        "$target"
)" \
    --location \
    --silent \
    --fail \
    --retry 5 \
    --retry-max-time 30 \
    --output "$couchbaseLiteDartArchiveFile"

# Unpack archives
case "$(_archiveExt $target)" in
zip)
    case "$(uname -s)" in
    MINGW* | CYGWIN* | MSYS*)
        # Windows 10 does not have unzip available, but has bsdtar which can
        # unpack zip archives.
        $TAR -xf "$couchbaseLiteCArchiveFile" -C "$tmpDir"
        $TAR -xf "$couchbaseLiteDartArchiveFile" -C "$tmpDir"
        ;;
    *)
        unzip -q "$couchbaseLiteCArchiveFile" -d "$tmpDir"
        unzip -q "$couchbaseLiteDartArchiveFile" -d "$tmpDir"
        ;;
    esac
    ;;
tar.gz)
    $TAR -xzf "$couchbaseLiteCArchiveFile" -C "$tmpDir"
    $TAR -xzf "$couchbaseLiteDartArchiveFile" -C "$tmpDir"
    ;;
esac

# Move archives into platform directory
tmpInstallDir="$tmpDir/installDir"
mkdir "$tmpInstallDir"

case "$target" in
android)
    cp -a "$tmpDir/libcblite-$COUCHBASE_LITE_C_VERSION/lib/"* "$tmpInstallDir"
    cp -a "$tmpDir/libcblitedart-$COUCHBASE_LITE_DART_VERSION/lib/"* "$tmpInstallDir"
    rm -rf "$tmpInstallDir/"*"/cmake"
    mv "$tmpInstallDir/aarch64-linux-android" "$tmpInstallDir/arm64-v8a"
    mv "$tmpInstallDir/arm-linux-androideabi" "$tmpInstallDir/armeabi-v7a"
    mv "$tmpInstallDir/i686-linux-android" "$tmpInstallDir/x86"
    mv "$tmpInstallDir/x86_64-linux-android" "$tmpInstallDir/x86_64"
    ;;
ios)
    cp -a "$tmpDir/CouchbaseLite.xcframework" "$tmpInstallDir"
    cp -a "$tmpDir/CouchbaseLiteDart.xcframework" "$tmpInstallDir"
    ;;
macos)
    cp -L "$tmpDir/libcblite-$COUCHBASE_LITE_C_VERSION/lib/libcblite."?".dylib" "$tmpInstallDir"
    cp -L "$tmpDir/libcblitedart-$COUCHBASE_LITE_DART_VERSION/lib/libcblitedart."?".dylib" "$tmpInstallDir"
    ;;
linux*)
    cp -a "$tmpDir/libcblite-$COUCHBASE_LITE_C_VERSION/lib/"*"/libcblite."* "$tmpInstallDir"
    cp -a "$tmpDir/libcblitedart-$COUCHBASE_LITE_DART_VERSION/lib/"*"/libcblitedart."* "$tmpInstallDir"
    ;;
windows*)
    cp -a "$tmpDir/libcblite-$COUCHBASE_LITE_C_VERSION/bin/cblite."* "$tmpInstallDir"
    cp -a "$tmpDir/libcblitedart-$COUCHBASE_LITE_DART_VERSION/bin/cblitedart."* "$tmpInstallDir"
    ;;
esac

# Move tmp install dir to actual install dir
installDir="$(_installDir "$target")"
mv "$tmpInstallDir" "$installDir"

# Delete the tmp dir
rm -rf "$tmpDir"
