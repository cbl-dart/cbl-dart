#!/usr/bin/env bash

set -e

# === Globals =================================================================

if [[ -z "${ANDROID_HOME}" ]]; then
    case "$(uname)" in
    Darwin)
        ANDROID_HOME="$HOME/Library/Android/sdk"
        ;;
    Linux)
        ANDROID_HOME="$HOME/Android/Sdk"
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
androidUserHome="${ANDROID_USER_HOME:-$HOME/.android}"
androidAvdHome="${ANDROID_AVD_HOME:-$androidUserHome/avd}"
sdkmanager=""
avdmanager=""

export ANDROID_USER_HOME="$androidUserHome"
export ANDROID_AVD_HOME="$androidAvdHome"

mkdir -p "$ANDROID_USER_HOME" "$ANDROID_AVD_HOME"

for dir in "$ANDROID_HOME"/cmdline-tools/*/bin; do
    if [[ -x "$dir/sdkmanager" ]]; then
        sdkmanager="$dir/sdkmanager"
        avdmanager="$dir/avdmanager"
        if [[ "$dir" == */latest/* ]]; then
            break
        fi
    fi
done

if [[ -z "$sdkmanager" || -z "$avdmanager" ]]; then
    echo "Could not find sdkmanager/avdmanager in $ANDROID_HOME/cmdline-tools/*/bin."
    exit 1
fi

# === Usage ===================================================================

function usage() {
    cat <<-EOF
COMMANDS
    createAndStart -a API-LEVEL -d DEVICE
        creates and starts an emulator

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

function waitForEmulatorToBecomeReady() {
    local timeoutSeconds=600
    local startTime=$SECONDS

    while true; do
        if "$ANDROID_HOME/platform-tools/adb" -s "$serialName" get-state >/dev/null 2>&1; then
            local bootCompleted
            bootCompleted=$("$ANDROID_HOME/platform-tools/adb" -s "$serialName" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
            local bootAnimation
            bootAnimation=$("$ANDROID_HOME/platform-tools/adb" -s "$serialName" shell getprop init.svc.bootanim 2>/dev/null | tr -d '\r')

            if [[ "$bootCompleted" == "1" && "$bootAnimation" == "stopped" ]]; then
                "$ANDROID_HOME/platform-tools/adb" -s "$serialName" shell input keyevent 82 >/dev/null 2>&1 || true
                echo "Emulator is ready"
                return 0
            fi
        fi

        if ((SECONDS - startTime >= timeoutSeconds)); then
            echo "Timed out waiting for emulator to become ready after ${timeoutSeconds}s."
            echo "Known AVDs:"
            "$ANDROID_HOME/emulator/emulator" -list-avds || true
            echo "Emulator logs:"
            cat ./emulator-logs.txt || true
            return 1
        fi

        sleep 5
    done
}

# === Command implementations =================================================

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

    sudo apt-get install libpulse0

    yes | "$sdkmanager" --licenses

    # Install emulator if not already present.
    if [[ ! -d "$ANDROID_HOME/emulator" ]]; then
        echo "Installing emulator..."
        "$sdkmanager" emulator
    fi

    # Install system image.
    systemImage="system-images;android-$apiLevel;default;x86_64"
    echo "Installing system image '$systemImage' ..."
    "$sdkmanager" "$systemImage"

    # Install platform tools if not already present.
    if [[ ! -d "$ANDROID_HOME/platform-tools" ]]; then
        echo "Installing platform tools..."
        "$sdkmanager" platform-tools
    fi

    # Create emulator.
    echo "Creating emulator..."
    rm -rf \
        "$ANDROID_AVD_HOME/$emulatorName.avd" \
        "$ANDROID_AVD_HOME/$emulatorName.ini" \
        "$ANDROID_USER_HOME/$emulatorName.ini"
    printf 'no\n' | "$avdmanager" create avd \
        --force \
        --name "$emulatorName" \
        --package "$systemImage" \
        --device "$device"

    if ! "$ANDROID_HOME/emulator/emulator" -list-avds | grep -Fx "$emulatorName" >/dev/null; then
        echo "Failed to create emulator '$emulatorName'."
        echo "Known AVDs:"
        "$ANDROID_HOME/emulator/emulator" -list-avds || true
        exit 1
    fi

    # Start emulator.
    echo "Starting emulator..."
    "$ANDROID_HOME/emulator/emulator" \
        -avd "$emulatorName" \
        -port "$emulatorPort" \
        -no-window \
        -no-audio \
        -no-boot-anim \
        -partition-size 4096 \
        >./emulator-logs.txt 2>&1 &

    sleep 10
    cat ./emulator-logs.txt

    # Wait for emulator to become ready.
    echo "Waiting for emulator to become ready..."
    waitForEmulatorToBecomeReady
}

function setupReversePort() {
    local port="$1"

    requireOption -p PORT "$port"

    echo "Setting up reverse socket connect for port $port"
    "$ANDROID_HOME/platform-tools/adb" -s "$serialName" reverse "tcp:$1" "tcp:$1"
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

    "$ANDROID_HOME/platform-tools/adb" \
        -s "$serialName" \
        bugreport \
        "$outputDirectory"

    echo "Created bugreport"
}

function copyAppData() {
    "$ANDROID_HOME/platform-tools/adb" shell "run-as $appBundleId cp -r /data/data/$appBundleId /mnt/sdcard"
    "$ANDROID_HOME/platform-tools/adb" pull "/mnt/sdcard/$appBundleId" "appData"
}

# === Parse command ===========================================================

if [[ $# -eq 0 ]]; then
    usageFailure
fi

commands=(
    createAndStart
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
