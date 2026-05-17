#!/usr/bin/env bash

set -e

# === Globals =================================================================

if [[ -z "${ANDROID_HOME}" ]]; then
    case "$(uname)" in
    Darwin)
        ANDROID_HOME="~/Library/Android/sdk"
        ;;
    Linux)
        ANDROID_HOME="~/Android/Sdk"
        ;;
    *)
        echo "The environment variable ANDROID_HOME needs to be set"
        exit 1
        ;;
    esac
fi

emulatorName="cbl-dart"
emulatorPort=5554
serialName="emulator-$emulatorPort"
appBundleId="com.terwesten.gabriel.cbl_e2e_tests_flutter"

# === Usage ===================================================================

function usage() {
    cat <<-EOF
COMMANDS
    createAndStart -a API-LEVEL -d DEVICE
        creates and starts an emulator

    diagnostics -o OUTPUT-DIRECTORY
        collects emulator diagnostics

    setupReversePort PORT
        proxies a port from the emulator to the host

    bugreport -o OUTPUT-DIRECTORY
        creates a bugreport for the emulator

DESCRIPTION
    -a API-LEVEL
        Android API level of the emulator

    -d DEVICE
        devices definition to the emulator

    -o OUTPUT-DIRECTORY
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

function adbForEmulator() {
    "$ANDROID_HOME/platform-tools/adb" -s "$serialName" "$@"
}

function waitForBootProperty() {
    local property="$1"
    local expected="$2"
    local timeoutSeconds="$3"
    local elapsed=0

    echo "Waiting for $property to become $expected..."

    while [[ $elapsed -lt $timeoutSeconds ]]; do
        local value
        value="$(adbForEmulator shell getprop "$property" 2>/dev/null | tr -d '\r')"

        if [[ "$value" == "$expected" ]]; then
            echo "$property is $expected"
            return 0
        fi

        sleep 2
        elapsed=$((elapsed + 2))
    done

    echo "Timed out waiting for $property to become $expected"
    return 1
}

function waitForPackageManager() {
    local timeoutSeconds="$1"
    local elapsed=0

    echo "Waiting for Android package manager..."

    while [[ $elapsed -lt $timeoutSeconds ]]; do
        if adbForEmulator shell cmd package list packages >/dev/null 2>&1; then
            echo "Android package manager is ready"
            return 0
        fi

        sleep 2
        elapsed=$((elapsed + 2))
    done

    echo "Timed out waiting for Android package manager"
    return 1
}

function waitForEmulatorReady() {
    echo "Waiting for emulator to become ready..."
    adbForEmulator wait-for-device
    waitForBootProperty sys.boot_completed 1 180
    waitForBootProperty dev.bootcomplete 1 180
    waitForPackageManager 180
    adbForEmulator shell input keyevent 82 >/dev/null 2>&1 || true
    "$ANDROID_HOME/platform-tools/adb" devices -l
    echo "Emulator is ready"
}

function createAndStart() {
    local apiLevel=""
    local device=""

    while getopts "a:d:" optName; do
        case "$optName" in
        a)
            apiLevel="$OPTARG"
            ;;
        d)
            device="$OPTARG"
            ;;
        ?)
            usageFailure
            ;;
        esac
    done

    requireOption -a API-LEVEL "$apiLevel"
    requireOption -d DEVICE "$device"

    echo 'KERNEL=="kvm", GROUP="kvm", MODE="0666", OPTIONS+="static_node=kvm"' | sudo tee /etc/udev/rules.d/99-kvm4all.rules
    sudo udevadm control --reload-rules
    sudo udevadm trigger --name-match=kvm

    sudo apt-get install -y --no-install-recommends libpulse0

    yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --licenses

    # Install emulator if not already present.
    if [[ ! -d "$ANDROID_HOME/emulator" ]]; then
        echo "Installing emulator..."
        "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" emulator
    fi

    # Install system image.
    systemImage="system-images;android-$apiLevel;default;x86_64"
    echo "Installing system image '$systemImage' ..."
    "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" "$systemImage"

    # Install platform tools if not already present.
    if [[ ! -d "$ANDROID_HOME/platform-tools" ]]; then
        echo "Installing platform tools..."
        "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" platform-tools
    fi

    # Create emulator.
    echo "Creating emulator..."
    "$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager" create avd \
        --name "$emulatorName" \
        --package "$systemImage" \
        --device "$device"

    # Start emulator.
    echo "Staring emulator..."
    "$ANDROID_HOME/emulator/emulator" \
        -avd "$emulatorName" \
        -port "$emulatorPort" \
        -no-window \
        -no-audio \
        -no-boot-anim \
        -no-metrics \
        -partition-size 4096 \
        >./emulator-logs.txt 2>&1 &

    sleep 10
    cat ./emulator-logs.txt

    waitForEmulatorReady
}

function setupReversePort() {
    local port="$1"

    requireOption -p PORT "$port"

    echo "Setting up reverse socket connect for port $port"
    adbForEmulator reverse "tcp:$1" "tcp:$1"
}

function diagnostics() {
    local outputDirectory=""

    while getopts "o:" optName; do
        case "$optName" in
        o)
            outputDirectory="$OPTARG"
            ;;
        ?)
            usageFailure
            ;;
        esac
    done

    requireOption -o OUTPUT-DIRECTORY "$outputDirectory"

    mkdir -p "$outputDirectory"

    "$ANDROID_HOME/platform-tools/adb" devices -l >"$outputDirectory/adb-devices.txt" 2>&1 || true
    adbForEmulator shell getprop >"$outputDirectory/getprop.txt" 2>&1 || true
    adbForEmulator shell dumpsys activity processes >"$outputDirectory/dumpsys-activity-processes.txt" 2>&1 || true
    adbForEmulator shell dumpsys package "$appBundleId" >"$outputDirectory/dumpsys-package.txt" 2>&1 || true
    adbForEmulator logcat -d -v threadtime >"$outputDirectory/logcat.txt" 2>&1 || true

    if [[ -f ./emulator-logs.txt ]]; then
        cp -a ./emulator-logs.txt "$outputDirectory/"
    fi
}

function bugreport() {
    local outputDirectory=""

    while getopts "o:" optName; do
        case "$optName" in
        o)
            outputDirectory="$OPTARG"
            ;;
        ?)
            usageFailure
            ;;
        esac
    done

    requireOption -o OUTPUT-DIRECTORY "$outputDirectory"

    echo "Creating bugreport..."

    mkdir -p "$outputDirectory"

    adbForEmulator \
        bugreport \
        "$outputDirectory"

    echo "Created bugreport"
}

function copyAppData() {
    adbForEmulator shell "run-as $appBundleId cp -r /data/data/$appBundleId /mnt/sdcard"
    adbForEmulator pull "/mnt/sdcard/$appBundleId" "appData"
}

# === Parse command ===========================================================

if [[ $# -eq 0 ]]; then
    usageFailure
fi

commands=(
    createAndStart
    diagnostics
    setupReversePort
    bugreport
    copyAppData
)

if [[ ! " ${commands[*]} " =~ " $1 " ]]; then
    echo "Unknown command $1"
    echo
    usageFailure
fi

"$@"
