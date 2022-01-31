#!/usr/bin/env bash

# Allows running pure Dart tests through the Flutter test runner
# with the VS Code Dart extension.

set -e

flutter test "$@"
