#!/usr/bin/env bash

set -e

# Parse and validate args
cmd=
args=()

for arg in "$@"; do
    if [ -z "$cmd" ]; then
        cmd="$arg"
    else
        args+="$arg"
    fi
done

if [ -z "$cmd" ]; then
    echo "You need to provide a command."
    exit 1
fi

commands=(
    foreach
)

if [[ ! " ${commands[@]} " =~ " ${cmd} " ]]; then
    echo "'$cmd' is not a known command."
    exit 1
fi

# Constants
scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
projectDir="$(cd "$scriptDir/.." && pwd)"
packagesDir="$projectDir/packages"

packages=(
    cbl
    cbl_e2e_tests
    cbl_e2e_tests_standalone_dart
    cbl_flutter
    cbl_flutter_android
    cbl_flutter_apple
)

# Commands

function foreach() {
    for pkg in "${packages[@]}"; do
        local pkgDir="$packagesDir/$pkg"

        echo "Going into $pkg"
        cd "$pkgDir"

        bash -c "$*"

        # Finish with a new line
        echo
    done
}

"$@"
