#!/usr/bin/env bash

set -e

case "$(uname)" in
MINGW* | CYGWIN* | MSYS*)
    formatCoverageBin="format_coverage.bat"
;;
*)
    formatCoverageBin="format_coverage"
;;
esac

# Converts the dart coverage output for a package to lcov.
#
# The first and only parameter is the packages directory.
#
# The dart coverage data is expected to be in `$PACKAGE_DIR$/coverage/dart`.
#
# The output is written to `$PACKAGE_DIR$/coverage/lcov.info`.
function dartToLcov() {
    local packageDir="$1"
    local coverageDir="coverage"
    local input="$coverageDir/dart"
    local output="$coverageDir/lcov.info"
    local packagesFile=".dart_tool/package_config.json"

    dart pub global activate coverage

    # `format_coverage` only works when executed from the root of the package.
    cd "$packageDir"

    $formatCoverageBin \
        --check-ignore \
        --in "$input" \
        --lcov \
        --out "$output" \
        --packages "$packagesFile"
}

"$@"
