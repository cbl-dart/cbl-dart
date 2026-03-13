#!/usr/bin/env bash

set -e

scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
workspaceDir="$(cd "$scriptDir/.." && pwd)"

function isDebug() {
    [[ "${RUNNER_DEBUG:-}" == "1" ]]
}

function retry() {
    local attempts=$1; shift
    local delay=$1; shift
    local n=0
    until "$@"; do
        n=$((n + 1))
        if [ $n -ge $attempts ]; then
            echo "Command failed after $n attempts: $*"
            return 1
        fi
        echo "Attempt $n/$attempts failed, retrying in ${delay}s..."
        sleep "$delay"
    done
}

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
androidVersion="27"
androidDevice="pixel_4"
syncGatewayLogFile="$workspaceDir/.tmp/sync-gateway.log"

# === iOS simulator auto-detection =============================================

function _detectIosSimulator() {
    local runtimeId
    runtimeId=$(xcrun simctl list runtimes -j |
        jq -r '[.runtimes[] | select(.platform == "iOS" and .isAvailable == true)] | last | .identifier // empty')

    if [ -z "$runtimeId" ]; then
        echo "ERROR: No available iOS simulator runtime found" >&2
        xcrun simctl list runtimes >&2
        exit 1
    fi

    local deviceName
    deviceName=$(xcrun simctl list devices available -j |
        jq -r --arg rt "$runtimeId" '.devices[$rt] // [] | map(select(.name | startswith("iPhone"))) | last | .name // empty')

    if [ -z "$deviceName" ]; then
        echo "ERROR: No available iPhone device found for runtime '$runtimeId'" >&2
        xcrun simctl list devices available >&2
        exit 1
    fi

    # Extract version from runtime id (e.g. ...iOS-18-2 -> 18-2)
    iosVersion=$(echo "$runtimeId" | sed 's/.*iOS-//')
    iosDevice="$deviceName"
    echo "Detected iOS simulator: runtime=$runtimeId device=$iosDevice"
}

# === Steps ===================================================================

function startCouchbaseServices() {
    mkdir -p "$(dirname "$syncGatewayLogFile")"

    case "$(uname)" in
    Darwin)
        ./packages/cbl_e2e_tests/couchbase-services.sh startCouchbaseServerMacOS
        ./packages/cbl_e2e_tests/couchbase-services.sh waitForCouchbaseServer
        ./packages/cbl_e2e_tests/couchbase-services.sh initCouchbaseServer
        : >"$syncGatewayLogFile"
        ./packages/cbl_e2e_tests/couchbase-services.sh startSyncGatewayMacOS \
            >>"$syncGatewayLogFile" 2>&1 &
        ./packages/cbl_e2e_tests/couchbase-services.sh waitForSyncGateway
        ;;
    MINGW64* | MSYS* | CYGWIN*)
        ./packages/cbl_e2e_tests/couchbase-services.sh startCouchbaseServerWindows
        ./packages/cbl_e2e_tests/couchbase-services.sh waitForCouchbaseServer
        ./packages/cbl_e2e_tests/couchbase-services.sh initCouchbaseServer
        : >"$syncGatewayLogFile"
        ./packages/cbl_e2e_tests/couchbase-services.sh startSyncGatewayWindows \
            >>"$syncGatewayLogFile" 2>&1 &
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
        _detectIosSimulator
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

        if isDebug; then
            echo "=== Flutter config ==="
            flutter config --list 2>&1 || true
            echo "=== Flutter version ==="
            flutter --version 2>&1 || true
        fi

        local verboseFlag=""
        if isDebug; then verboseFlag="-v"; fi

        # Build the app explicitly when needed:
        # - iOS: always, because we need the bundle for simulator readiness
        #   checks before flutter drive.
        # - Debug mode: always, so we can inspect the bundle afterwards.
        # Otherwise, let flutter drive handle the build implicitly.
        local buildTarget
        case "$targetOs" in
        Ubuntu)   buildTarget="linux" ;;
        macOS)    buildTarget="macos" ;;
        Windows)  buildTarget="windows" ;;
        Android)  buildTarget="apk" ;;
        iOS)      buildTarget="ios" ;;
        *)        buildTarget="$(echo "$device" | tr '[:upper:]' '[:lower:]')" ;;
        esac
        local buildFlags=""
        case "$targetOs" in
        iOS) buildFlags="--simulator --no-codesign" ;;
        esac
        local didExplicitBuild=false
        if [ "$targetOs" = "iOS" ] || isDebug; then
            echo "=== Building Flutter app for $targetOs ==="
            flutter build "$buildTarget" --debug $buildFlags $verboseFlag $DART_DEFINES 2>&1
            didExplicitBuild=true
        fi

        if isDebug; then
            echo "=== Native assets builder cache ==="
            find .dart_tool -path '*/native_assets_builder/*' -type f 2>/dev/null || echo "No native_assets_builder directory found"
            find .dart_tool -path '*/hooks_runner/*' -type f 2>/dev/null || echo "No hooks_runner directory found"
            find .dart_tool -name 'build_output.json' -o -name 'output.json' 2>/dev/null | while read -r f; do
                echo "--- $f ---"
                cat "$f"
                echo ""
            done

            echo "=== Inspecting Flutter app bundle for native libraries ==="
            case "$targetOs" in
            Ubuntu)
                find build/linux/ -type f \( -name '*.so' -o -name '*.so.*' \) 2>/dev/null || echo "No .so files found"
                ls -laR build/linux/x64/debug/bundle/lib/ 2>/dev/null || echo "bundle/lib/ not found"
                ls -laR build/native_assets/ 2>/dev/null || echo "build/native_assets/ not found"
                ;;
            Windows)
                find build/windows/ -type f -name '*.dll' 2>/dev/null || echo "No .dll files found"
                ls -laR build/windows/x64/runner/Debug/ 2>/dev/null || echo "runner/Debug/ not found"
                ;;
            Android)
                if command -v unzip &>/dev/null; then
                    local apk
                    apk=$(find build/app/outputs -name '*.apk' 2>/dev/null | head -1)
                    if [ -n "$apk" ]; then
                        unzip -l "$apk" | grep -E '\.so$' || echo "No .so files in APK"
                    fi
                fi
                ;;
            macOS)
                find build/macos -type f \( -name '*.dylib' -o -name '*.framework' \) 2>/dev/null || echo "No dylib/framework files found"
                ls -laR build/macos/Build/Products/Debug/*.app/Contents/Frameworks/ 2>/dev/null || echo "Frameworks/ not found"
                ;;
            iOS)
                find build/ios -type f \( -name '*.dylib' -o -name '*.framework' \) 2>/dev/null || echo "No dylib/framework files found"
                ls -laR build/ios/iphonesimulator/*.app/Frameworks/ 2>/dev/null || echo "Frameworks/ not found"
                ;;
            esac
            echo "=== End bundle inspection ==="
        fi

        # --- iOS: ensure simulator is fully ready before flutter drive ---
        if [ "$targetOs" = "iOS" ]; then
            echo "=== iOS simulator readiness ==="
            local simId
            simId=$(xcrun simctl list devices booted -j | jq -r '.devices[][] | select(.state == "Booted") | .udid' | head -1)
            if [ -n "$simId" ]; then
                echo "Booted simulator: $simId"

                # Re-confirm boot status (blocks until truly ready).
                echo "Waiting for simulator to be fully ready..."
                xcrun simctl bootstatus "$simId" -b 2>&1 || true

                # Wait for SpringBoard to be responsive — it can lag behind
                # the "Booted" state and cause app launches to hang.
                echo "Warming up SpringBoard..."
                xcrun simctl launch "$simId" com.apple.springboard 2>/dev/null || true
                sleep 5

                if isDebug; then
                    local appBundle
                    appBundle=$(find build/ios -name "Runner.app" -path "*/iphonesimulator/*" -type d 2>/dev/null | head -1)
                    if [ -n "$appBundle" ]; then
                        echo "App bundle: $appBundle"

                        echo "--- Framework architectures ---"
                        for fw in "$appBundle"/Frameworks/*.framework/*; do
                            if [ -f "$fw" ] && file "$fw" | grep -q "Mach-O"; then
                                echo "$fw:"
                                lipo -info "$fw" 2>&1 || true
                            fi
                        done

                        echo "--- Code signing ---"
                        codesign -dvv "$appBundle" 2>&1 || true

                        echo "--- Pre-installing app ---"
                        xcrun simctl install "$simId" "$appBundle" 2>&1 || true

                        echo "--- Test-launching app ---"
                        xcrun simctl launch --terminate-running-process "$simId" "$testAppBundleId" 2>&1 || true
                        sleep 5

                        echo "--- Checking if app process is alive ---"
                        xcrun simctl spawn "$simId" launchctl list 2>&1 | grep -i "runner\|cbl" || echo "App not found in launchctl"

                        echo "--- Recent crash logs ---"
                        find ~/Library/Logs/DiagnosticReports -name "Runner*" -newer "$appBundle" 2>/dev/null || echo "No crash logs"

                        echo "--- Terminate pre-launch ---"
                        xcrun simctl terminate "$simId" "$testAppBundleId" 2>/dev/null || true
                        sleep 2
                    fi
                fi
            else
                echo "ERROR: No booted simulator found — aborting"
                exit 1
            fi
            echo "=== End iOS simulator readiness ==="
        fi

        # Note: We would like to collect coverage data from tests, but
        # `flutter drive` does not support the `--coverage` flag. While
        # `flutter test` does, it does not support the `--keep-app-running`
        # flag, which we need to collect logs from devices.
        local noBuildFlag=""
        if [ "$didExplicitBuild" = true ]; then noBuildFlag="--no-build"; fi
        flutter drive \
            -d "$device" \
            $DART_DEFINES \
            $noBuildFlag \
            --keep-app-running \
            --driver test_driver/integration_test.dart \
            --target integration_test/e2e_test.dart \
            $verboseFlag
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
    if [ -d ~/Library/Logs/DiagnosticReports ]; then
        cp -a ~/Library/Logs/DiagnosticReports "$testResultsDir"
        echo "Copied macOS DiagnosticReports"
    else
        echo "No DiagnosticReports directory found"
    fi
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

function _isAndroidEmulatorReachable() {
    "$ANDROID_HOME/platform-tools/adb" -s "emulator-5554" get-state 2>/dev/null | grep -q "device"
}

function _collectCrashReportsAndroid() {
    if ! _isAndroidEmulatorReachable; then
        echo "Android emulator is not reachable, skipping bugreport collection"
        return 0
    fi
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

function _isIosSimulatorBooted() {
    xcrun simctl list devices booted -j 2>/dev/null | grep -q '"state" : "Booted"'
}

function _collectCblLogsIosSimulator() {
    echo "Collecting Couchbase Lite logs from iOS Simulator app"

    if ! _isIosSimulatorBooted; then
        echo "No booted iOS simulator found, skipping log collection"
        return 0
    fi

    _detectIosSimulator
    ./tools/apple-simulator.sh copyData \
        -o "iOS-$iosVersion" \
        -d "$iosDevice" \
        -b "$testAppBundleId" \
        -f "Library/Caches/cbl_flutter/logs" \
        -t "$testResultsDir"
}

function _collectCblLogsMacOS() {
    echo "Collecting Couchbase Lite logs from macOS app"

    local appDataContainer="$HOME/Library/Containers/$testAppBundleId/Data"
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
    if ! _isAndroidEmulatorReachable; then
        echo "Android emulator is not reachable, skipping app data collection"
        return 0
    fi
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

function _collectCouchbaseServerLogs() {
    echo "Collecting Couchbase Server logs"

    local outputDir="$testResultsDir/couchbase-server-logs"
    mkdir -p "$outputDir"

    case "$(uname)" in
    Darwin)
        local processLog="${RUNNER_TEMP:-/tmp}/couchbase-server-macos.log"
        local appLog="$HOME/Library/Logs/CouchbaseServer.log"
        local httpLog="$HOME/Library/Logs/couchbase-server.log"

        for logFile in "$processLog" "$appLog" "$httpLog"; do
            if [ -f "$logFile" ]; then
                echo "Copying $logFile"
                cp -a "$logFile" "$outputDir/"
            fi
        done
        ;;
    MINGW64*|MSYS*|CYGWIN*)
        local cbsLogDir="/c/Program Files/Couchbase/Server/var/lib/couchbase/logs"
        if [ -d "$cbsLogDir" ]; then
            echo "Copying Couchbase Server logs from $cbsLogDir"
            cp -a "$cbsLogDir"/* "$outputDir/" 2>/dev/null || true
        else
            echo "Couchbase Server log directory not found"
        fi
        ;;
    *)
        ./packages/cbl_e2e_tests/couchbase-services.sh logsCouchbaseServer \
            >"$outputDir/couchbase-server.log" 2>&1 || true
        ;;
    esac
}

function _collectSyncGatewayLogs() {
    echo "Collecting Sync Gateway logs"

    local outputFile="$testResultsDir/sync-gateway.log"

    case "$(uname)" in
    Darwin|MINGW64*|MSYS*|CYGWIN*)
        if [ ! -e "$syncGatewayLogFile" ]; then
            echo "Did not find Sync Gateway log file"
            return 0
        fi

        cp -a "$syncGatewayLogFile" "$outputFile"
        ;;
    *)
        ./packages/cbl_e2e_tests/couchbase-services.sh logsSyncGateway \
            >"$outputFile" || true
        ;;
    esac
}

function collectTestResults() {
    requireEnvVar EMBEDDER
    requireEnvVar TARGET_OS
    requireEnvVar TEST_PACKAGE

    mkdir "$testResultsDir"

    # Wait for crash reports/core dumps.
    sleep 60

    _collectCouchbaseServerLogs
    _collectSyncGatewayLogs

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

    # Install codecov uploader
    case "$OSTYPE" in
    linux*)
        retry 3 10 curl --fail -Os https://cli.codecov.io/latest/linux/codecov
        chmod +x codecov
        ;;
    darwin*)
        retry 3 10 curl --fail -Os https://cli.codecov.io/latest/macos/codecov
        chmod +x codecov
        ;;
    mingw* | msys* | cygwin*)
        retry 3 10 curl --fail -Os https://cli.codecov.io/latest/windows/codecov.exe
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
