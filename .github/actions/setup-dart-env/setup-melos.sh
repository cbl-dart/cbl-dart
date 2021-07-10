#!/bin/bash

set -e

melosVersion="$1"

echo "Installing Melos $melosVersion"

echo "Globally activating Melos..."
flutter pub global activate melos "$melosVersion"

if [ -z "$SKIP_MELOS_BOOTSTRAP" ]; then
    echo "Bootstraping packages..."
    melos bootstrap
else
    echo "Skipping bootstraping packages"
fi
