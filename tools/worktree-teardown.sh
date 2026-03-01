#!/usr/bin/env bash

set -e

scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
projectDir="$(cd "$scriptDir/.." && pwd)"
cblE2eTestsDir="$projectDir/packages/cbl_e2e_tests"

# === Description =============================================================

# Tears down resources in the current worktree.
#
# Assumes the script is running inside a worktree of the cbl-dart repository
# and cleans up any resources that were started for development or testing.
#
# Steps:
# 1. Tear down Docker Compose services (Sync Gateway).

# === Teardown ================================================================

echo "Tearing down Docker Compose services..."
"$cblE2eTestsDir/couchbase-services.sh" teardownDocker

echo "Teardown complete"
