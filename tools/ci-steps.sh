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
iosVersion="18-4"
iosDevice="iPhone 16"
androidVersion="27"
androidDevice="pixel_4"

# === Steps ===================================================================

function startCouchbaseServices() {
    case "$(uname)" in
    Darwin)
        ./packages/cbl_e2e_tests/couchbase-services.sh startSyncGatewayMacOS &
        ./packages/cbl_e2e_tests/couchbase-services.sh waitForSyncGateway
        ;;
    MINGW64* | MSYS* | CYGWIN*)
        ./packages/cbl_e2e_tests/couchbase-services.sh startSyncGatewayWindows &
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

        # --- Diagnostic: Flutter native assets configuration ---
        echo "=== Flutter config ==="
        flutter config --list 2>&1 || true
        echo "=== Flutter version ==="
        flutter --version 2>&1 || true

        # Build the app. Map device names to build sub-commands.
        echo "=== Building Flutter app for $targetOs ==="
        local buildTarget
        case "$targetOs" in
        Ubuntu)   buildTarget="linux" ;;
        macOS)    buildTarget="macos" ;;
        Windows)  buildTarget="windows" ;;
        Android)  buildTarget="apk" ;;
        iOS)      buildTarget="ios" ;;
        *)        buildTarget="$(echo "$device" | tr '[:upper:]' '[:lower:]')" ;;
        esac
        echo "Build target: $buildTarget"
        local buildFlags=""
        case "$targetOs" in
        iOS) buildFlags="--simulator --no-codesign" ;;
        esac
        flutter build "$buildTarget" --debug $buildFlags -v $DART_DEFINES 2>&1

        # --- Diagnostic: check for native assets builder output ---
        echo "=== Native assets builder cache ==="
        # This directory contains the build hook output when Flutter invokes it.
        find .dart_tool -path '*/native_assets_builder/*' -type f 2>/dev/null || echo "No native_assets_builder directory found"
        find .dart_tool -path '*/hooks_runner/*' -type f 2>/dev/null || echo "No hooks_runner directory found"
        # Show the build output JSON if it exists (contains registered assets).
        find .dart_tool -name 'build_output.json' -o -name 'output.json' 2>/dev/null | while read -r f; do
            echo "--- $f ---"
            cat "$f"
            echo ""
        done

        # --- Diagnostic: inspect the built app bundle for native libraries ---
        echo "=== Inspecting Flutter app bundle for native libraries ==="
        case "$targetOs" in
        Ubuntu)
            echo "--- Linux .so files ---"
            find build/linux/ -type f \( -name '*.so' -o -name '*.so.*' \) 2>/dev/null || echo "No .so files found"
            echo "--- Full bundle lib dir ---"
            ls -laR build/linux/x64/debug/bundle/lib/ 2>/dev/null || echo "bundle/lib/ not found"
            echo "--- Native assets staging dir (build/native_assets/) ---"
            ls -laR build/native_assets/ 2>/dev/null || echo "build/native_assets/ not found"
            echo "--- CMake install log (cmake_install.cmake) ---"
            grep -A2 'native_assets' build/linux/x64/debug/cmake_install.cmake 2>/dev/null || echo "No native_assets in cmake_install.cmake"
            echo "--- generated_config.cmake PROJECT_DIR ---"
            grep 'PROJECT_DIR' linux/flutter/ephemeral/generated_config.cmake 2>/dev/null || echo "generated_config.cmake not found"
            ;;
        Windows)
            echo "--- Windows .dll files ---"
            find build/windows/ -type f -name '*.dll' 2>/dev/null || echo "No .dll files found"
            echo "--- Full runner dir ---"
            ls -laR build/windows/x64/runner/Debug/ 2>/dev/null || echo "runner/Debug/ not found"
            ;;
        Android)
            echo "--- APK native libs ---"
            if command -v unzip &>/dev/null; then
                local apk
                apk=$(find build/app/outputs -name '*.apk' 2>/dev/null | head -1)
                if [ -n "$apk" ]; then
                    echo "APK: $apk"
                    unzip -l "$apk" | grep -E '\.so$' || echo "No .so files in APK"
                else
                    echo "No APK found in build/app/outputs/"
                fi
            fi
            ;;
        macOS)
            echo "--- macOS app bundle ---"
            find build/macos -type f \( -name '*.dylib' -o -name '*.framework' \) 2>/dev/null || echo "No dylib/framework files found"
            echo "--- Frameworks dir ---"
            ls -laR build/macos/Build/Products/Debug/*.app/Contents/Frameworks/ 2>/dev/null || echo "Frameworks/ not found"
            ;;
        iOS)
            echo "--- iOS app bundle ---"
            find build/ios -type f \( -name '*.dylib' -o -name '*.framework' \) 2>/dev/null || echo "No dylib/framework files found"
            echo "--- Frameworks dir ---"
            ls -laR build/ios/iphonesimulator/*.app/Frameworks/ 2>/dev/null || echo "Frameworks/ not found"
            ;;
        *)
            echo "(Bundle inspection not configured for $targetOs)"
            ;;
        esac
        echo "=== End bundle inspection ==="

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

                # Verify the app bundle exists and inspect it.
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

                    # Pre-install the app and verify it launches before
                    # handing off to flutter drive.
                    echo "--- Pre-installing app ---"
                    xcrun simctl install "$simId" "$appBundle" 2>&1 || true

                    echo "--- Test-launching app ---"
                    xcrun simctl launch --terminate-running-process "$simId" "$testAppBundleId" 2>&1 || true
                    sleep 5

                    echo "--- Checking if app process is alive ---"
                    xcrun simctl spawn "$simId" launchctl list 2>&1 | grep -i "runner\|cbl" || echo "App not found in launchctl"

                    echo "--- Recent crash logs ---"
                    find ~/Library/Logs/DiagnosticReports -name "Runner*" -newer "$appBundle" 2>/dev/null || echo "No crash logs"

                    # Clean up: terminate the test launch so flutter drive
                    # starts fresh.
                    echo "--- Terminate pre-launch ---"
                    xcrun simctl terminate "$simId" "$testAppBundleId" 2>/dev/null || true
                    sleep 2
                else
                    echo "WARNING: No Runner.app found — skipping pre-launch"
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
        flutter drive \
            -d "$device" \
            $DART_DEFINES \
            --keep-app-running \
            --driver test_driver/integration_test.dart \
            --target integration_test/e2e_test.dart \
            -v
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
