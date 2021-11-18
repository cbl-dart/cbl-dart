#!/usr/bin/env bash

set -e

function requireEnvVar() {
    local envVar="$1"

    if [[ -z "${!envVar}" ]]; then
        echo "$envVar is a required environment variable, but is not set"
        exit 1
    fi
}

# === Constants ===============================================================

testResultsDir="test-results"
cblFlutterPrebuiltPackage="cbl_flutter_prebuilt"
embedder="$EMBEDDER"
targetOs="$TARGET_OS"
testPackage="$TEST_PACKAGE"
testPackageDir="packages/$testPackage"
testAppBundleId="com.terwesten.gabriel.cblE2eTestsFlutter"
iosVersion="15-0"
iosDevice="iPhone 13"
androidVersion="22"
androidDevice="pixel_4"

melosBin="melos"
if [[ ! $(which "$melosBin" &>/dev/null) ]]; then
    # On Windows bash can't find melos by its simple name.
    melosBin="melos.bat"
fi

# === Steps ===================================================================

function buildNativeLibraries() {
    local target=

    case "$targetOs" in
    iOS)
        target=ios
        ;;
    macOS)
        target=macos
        ;;
    Android)
        target=android
        ;;
    Ubuntu)
        target=ubuntu20.04-x86_64
        ;;
    Windows)
        target=windows-x86_64
        ;;
    esac

    ./tools/dev-tools.sh prepareNativeLibraries enterprise debug "$target"
}

function configureFlutter() {
    requireEnvVar TARGET_OS

    case "$targetOs" in
    macOS)
        flutter config --enable-macos-desktop
        ;;
    Ubuntu)
        flutter config --enable-linux-desktop
        ;;
    Windows)
        flutter config --enable-windows-desktop
        ;;
    esac
}

function bootstrapPackage() {
    requireEnvVar EMBEDDER
    requireEnvVar TEST_PACKAGE

    local noMelos=""
    if [[ " $* " =~ " --no-melos " ]]; then
        noMelos="true"
    fi

    case "$embedder" in
    standalone)
        if [[ "$noMelos" == "true" ]]; then
            cd "$testPackageDir"
            dart pub get
        else
            $melosBin bootstrap --scope "$testPackage"
        fi
        ;;
    flutter)
        # `flutter pub get` creates some files which `melos bootstrap` doesn't.
        cd "$testPackageDir"
        flutter pub get

        if [[ "$noMelos" != "true" ]]; then
            $melosBin bootstrap --scope "$testPackage"
        fi
        ;;
    esac
}

function startCouchbaseServices() {
    case "$(uname)" in
    Darwin)
        $melosBin run test:startSyncGatewayMacOS &>/dev/null &
        $melosBin run test:waitForSyncGateway
        ;;
    *)
        $melosBin run test:setupCouchbaseClusterDocker
        ;;
    esac
}

function startVirtualDevices() {
    requireEnvVar TARGET_OS

    case "$targetOs" in
    iOS)
        ./tools/apple-simulator.sh start -o "iOS-$iosVersion" -d "$iosDevice"
        ;;
    Android)
        ./tools/android-emulator.sh createAndStart -a "$androidVersion" -d "$androidDevice"
        ./tools/android-emulator.sh setupReversePort 4984
        ./tools/android-emulator.sh setupReversePort 4985
        ;;
    Ubuntu)
        Xvfb :99 &
        echo "DISPLAY=:99" >>$GITHUB_ENV
        ;;
    esac
}

function runE2ETests() {
    requireEnvVar EMBEDDER
    requireEnvVar TARGET_OS
    requireEnvVar TEST_PACKAGE

    case "$embedder" in
    standalone)
        cd "$testPackageDir"

        export ENABLE_TIME_BOMB=true
        testCommand="dart test --coverage coverage/dart -r expanded -j 1"

        case "$targetOs" in
        macOS)
            # The tests are run with sudo, so that macOS records crash reports.
            sudo $testCommand
            # Since we ran the tests under sudo, the test outputs such as
            # coverage data and logs are owned by sudo.
            # Here we recursively restore ownership of the package directory
            # back to the normal user.
            sudo chown -R "$(whoami)" "."
            ;;
        Ubuntu)
            # Enable core dumps.
            ulimit -c unlimited
            $testCommand
            ;;
        Windows)
            # Not collecting crash reports for Windows for now.
            $testCommand
            ;;
        esac
        ;;
    flutter)
        cd "$testPackageDir"

        device=""
        case "$targetOs" in
        iOS)
            device="iPhone"
            ;;
        macOS)
            device="macOS"
            ;;
        Android)
            device="Android"
            ;;
        Ubuntu)
            # Enable core dumps.
            device="Linux"
            ulimit -c unlimited
            sudo sysctl -w kernel.core_pattern="core.%p"
            ;;
        esac

        # Note: We would like to collect coverage data from tests, but
        # `flutter drive` does not support the `--coverage` flag. While
        # `flutter test` does, it does not support the `--keep-app-running`
        # flag, which we need to collect logs from devices.
        flutter drive \
            --no-pub \
            -d "$device" \
            --dart-define enableTimeBomb=true \
            --keep-app-running \
            --driver test_driver/integration_test.dart \
            --target integration_test/e2e_test.dart
        ;;
    esac
}

function _collectFlutterIntegrationResponseData() {
    echo "Collecting Flutter integration test response data"

    local integrationResponseData="$testPackageDir/build/integration_response_data"

    if [ ! -e "$integrationResponseData" ]; then
        echo "Did not find data"
        return 0
    fi

    echo "Copying data..."
    cp -a "$integrationResponseData" "$testResultsDir"
    echo "Copied data"
}

function _collectCrashReportsMacOS() {
    # Crash reports are generated by the OS.
    echo "Copying macOS DiagnosticReports..."
    cp -a ~/Library/Logs/DiagnosticReports "$testResultsDir"
    echo "Copied macOS DiagnosticReports"
}

function _collectCrashReportsLinuxStandalone() {
    ./tools/create-crash-report-linux.sh \
        -e "$(which dart)" \
        -c "$testPackageDir/core" \
        -o "$testResultsDir"
}

function _collectCrashReportsLinuxFlutter() {
    for core in "$testPackageDir/core."*; do
        local pid="${core##*.}"
        local coreTestResultsDir="$testResultsDir/$pid"
        mkdir -p "$coreTestResultsDir"

        ./tools/create-crash-report-linux.sh \
            -e "$testPackageDir/build/linux/x64/debug/bundle/$testPackage" \
            -c "$core" \
            -o "$coreTestResultsDir"
    done
}

function _collectCrashReportsAndroid() {
    ./tools/android-emulator.sh bugreport -o "$testResultsDir"
}

function _collectCblLogsStandalone() {
    echo "Collecting Couchbase Lite logs"

    local cblLogsDir="$testPackageDir/test/.tmp/logs"

    if [ ! -e "$cblLogsDir" ]; then
        echo "Did not find logs"
        return 0
    fi

    echo "Copying files..."
    cp -a "$cblLogsDir" "$testResultsDir"
    echo "Copied files"
}

function _collectCblLogsIosSimulator() {
    echo "Collecting Couchbase Lite logs from iOS Simulator app"

    ./tools/apple-simulator.sh copyData \
        -o "iOS-$iosVersion" \
        -d "$iosDevice" \
        -b "$testAppBundleId" \
        -f "Library/Caches/cbl_flutter/logs" \
        -t "$testResultsDir"
}

function _collectCblLogsMacOS() {
    echo "Collecting Couchbase Lite logs from macOS app"

    local appDataContainer="~/Library/Containers/$testAppBundleId/Data"
    local cblLogsDir="$appDataContainer/Library/Caches/cbl_flutter/logs"

    if [ ! -e "$cblLogsDir" ]; then
        echo "Did not find logs"
        return 0
    fi

    echo "Copying files..."
    cp -a "$cblLogsDir" "$testResultsDir"
    echo "Copied files"
}

function collectTestResults() {
    requireEnvVar EMBEDDER
    requireEnvVar TARGET_OS
    requireEnvVar TEST_PACKAGE

    mkdir "$testResultsDir"

    # Wait for crash reports/core dumps.
    sleep 60

    case "$embedder" in
    standalone)
        case "$targetOs" in
        macOS)
            _collectCrashReportsMacOS
            _collectCblLogsStandalone
            ;;
        Ubuntu)
            _collectCrashReportsLinuxStandalone
            _collectCblLogsStandalone
            ;;
        Windows)
            # Not collecting crash reports for Windows for now.
            _collectCblLogsStandalone
            ;;
        esac
        ;;
    flutter)
        _collectFlutterIntegrationResponseData

        case "$targetOs" in
        macOS)
            _collectCrashReportsMacOS
            _collectCblLogsMacOS
            ;;
        iOS)
            _collectCrashReportsMacOS
            _collectCblLogsIosSimulator
            ;;
        Android)
            _collectCrashReportsAndroid
            # TODO get cbl logs from device
            ;;
        Ubuntu)
            _collectCrashReportsLinuxFlutter
            # TODO get cbl logs from device
            ;;
        esac
        ;;
    esac
}

# Uploads coverage data to codecov.
#
# The first and only paramter is a comma separated list of flags to be
# associated with the uploaded coverage data.
function uploadCoverageData() {
    requireEnvVar EMBEDDER
    requireEnvVar TEST_PACKAGE

    local flags="$1"

    # Format coverage data as lcov
    case "$embedder" in
    standalone)
        # We are checking whether dart coverage data exists because we are
        # temporarily using `flutter` to run pure dart tests and `flutter`
        # already outputs lcov.
        if [ -d "$testPackageDir/coverage/dart" ]; then
            ./tools/coverage.sh dartToLcov "$testPackageDir"
        fi
        ;;
    flutter)
        # Flutter already outputs coverage data as lcov and into the correct
        # location.
        ;;
    esac

    # Install codecove uploader
    case "$OSTYPE" in
    linux*)
        curl -Os https://uploader.codecov.io/latest/linux/codecov
        chmod +x codecov
        ;;
    darwin*)
        curl -Os https://uploader.codecov.io/latest/macos/codecov
        chmod +x codecov
        ;;
    mingw* | msys* | cygwin*)
        curl -Os https://uploader.codecov.io/latest/window/codecov.exe
        ;;
    esac

    # Upload coverage data
    ./codecov* \
        -F "$flags" \
        -f "$testPackageDir/coverage/lcov.info" \
        -C "$GITHUB_SHA"
}

"$@"
