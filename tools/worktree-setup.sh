#!/usr/bin/env bash

set -e

scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
projectDir="$(cd "$scriptDir/.." && pwd)"

# === Description =============================================================

# Bootstraps the current worktree for development.
#
# Assumes the script is running inside a worktree of the cbl-dart repository
# and prepares it by resolving dependencies.

# === Bootstrap ===============================================================

cd "$projectDir"

echo "Bootstrapping packages..."
melos bootstrap

echo "Worktree is ready for development"
