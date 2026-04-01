#!/usr/bin/env bash

# Utilities to install and manage Android SDK.

set -e

ndkVersion="28.0.13004108"
appNdkVersion="28.2.13676358"
appBuildToolsVersion="35.0.0"
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

# Find sdkmanager, checking "latest" first then any versioned directory.
sdkmanager=""
for dir in "$sdkHome"/cmdline-tools/*/bin; do
    if [ -x "$dir/sdkmanager" ]; then
        sdkmanager="$dir/sdkmanager"
        # Prefer "latest" if available.
        if [[ "$dir" == */latest/* ]]; then
            break
        fi
    fi
done

if [ -z "$sdkmanager" ]; then
    echo "Could not find sdkmanager in $sdkHome/cmdline-tools/*/bin."
    exit 1
fi

function installNativeToolchain() {
    "$sdkmanager" --install "ndk;$ndkVersion"
    "$sdkmanager" --install "cmake;$cmakeVersion"
}

function installAppBuildDeps() {
    "$sdkmanager" --install "ndk;$appNdkVersion"
    "$sdkmanager" --install "build-tools;$appBuildToolsVersion"
    "$sdkmanager" --install "platforms;android-33"
    "$sdkmanager" --install "platforms;android-36"
}

"$@"
