#!/usr/bin/env bash

# Script which installs published binaries for a given platform.
#
# The first and only argument to the script must be the name of the platform
# (android | apple). If the platform is `all` , the binaries for all platforms
# will be installed.
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
pkgDir="$(cd "$dir/.." && pwd)"
allPlatforms=(android apple)

platformArg="$1"
platforms=
if [ "$platformArg" = "all" ]; then
    platforms=("${allPlatforms[@]}")
else
    platforms=("$platformArg")
fi

function installBinariesForPlatform() {
    local platform="$1"
    local installDir=
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

    # Create temporary package to run `cbl_native:binary_url` from.
    # `pub` does not work from inside the package cache directory.
    local tmpDir="/tmp/cbl_flutter_install_binaries-$(date +%s%N)"
    mkdir "$tmpDir"
    cd "$tmpDir"

    # The constraints in this pubspec file ensure that we use the version of cbl_native
    # which cbl_flutter depends on.
    cat >pubspec.yaml <<-EOF
name: tmp
environment:                                                            
  sdk: '>=2.12.0-0 <3.0.0' 
dependencies:
    cbl_flutter:
        path: "$pkgDir"
    cbl_native: any
EOF

    flutter pub get
    flutter pub run cbl_native:binary_url "$platform" --install "$installDir"

    # Clean up the tmporary package
    rm -rf "$tmpDir"
}

for platform in "${platforms[@]}"; do
    installBinariesForPlatform "$platform"
done
