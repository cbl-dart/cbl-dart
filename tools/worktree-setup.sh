#!/usr/bin/env bash

set -e

case "$(uname)" in
MINGW* | CYGWIN* | MSYS*)
    melosBin="melos.bat"
    ;;
*)
    melosBin="melos"
    ;;
esac

scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
projectDir="$(cd "$scriptDir/.." && pwd)"

# === Description =============================================================

# Bootstraps the current worktree for development.
#
# Assumes the script is running inside a worktree of the cbl-dart repository
# and prepares it by resolving dependencies and building native libraries.
#
# Steps:
# 1. Run melos bootstrap (resolve dependencies across all packages).
# 2. Build native libraries for the host target.

# === Bootstrap ===============================================================

cd "$projectDir"

echo "Bootstrapping packages..."
"$scriptDir/dev-tools.sh" bootstrap

echo "Building native libraries..."
"$scriptDir/dev-tools.sh" prepareNativeLibraries

echo "Worktree is ready for development"
