#!/usr/bin/env bash

set -e

# === Usage ===================================================================

function usage() {
    cat <<-EOF
COMMANDS
    start -o OS -d DEVICE
        starts a device simulator

    copyData -o OS -d DEVICE -b APP-BUNDLE-ID -f FILE -t OUTPUT-DIRECTORY
        copies data from a device simulator's container

DESCRIPTION
    -o OS
        name and version of the simulated os, e.g. iOS-14-5

    -d DEVICE
        name of the simulated devices

    -b APP-BUNDLE-ID
        id of the app bundle to copy data from

    -f FILE
        path of the file to copy

    -t OUTPUT-DIRECTORY
        directory to store outputs in
EOF
}

function usageFailure {
    usage
    exit 1
}

function requireOption() {
    if [[ -z "$3" ]]; then
        echo "$2 ($1) is required and was not provided"
        echo
        usageFailure
    fi
}

# === Command implementations =================================================

function _getSimulatorInfo() {
    local os="$1"
    local device="$2"

    xcrun simctl list -j |
        jq \
            ".devices[\"com.apple.CoreSimulator.SimRuntime.$os\"] \
            | map(select(.name == \"$device\"))
            | first"
}

function _getSimulatorId() {
    local os="$1"
    local device="$2"

    _getSimulatorInfo "$os" "$device" | jq -r '.udid'
}

function start() {
    local os=""
    local device=""

    while getopts "o:d:" optName; do
        case "$optName" in
        o)
            os="$OPTARG"
            ;;
        d)
            device="$OPTARG"
            ;;
        ?)
            usageFailure
            ;;
        esac
    done

    requireOption OS -o "$os"
    requireOption DEVICE -d "$device"

    echo "Getting id of simulator..."
    simulatorId="$(_getSimulatorId "$os" "$device")"

    echo "Booting simulator..."
    xcrun simctl bootstatus "$simulatorId" -b
    echo "Booted simulator"
}

function copyData() {
    local os=""
    local device=""
    local appBundleId=""
    local file=""
    local outputDirectory=""

    while getopts "o:d:b:f:t:" optName; do
        case "$optName" in
        o)
            os="$OPTARG"
            ;;
        d)
            device="$OPTARG"
            ;;
        b)
            appBundleId="$OPTARG"
            ;;
        f)
            file="$OPTARG"
            ;;
        t)
            outputDirectory="$OPTARG"
            ;;
        ?)
            usageFailure
            ;;
        esac
    done

    requireOption -o OS "$os"
    requireOption -d DEVICE "$device"
    requireOption -b APP-BUNDLE-ID "$appBundleId"
    requireOption -f FILE "$file"
    requireOption -t OUTPUT-DIRECTORY "$outputDirectory"

    echo "Getting id of simulator..."
    simulatorId="$(_getSimulatorId "$os" "$device")"

    echo "Getting test application's data container..."
    testAppSimulatorDataDir="$(
        xcrun simctl get_app_container \
            "$simulatorId" \
            "$appBundleId" \
            data
    )"

    filePath="$testAppSimulatorDataDir/$file"

    if [ ! -e "$filePath" ]; then
        echo "Could not find file"
        exit 0
    fi

    echo "Copying data..."
    mkdir -p "$outputDirectory"
    cp -a "$filePath" "$outputDirectory"
    echo "Copied data"
}

# === Parse command ===========================================================

if [[ $# -eq 0 ]]; then
    usageFailure
fi

commands=(
    start
    copyData
)

if [[ ! " ${commands[*]} " =~ " $1 " ]]; then
    echo "Unknown command $1"
    echo
    usageFailure
fi

"$@"
