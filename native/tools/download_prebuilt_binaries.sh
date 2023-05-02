#!/usr/bin/env bash

# Script that downloads and unpacks official prebuilt binaries of
# Couchbase Lite C.
#
# The binaries will be installed into `native/vendor/couchbase-lite-C-prebuilt`.
# For each target both the community and enterprise editions are installed.
# The release of Couchbase Lite C, this script downloads, is defined in
# `native/CouchbaseLiteC.release`.
#
# # Usage
#
# If no arguments are passed, binares for all targets supported by cbl-dart
# are downloaded.
#
# A single argument can be passed, which must be a target that is supported by
# cbl-dart, in which case only the binares for that target are downloaded.

set -e

TAR=tar

case "$(uname -s)" in
MINGW* | CYGWIN* | MSYS*)
    # Use bsd tar, which comes with Windows 10 and not gnu tar from git-bash.
    TAR="$SYSTEMROOT\system32\tar.exe"
    ;;
esac
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nativeDir="$(cd "$scriptDir/.." && pwd)"
vendorDir="$nativeDir/vendor"
binariesDir="$vendorDir/couchbase-lite-C-prebuilt"
tmpDir="$binariesDir/tmp"
couchbaseLiteCRelease="$(cat "$nativeDir/CouchbaseLiteC.release")"
editions=(community enterprise)
targets=(android ios macos linux-x86_64 windows-x86_64)
targetsWithExternalSymbols=(macos linux-x86_64 windows-x86_64)

# Outputs the extension of the archives for the given target.
function _archiveExt() {
    local target=$1

    case "$target" in
    linux*)
        echo tar.gz
        ;;
    *)
        echo zip
        ;;

    esac
}

# Outputs the URL of the archive for the given release, edition and target of
# Couchbase Lite C.
function _downloadUrl() {
    local release="$1"
    local edition="$2"
    local target="$3"
    echo "https://packages.couchbase.com/releases/couchbase-lite-c/$release/couchbase-lite-c-$edition-$release-$target.$(_archiveExt "$target")"
}

function _symbolsDownloadUrl() {
    local release="$1"
    local edition="$2"
    local target="$3"
    echo "https://packages.couchbase.com/releases/couchbase-lite-c/$release/couchbase-lite-c-$edition-$release-$target-symbols.$(_archiveExt "$target")"
}

# Downloads and unpacks the binares for the given release, edition and target
# of Couchbase Lite C.
function _downloadBinaries() {
    local release="$1"
    local edition="$2"
    local target="$3"
    local archiveFile="$tmpDir/$release-$edition-$target.$(_archiveExt "$target")"
    local symbolsArchiveFile="$tmpDir/$release-$edition-$target-symbols.$(_archiveExt "$target")"
    local installDir="$binariesDir/$release-$edition-$target"

    if [ -d "$installDir" ]; then
        echo "Skipping download for exisiting binaries: $release-$edition-$target"
        return 0
    fi

    echo "Downloading prebuild binaries: $release-$edition-$target"

    curl "$(_downloadUrl "$release" "$edition" "$target")" \
        --silent \
        --fail \
        --retry 5 \
        --retry-max-time 30 \
        --output "$archiveFile"

    if [[ " ${targetsWithExternalSymbols[*]} " == *" $target "* ]]; then
        curl "$(_symbolsDownloadUrl "$release" "$edition" "$target")" \
            --silent \
            --fail \
            --retry 5 \
            --retry-max-time 30 \
            --output "$symbolsArchiveFile"
    fi

    rm -rf "$installDir"
    mkdir -p "$installDir"

    _unpackArchive "$archiveFile" "$installDir"

    if [[ " ${targetsWithExternalSymbols[*]} " == *" $target "* ]]; then
        _unpackArchive "$symbolsArchiveFile" "$installDir"

        case "$target" in
        macos)
            mv "$installDir/libcblite-$release/libcblite.dylib.dSYM" "$installDir/libcblite-$release/lib"
            ;;
        linux*)
            mv "$installDir/libcblite-$release/libcblite.so.sym" "$installDir/libcblite-$release/lib/"*-linux-gnu
            ;;
        windows*)
            mv "$installDir/cblite.pdb" "$installDir/libcblite-$release/bin"
            ;;
        esac
    fi
}

function _unpackArchive() {
    local archiveFile="$1"
    local installDir="$2"

    case "$archiveFile" in
    *.zip)
        case "$(uname -s)" in
        MINGW* | CYGWIN* | MSYS*)
            # Windows 10 does not have unzip available, but has bsdtar which can
            # unpack zip archives.
            $TAR -xf "$archiveFile" -C "$installDir"
            ;;
        *)
            unzip -q "$archiveFile" -d "$installDir"
            ;;
        esac
        ;;
    *.tar.gz)
        $TAR -xzf "$archiveFile" -C "$installDir"
        ;;
    esac
}

# Downloads the binaries for the given release and all the given editions and
# targets of Couchbase Lite C.
#
# The edition and targets must be space sperated lists. If either one is empty,
# the binaries for all respectively allowed value are downloaded.
function _downloadMultipleBinaries() {
    local _release="$1"
    local _editions="$2"
    local _targets="$3"

    if [[ -z "$_release" ]]; then
        _release="$couchbaseLiteCRelease"
    fi

    if [[ -z "$_editions" ]]; then
        _editions="${editions[*]}"
    fi

    if [[ -z "$_targets" ]]; then
        _targets="${targets[*]}"
    fi

    for edition in $_editions; do
        for target in $_targets; do
            _downloadBinaries "$_release" "$edition" "$target"
        done
    done
}

target="$1"

if [[ -n "$target" ]]; then
    if [[ ! " ${targets[*]} " =~ " $target " ]]; then
        echo "Invalid target: $target"
        exit 1
    fi
fi

mkdir -p "$tmpDir"

_downloadMultipleBinaries "" "" "$target"

rm -rf "$tmpDir"
