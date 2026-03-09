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

mainRepoDir="$(git rev-parse --path-format=absolute --git-common-dir)"
mainRepoDir="$(cd "$mainRepoDir/.." && pwd)"

if [ -f "$mainRepoDir/.claude/settings.local.json" ]; then
  echo "Symlinking .claude/settings.local.json..."
  mkdir -p .claude
  ln -sf "$mainRepoDir/.claude/settings.local.json" .claude/settings.local.json
fi

echo "Bootstrapping packages..."
melos bootstrap

echo "Worktree is ready for development"
