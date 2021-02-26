#!/usr/bin/env bash

# Script which installs published binaries for a given platform.
#
# The first and only argument to the script must be the name of the platform 
# (android | apple).
# 
# When the environment variable CBL_FLUTTER_SKIP_INSTALL_BINARIES is set, the
# installation will be skipped.

set -e

# Skip installation if environment variable is set
if [ -n "$CBL_FLUTTER_SKIP_INSTALL_BINARIES" ]; then
    echo "cbl_flutter: Skipping install of publihsed binaries"
    exit 0
fi

# Setup parameters
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pkgDir="$dir/.."
platform="$1"

installDir=
case "$platform" in
    android)
        installDir="$pkgDir/android/lib"
    ;;
    apple)
        installDir="$pkgDir/Xcframeworks"
    ;;
    *)
        echo "cbl_flutter: Unknown platform $platform"
        exit 1
    ;;
esac

# Install binaries
cd "$pkgDir"
flutter pub get
flutter pub run cbl_native:binary_url "$platform" --install "$installDir"
