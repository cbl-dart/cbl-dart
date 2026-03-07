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
embedder="$EMBEDDER"
targetOs="$TARGET_OS"
testPackage="$TEST_PACKAGE"
testPackageDir="packages/$testPackage"
testAppBundleId="com.terwesten.gabriel.cblE2eTestsFlutter"
iosVersion="15-2"
iosDevice="iPhone 13"
androidVersion="27"
androidDevice="pixel_4"

# === Steps ===================================================================

function startCouchbaseServices() {
    case "$(uname)" in
    Darwin)
        ./packages/cbl_e2e_tests/couchbase-services.sh startSyncGatewayMacOS &>/dev/null &
        ./packages/cbl_e2e_tests/couchbase-services.sh waitForSyncGateway
        ;;
    MINGW64* | MSYS* | CYGWIN*)
        ./packages/cbl_e2e_tests/couchbase-services.sh startSyncGatewayWindows &>/dev/null &
        ./packages/cbl_e2e_tests/couchbase-services.sh waitForSyncGateway
        ;;
    *)
        ./packages/cbl_e2e_tests/couchbase-services.sh setupDocker
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

function runUnitTests() {
    requireEnvVar EMBEDDER
    requireEnvVar TEST_PACKAGE

    cd "$testPackageDir"

    case "$embedder" in
    standalone)
        dart test --coverage coverage/dart -r expanded -j 1
        ;;
    flutter)
        flutter test --coverage coverage -r expanded
        ;;
    esac
}

function _verifyFlutterTestResults() {
    local responseDataFile="build/integration_response_data.json"

    if [ ! -f "$responseDataFile" ]; then
        echo "ERROR: No integration test response data found at $responseDataFile"
        echo "Tests may have crashed or timed out without producing results."
        exit 1
    fi

    # The response data is a JSON object where the "result" key is "true" or
    # "false" (as a string). See Response.toJson() in the integration_test
    # package.
    if ! grep -q '"result":"true"' "$responseDataFile" 2>/dev/null &&
        ! grep -q '"result": "true"' "$responseDataFile" 2>/dev/null; then
        echo "ERROR: Integration tests failed. Response data:"
        cat "$responseDataFile"
        exit 1
    fi

    echo "Integration test response data confirms all tests passed."
}

function runE2ETests() {
    requireEnvVar EMBEDDER
    requireEnvVar TARGET_OS
    requireEnvVar TEST_PACKAGE

    local DART_DEFINES="--dart-define enableTimeBomb=true"

    case "$embedder" in
    standalone)
        cd "$testPackageDir"

        export ENABLE_TIME_BOMB=true
        testCommand="dart test --coverage coverage/dart -r expanded -j 1"

        case "$targetOs" in
        macOS)
            # The tests are run with sudo, so that macOS records crash reports.
            # -E preserves the environment so that the Flutter SDK is
            # discoverable for pub workspace resolution.
            sudo -E $testCommand
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
            DART_DEFINES="$DART_DEFINES --dart-define skipPeerSyncTest=true"
            ;;
        Android)
            device="emulator"
            ;;
        Ubuntu)
            # Enable core dumps.
            device="Linux"
            ulimit -c unlimited
            sudo sysctl -w kernel.core_pattern="core.%p"
            ;;
        Windows)
            device="Windows"
            ;;
        esac

        # Build first so we can inspect the bundle before running.
        echo "=== Building Flutter app for $targetOs ==="
        flutter build "${device,,}" --debug $DART_DEFINES 2>&1 || true

        # Diagnostic: inspect the built app bundle for native libraries.
        echo "=== Inspecting Flutter app bundle for native libraries ==="
        case "$targetOs" in
        Ubuntu)
            echo "--- Linux bundle (build/linux/) ---"
            find build/linux/ -type f \( -name '*.so' -o -name '*.so.*' \) 2>/dev/null || echo "No .so files found"
            echo "--- Full bundle lib dir ---"
            ls -laR build/linux/x64/debug/bundle/lib/ 2>/dev/null || echo "bundle/lib/ not found"
            ;;
        Windows)
            echo "--- Windows bundle (build/windows/) ---"
            find build/windows/ -type f -name '*.dll' 2>/dev/null || echo "No .dll files found"
            echo "--- Full runner dir ---"
            ls -laR build/windows/x64/debug/runner/ 2>/dev/null || echo "runner/ not found"
            ;;
        *)
            echo "(Bundle inspection not configured for $targetOs)"
            ;;
        esac
        echo "=== End bundle inspection ==="

        # Note: We would like to collect coverage data from tests, but
        # `flutter drive` does not support the `--coverage` flag. While
        # `flutter test` does, it does not support the `--keep-app-running`
        # flag, which we need to collect logs from devices.
        flutter drive \
            -d "$device" \
            $DART_DEFINES \
            --keep-app-running \
            --driver test_driver/integration_test.dart \
            --target integration_test/e2e_test.dart

        _verifyFlutterTestResults
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

function _collectCblLogsAndroid() {
    ./tools/android-emulator.sh copyAppData
    zip -r appData.zip appData
    mv appData.zip "$testResultsDir"
}

function _collectCblLogsLinux() {
    echo "Collecting Couchbase Lite logs"

    local cblLogsDir="/tmp/cbl_flutter/logs"

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
            _collectCblLogsAndroid
            ;;
        Ubuntu)
            _collectCrashReportsLinuxFlutter
            _collectCblLogsLinux
            ;;
        Windows)
            # TODO(blaugold): collect crash report
            # TODO(blaugold): get cbl logs from device
            ;;
        esac
        ;;
    esac
}

function checkBuildRunnerOutput() {
    requireEnvVar TEST_PACKAGE

    cd "$testPackageDir"

    dart run build_runner build --delete-conflicting-outputs --verbose

    # Verify that the the build output did not change by checking if the repo is dirty.
    # This check is flaky in CI. We check multiple times on the hunch that there is some kind of
    # race condition.
    local checkAttempt=0
    local maxAttempts=5

    while [ $checkAttempt -lt $maxAttempts ]; do
        if [[ -z "$(git status --porcelain **/*.dart)" ]]; then
            exit 0
        fi
        checkAttempt=$((checkAttempt + 1))
        sleep 1
    done

    echo "Build output changed"
    git status --porcelain **/*.dart
    git diff
    exit 1
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
        ./tools/coverage.sh dartToLcov "$testPackageDir"
        ;;
    flutter)
        # Flutter already outputs coverage data as lcov and into the correct
        # location.
        ;;
    esac

    # Install codecove uploader
    case "$OSTYPE" in
    linux*)
        curl -Os https://cli.codecov.io/latest/linux/codecov
        chmod +x codecov
        ;;
    darwin*)
        curl -Os https://cli.codecov.io/latest/macos/codecov
        chmod +x codecov
        ;;
    mingw* | msys* | cygwin*)
        curl -Os https://cli.codecov.io/latest/windows/codecov.exe
        ;;
    esac

    # Upload coverage data
    ./codecov \
        --verbose \
        upload-process \
        --fail-on-error \
        --flag "$flags" \
        --file "$testPackageDir/coverage/lcov.info" \
        --commit-sha "$GITHUB_SHA"
}

"$@"
