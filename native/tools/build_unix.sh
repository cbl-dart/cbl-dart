#!/usr/bin/env bash

set -e

# === Constants ===

toolsDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nativeDir="$(cd "$toolsDir/.." && pwd)"
projectDir="$(cd "$nativeDir/.." && pwd)"
buildDir="$projectDir/build/unix"
libDir="$projectDir/build/unix/lib"
CBLDART_STATIC_CXX="OFF"

if [[ "$(uname)" == "Linux" ]]; then
    CBLDART_STATIC_CXX="ON"
fi

# === Commands ===

function clean() {
    rm -rf "$buildDir"
}

function build() {
    local buildMode="${1:-RelWithDebInfo}"
    _configure "$buildMode"
    _build
    _createLinksForDev
}

function _configure() {
    local buildType="$1"

    # If build dir has already been configured, skip configuring it again.
    if [ -d "$buildDir" ]; then
        echo "Skiping configuring build dir"
        return 0
    fi

    cmake \
        -B "$buildDir" \
        -G Ninja \
        -DCMAKE_INSTALL_PREFIX="$buildDir/install" \
        -DCMAKE_C_COMPILER_LAUNCHER=ccache \
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
        -DCBLDART_STATIC_CXX="$CBLDART_STATIC_CXX" \
        -DCMAKE_BUILD_TYPE="$buildType" \
        "$nativeDir"
}

function _build() {
    cmake --build "$buildDir"
    _copyToLib
    _stripSymbols
}

function _copyToLib() {
    rm -rf "$libDir"
    mkdir -p "$libDir"

    cp -P \
        "$buildDir/cbl-dart/libcblitedart."* \
        "$buildDir/vendor/couchbase-lite-C/libcblite."* \
        "$libDir"
}

function _stripSymbols() {
    case "$(uname)" in
    Linux)
        _stripSymbolsLinux "$libDir/libcblite.so".*.*.*
        _stripSymbolsLinux "$libDir/libcblitedart.so"
        ;;
    Darwin)
        _stripSymbolsMacOS "$libDir/libcblite".*.*.*.dylib
        _stripSymbolsMacOS "$libDir/libcblitedart.dylib"
        ;;
    *)
        echo "$OSTYPE is not a unix OS"
        exit 1
        ;;
    esac
}

function _stripSymbolsLinux() {
    local libraryPath="$1"
    local libraryDir="$(dirname "$libraryPath")"
    local libraryName="$(basename "$libraryPath")"
    local librarySym="$libraryName.sym"
    cd "$libraryDir"
    objcopy --only-keep-debug "$libraryName" "$librarySym"
    strip --strip-unneeded "$libraryName"
    objcopy --add-gnu-debuglink "$librarySym" "$libraryName"
}

function _stripSymbolsMacOS() {
    local libraryPath="$1"
    dsymutil "${libraryPath}" -o "$libraryPath.dSYM"
    strip -x "${libraryPath}"
}

function _createLinksForDev() {
    cd "$projectDir/packages/cbl_e2e_tests_standalone_dart"
    rm -f lib
    ln -s "$libDir"

    cd "$projectDir/packages/cbl_flutter/linux"
    rm -f lib
    ln -s "$libDir"
}

"$@"
