#!/usr/bin/env bash

set -e

# Converts the dart coverage output for a package to lcov.
#
# The first and only parameter is the packages directory.
#
# The dart coverage data is expected to be in `$PACKAGE_DIR$/coverage/dart`.
#
# The output is written to `$PACKAGE_DIR$/coverage/lcov.info`.
function dartToLcov() {
    local packageDir="$1"
    local coverageDir="$packageDir/coverage/dart"
    local input="$coverageDir/dart"
    local output="$coverageDir/lcov.info"
    local packagesFile="$packageDir/.packages"

    dart pub global activate coverage

    format_coverage \
        -i "$input" \
        -l \
        -o "$output" \
        --packages "$packagesFile"
}

"$@"
