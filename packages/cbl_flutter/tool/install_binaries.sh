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

# Skip installation if environment variable is set.
if [ -n "$CBL_FLUTTER_SKIP_INSTALL_BINARIES" ]; then
    echo "cbl_flutter: Skipping install of published binaries"
    exit 0
fi

# The directory of this script.
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The directory of the 'cbl_flutter' package. 
pkgDir="$(cd "$dir/.." && pwd)"

# The directory of the 'cbl_flutter' package formatted properly for the 
# current system.
pkgDirSys=
case $(uname -s) in
    CYGWIN*)    pkgDirSys=$(cygpath -m "$pkgDir");;
    MINGW*)     pkgDirSys=$(cygpath -m "$pkgDir");;
    *)          pkgDirSys=pkgDir
esac

# The names of all platforms for which binaries are available.
allPlatforms=(android apple)

platformArg="$1"

# The names of the platforms for which to install binaries.
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
  sdk: '>=2.12.0 <3.0.0' 
dependencies:
    cbl_flutter:
        path: "$pkgDirSys"
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
