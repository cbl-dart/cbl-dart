#!/usr/bin/env bash

# This scripts creates symbolic links for the Xcframeworks in
# `./Xcframeworks` to `{ios,macos}/Xcframeworks`.

set -e

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pkgDir="$(cd "$dir/.." && pwd)"
frameworks=(CouchbaseLite CouchbaseLiteDart)
platformDirs=(ios macos)

for platformDir in "${platformDirs[@]}"; do
    platformFrameworksDir="$pkgDir/$platformDir/Xcframeworks"

    # If the Xcframeworks directory already exists, skip it.
    if [ -d "$platformFrameworksDir" ]; then
        continue
    fi
    
    mkdir -p "$platformFrameworksDir"

    cd "$platformFrameworksDir"

    for framework in "${frameworks[@]}"; do
        ln -s "../../Xcframeworks/$framework.xcframework"
    done
done
