#!/usr/bin/env bash

# Script that downloads and unpacks official prebuilt binaries of
# Couchbase Lite C.
#
# The binaries will be installed into `native/vendor/couchbase-lite-C-prebuilt`.
# For each target both the community and enterprise editions are installed.
# The version of Couchbase Lite C, this script downloads, is defined in
# `native/CouchbaseLite.version`.
#
# # Usage
#
# If no arguments are passed, binares for all targets supported by cbl-dart
# are downloaded.
#
# A single argument can be passed, which must be a target that is supported by
# cbl-dart, in which case only the binares for that target are downloaded.

set -e

scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nativeDir="$(cd $scriptDir/.. && pwd)"
vendorDir="$nativeDir/vendor"
binariesDir="$vendorDir/couchbase-lite-C-prebuilt"
tmpDir="$binariesDir/tmp"
versionFile="$nativeDir/CouchbaseLite.version"
version="$(cat "$versionFile")"
editions=(community enterprise)
targets=(android ios macos ubuntu20.04-x86_64)

# Outputs the extension of the archives for the given target.
function _archiveExt() {
    local target=$1

    case "$target" in
    ubuntu*)
        echo tar.gz
        ;;
    *)
        echo zip
        ;;

    esac
}

# Outputs the URL of the archive for the given version, edition and target of
# Couchbase Lite C.
function _downloadUrl() {
    local version=$1
    local edition=$2
    local target=$3
    echo "https://packages.couchbase.com/releases/couchbase-lite-c/$version/couchbase-lite-c-$edition-$version-$target.$(_archiveExt $target)"
}

# Downloads and unpacks the binares for the given version, edition and target
# of Couchbase Lite C.
function _downloadBinaries() {
    local version=$1
    local edition=$2
    local target=$3
    local archiveFile="$tmpDir/$version-$edition-$target.$(_archiveExt $target)"
    local installDir="$binariesDir/$version-$edition-$target"

    if [ -d "$installDir" ]; then
        echo "Skipping download for exisiting binaries: $version-$edition-$target"
        return 0
    fi

    echo "Downloading prebuild binaries: $version-$edition-$target"

    curl "$(_downloadUrl $version $edition $target)" \
        --silent \
        --fail \
        --retry 5 \
        --retry-max-time 30 \
        --output "$archiveFile"

    rm -rf "$installDir"
    mkdir -p "$installDir"

    case "$(_archiveExt $target)" in
    zip)
        unzip -q "$archiveFile" -d "$installDir"
        ;;
    tar.gz)
        tar -xzf "$archiveFile" -C "$installDir"
        ;;
    esac
}

# Downloads the binaries for the given version and all the given editions and
# targets of Couchbase Lite C.
#
# The edition and targets must be space sperated lists. If either one is empty,
# the binaries for all respectively allowed value are downloaded.
function _downloadMultipleBinaries() {
    local _version=$1
    local _editions=$2
    local _targets=$3

    if [[ -z "$_version" ]]; then
        _version="$version"
    fi

    if [[ -z "$_editions" ]]; then
        _editions="${editions[*]}"
    fi

    if [[ -z "$_targets" ]]; then
        _targets="${targets[*]}"
    fi

    for edition in $_editions; do
        for target in $_targets; do
            _downloadBinaries "$version" "$edition" "$target"
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
