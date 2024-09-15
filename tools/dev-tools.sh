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

function bootstrapPackage() {
    local package="$1"
    $melosBin bootstrap --scope "$package"
}

function bootstrap() {
    $melosBin bootstrap
}

"$@"
