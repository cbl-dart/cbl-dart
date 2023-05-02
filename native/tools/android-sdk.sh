#!/usr/bin/env bash

# Utilities to install and manage Android SDK.

set -e

ndkVersion="23.1.7779620"
cmakeVersion="3.18.1"
defaultSdkLocation=("$HOME/Android/Sdk" "$HOME/Library/Android/sdk")
sdkHome="$ANDROID_HOME"

# Look for Android SDK in default locations
if [ -z "$sdkHome" ]; then
    for location in "${defaultSdkLocation[@]}"; do
        if [ -d "$location" ]; then
            sdkHome="$location"
            break
        fi
    done

    if [ -z "$sdkHome" ]; then
        echo "Could not find Android SDK."
        exit 1
    fi
fi

function installNativeToolchain() {
    $sdkHome/cmdline-tools/latest/bin/sdkmanager --install "ndk;$ndkVersion"
    $sdkHome/cmdline-tools/latest/bin/sdkmanager --install "cmake;$cmakeVersion"
}

"$@"
