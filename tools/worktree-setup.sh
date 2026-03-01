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
# and prepares it by building generated packages and resolving dependencies.
#
# Steps:
# 1. Build the generated Flutter packages (cbl_flutter_ce|ee).
# 2. Run melos bootstrap (resolve dependencies across all packages).

# === Bootstrap ===============================================================

cd "$projectDir"

echo "Building generated Flutter packages..."
$melosBin run build:cbl_flutter_prebuilt

echo "Bootstrapping packages..."
"$scriptDir/dev-tools.sh" bootstrap

echo "Worktree is ready for development"
