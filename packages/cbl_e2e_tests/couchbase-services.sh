#!/usr/bin/env bash

set -e

scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dockerComposeFile="$scriptDir/docker-compose.yaml"
# The host installers for Couchbase Server 8.0 are currently not starting
# reliably on GitHub-hosted macOS and Windows runners. Keep native host-based
# E2E startup on the stable 7.6 line; Docker-based Linux E2E still uses 8.0.
couchbaseServerVersion=7.6.9
syncGatewayVersion=4.0.3
couchbaseServerAdminUser="Administrator"
couchbaseServerAdminPass="password"
couchbaseServerBucket="db"
sgRbacUser="sync_gateway"
sgRbacPass="sync_gateway"
macOSCouchbaseServerLogFile="${RUNNER_TEMP:-/tmp}/couchbase-server-macos.log"
macOSCouchbaseAppLogFile="$HOME/Library/Logs/CouchbaseServer.log"
macOSCouchbaseHTTPLogFile="$HOME/Library/Logs/couchbase-server.log"
macOSCouchbaseAppDir="/Applications/Couchbase Server.app"
macOSCouchbaseCouchJSFile="$macOSCouchbaseAppDir/Contents/Resources/couchbase-core/bin/couchjs"
syncGatewayMacOSLogFile="${RUNNER_TEMP:-/tmp}/sync-gateway-macos.log"
syncGatewayWindowsLogFile="${RUNNER_TEMP:-/tmp}/sync-gateway-windows.log"

function waitForService() {
    name="$1"
    url="$2"
    diagnostics="${3:-}"
    maxAttempts=10
    delayBetweenAttempts=5
    attempt=0

    echo "::group::Wait for $name"

    while true; do
        echo "Attempt $attempt to connect to $name"
        curl --silent -o /dev/null "$url" && break

        attempt=$((attempt + 1))

        if ((attempt == maxAttempts)); then
            echo "$name was not reachable after $maxAttempts"
            if [ -n "$diagnostics" ]; then
                "$diagnostics"
            fi
            exit 1
        fi

        sleep $delayBetweenAttempts
    done

    echo "$name is reachable"

    echo "::endgroup::"
}

function waitForSyncGateway() {
    waitForService \
        "Sync Gateway" \
        localhost:4984 \
        dumpSyncGatewayDiagnostics
}

function dumpCouchbaseServerDiagnostics() {
    echo "::group::Couchbase Server diagnostics"

    case "$(uname)" in
    Darwin)
        ps aux | grep -i '[c]ouchbase' || true
        ls -ld "$macOSCouchbaseAppDir" || true
        ls -l "$macOSCouchbaseCouchJSFile" || true
        if [ -f "$macOSCouchbaseServerLogFile" ]; then
            echo "-- $macOSCouchbaseServerLogFile --"
            tail -n 200 "$macOSCouchbaseServerLogFile" || true
        fi
        if [ -f "$macOSCouchbaseAppLogFile" ]; then
            echo "-- $macOSCouchbaseAppLogFile --"
            tail -n 200 "$macOSCouchbaseAppLogFile" || true
        fi
        if [ -f "$macOSCouchbaseHTTPLogFile" ]; then
            echo "-- $macOSCouchbaseHTTPLogFile --"
            tail -n 200 "$macOSCouchbaseHTTPLogFile" || true
        fi
        ;;
    MINGW64* | MSYS* | CYGWIN*)
        powershell.exe -Command "\$service = Get-Service | Where-Object { \$_.Name -like 'CouchbaseServer*' -or \$_.DisplayName -like 'Couchbase Server*' } | Select-Object -First 1; if (\$null -eq \$service) { Write-Host 'No Couchbase service found'; exit 0 }; \$service | Format-List -Property Name,DisplayName,Status,StartType" || true
        ;;
    esac

    echo "::endgroup::"
}

function dumpSyncGatewayDiagnostics() {
    echo "::group::Sync Gateway diagnostics"

    case "$(uname)" in
    Darwin)
        ps aux | grep -i '[s]ync_gateway' || true
        if [ -f "$syncGatewayMacOSLogFile" ]; then
            echo "-- $syncGatewayMacOSLogFile --"
            tail -n 200 "$syncGatewayMacOSLogFile" || true
        fi
        ;;
    MINGW64* | MSYS* | CYGWIN*)
        powershell.exe -Command "Get-Process sync_gateway -ErrorAction SilentlyContinue | Format-List -Property Id,ProcessName,Path,StartTime" || true
        if [ -f "$syncGatewayWindowsLogFile" ]; then
            echo "-- $syncGatewayWindowsLogFile --"
            tail -n 200 "$syncGatewayWindowsLogFile" || true
        fi
        ;;
    *)
        docker compose -f "$dockerComposeFile" ps || true
        docker compose -f "$dockerComposeFile" logs sync-gateway || true
        ;;
    esac

    echo "::endgroup::"
}

function waitForCouchbaseServer() {
    waitForService \
        "Couchbase Server" \
        http://localhost:8091/pools \
        dumpCouchbaseServerDiagnostics
}

function waitForCouchbaseQueryService() {
    local maxAttempts=30
    local delayBetweenAttempts=2
    local attempt=0
    local response

    echo "::group::Wait for Couchbase Query Service"

    while true; do
        echo "Attempt $attempt to query Couchbase Query Service"
        response="$(
            curl --silent --show-error -X POST http://localhost:8093/query/service \
                -u "${couchbaseServerAdminUser}:${couchbaseServerAdminPass}" \
                --data-urlencode 'statement=SELECT 1;' 2>&1 || true
        )"

        if echo "$response" | grep -q '"status":"success"'; then
            break
        fi

        attempt=$((attempt + 1))
        if ((attempt == maxAttempts)); then
            echo "Couchbase Query Service was not ready after $maxAttempts attempts"
            if [ -n "$response" ]; then
                echo "$response"
            fi
            dumpCouchbaseServerDiagnostics
            exit 1
        fi

        sleep $delayBetweenAttempts
    done

    echo "Couchbase Query Service is reachable"
    echo "::endgroup::"
}

function initCouchbaseServer() {
    echo "::group::Initialize Couchbase Server"

    echo "Initializing cluster..."
    # Omit dataPath/indexPath so CBS uses its platform-specific defaults.
    curl -sf -X POST http://localhost:8091/clusterInit \
        -d "hostname=127.0.0.1" \
        -d "services=kv,index,n1ql" \
        -d "memoryQuota=256" \
        -d "indexMemoryQuota=256" \
        -d "username=${couchbaseServerAdminUser}" \
        -d "password=${couchbaseServerAdminPass}" \
        -d "port=SAME" \
        -d "indexerStorageMode=plasma"

    echo "Setting index replicas to 0..."
    curl -sf -X POST http://localhost:8091/settings/indexes \
        -u "${couchbaseServerAdminUser}:${couchbaseServerAdminPass}" \
        -d "numReplica=0" \
        -d "storageMode=plasma"

    echo "Creating bucket '${couchbaseServerBucket}'..."
    curl -sf -X POST http://localhost:8091/pools/default/buckets \
        -u "${couchbaseServerAdminUser}:${couchbaseServerAdminPass}" \
        -d "name=${couchbaseServerBucket}" \
        -d "ramQuota=100" \
        -d "bucketType=couchbase" \
        -d "flushEnabled=1"

    echo "Waiting for bucket to be ready..."
    local attempt=0
    until curl -sf "http://localhost:8091/pools/default/buckets/${couchbaseServerBucket}" \
        -u "${couchbaseServerAdminUser}:${couchbaseServerAdminPass}" | grep -q '"status":"healthy"'; do
        attempt=$((attempt + 1))
        if ((attempt > 30)); then
            echo "Bucket was not ready after 30 attempts"
            exit 1
        fi
        sleep 2
    done

    echo "Enabling cross-cluster versioning on bucket '${couchbaseServerBucket}'..."
    curl -sf -X POST "http://localhost:8091/pools/default/buckets/${couchbaseServerBucket}" \
        -u "${couchbaseServerAdminUser}:${couchbaseServerAdminPass}" \
        -d "enableCrossClusterVersioning=true"

    echo "Creating RBAC user '${sgRbacUser}'..."
    curl -sf -X PUT "http://localhost:8091/settings/rbac/users/local/${sgRbacUser}" \
        -u "${couchbaseServerAdminUser}:${couchbaseServerAdminPass}" \
        -d "password=${sgRbacPass}" \
        -d "roles=bucket_full_access[${couchbaseServerBucket}],bucket_admin[${couchbaseServerBucket}]"

    waitForCouchbaseQueryService

    echo "Couchbase Server initialization complete"
    echo "::endgroup::"
}

function startCouchbaseServerMacOS() {
    local arch
    if [ "$(uname -m)" = "arm64" ]; then
        arch="arm64"
    else
        arch="x86_64"
    fi
    local cbsDmg="couchbase-server-enterprise_${couchbaseServerVersion}-macos_${arch}.dmg"
    local cbsUrl="https://packages.couchbase.com/releases/${couchbaseServerVersion}/${cbsDmg}"
    local cbsAppDir="$macOSCouchbaseAppDir"
    local cbsExecutable="$cbsAppDir/Contents/MacOS/Couchbase Server"

    if [ ! -d "$cbsAppDir" ]; then
        echo "::group::Install Couchbase Server"

        curl -LO "$cbsUrl"
        local mountOutput
        mountOutput="$(hdiutil attach "$cbsDmg" -nobrowse)"
        local mountPoint
        mountPoint="$(echo "$mountOutput" | grep -o '/Volumes/.*' | head -1)"
        sudo cp -R "$mountPoint/Couchbase Server.app" /Applications/
        hdiutil detach "$mountPoint" -quiet
        rm -f "$cbsDmg"

        # Remove quarantine attribute to prevent Gatekeeper from blocking.
        sudo xattr -rc "$cbsAppDir"

        echo "::endgroup::"
    fi

    # The macOS startup script rewrites files inside the app bundle before
    # launching Erlang, so the runner user must own the copied app.
    sudo chown -R "$(id -un):$(id -gn)" "$cbsAppDir"
    chmod -R u+w "$cbsAppDir"

    if [ ! -x "$cbsExecutable" ]; then
        echo "Could not find Couchbase Server executable at $cbsExecutable"
        exit 1
    fi

    rm -f "$macOSCouchbaseServerLogFile"
    nohup "$cbsExecutable" >"$macOSCouchbaseServerLogFile" 2>&1 </dev/null &
}

function startCouchbaseServerWindows() {
    local cbsMsi="couchbase-server-enterprise_${couchbaseServerVersion}-windows_amd64.msi"
    local cbsUrl="https://packages.couchbase.com/releases/${couchbaseServerVersion}/${cbsMsi}"
    local serviceName

    echo "::group::Install Couchbase Server"

    curl -LO "$cbsUrl"
    powershell.exe -Command "Start-Process msiexec.exe -Wait -ArgumentList '/i $cbsMsi /qn /norestart'"
    rm "$cbsMsi"

    serviceName="$(
        powershell.exe -Command "(Get-Service | Where-Object { \$_.Name -like 'CouchbaseServer*' -or \$_.DisplayName -like 'Couchbase Server*' } | Select-Object -First 1 -ExpandProperty Name)" |
            tr -d '\r'
    )"

    if [ -z "$serviceName" ]; then
        echo "Could not find the Couchbase Server Windows service"
        exit 1
    fi

    powershell.exe -Command "\$service = Get-Service -Name '$serviceName'; if (\$service.Status -ne 'Running') { Start-Service -Name '$serviceName'; \$service.WaitForStatus('Running', [TimeSpan]::FromMinutes(3)) }; Get-Service -Name '$serviceName' | Format-List -Property Name,DisplayName,Status,StartType"

    echo "::endgroup::"
}

function startSyncGatewayMacOS {
    optDir="/opt"
    syncGatewayZip="couchbase-sync-gateway-community_${syncGatewayVersion}_x86_64.zip"
    syncGatewayUrl="https://packages.couchbase.com/releases/couchbase-sync-gateway/$syncGatewayVersion/$syncGatewayZip"
    syncGatewayInstallDir="$optDir/couchbase-sync-gateway"
    syncGatewayUser="sync_gateway"
    syncGatewayConfig="$scriptDir/sync-gateway-config-native.json"

    if [ ! -d "$syncGatewayInstallDir" ]; then
        echo "::group::Install Sync Gateway"

        curl "$syncGatewayUrl" -o "$syncGatewayZip"
        sudo unzip "$syncGatewayZip" -d "$optDir"
        rm "$syncGatewayZip"

        sudo sysadminctl -addUser "$syncGatewayUser"
        sudo dseditgroup -o create "$syncGatewayUser"
        sudo dseditgroup -o edit -a "$syncGatewayUser" -t user "$syncGatewayUser"

        echo "::endgroup::"
    fi

    rm -f "$syncGatewayMacOSLogFile"
    "$syncGatewayInstallDir/bin/sync_gateway" \
        '-disable_persistent_config' \
        '-api.admin_interface_authentication=false' \
        '-bootstrap.use_tls_server=false' \
        "$syncGatewayConfig" \
        >"$syncGatewayMacOSLogFile" 2>&1
}

function startSyncGatewayWindows {
    syncGatewayMsi="couchbase-sync-gateway-community_${syncGatewayVersion}_x86_64.msi"
    syncGatewayUrl="https://packages.couchbase.com/releases/couchbase-sync-gateway/$syncGatewayVersion/$syncGatewayMsi"
    syncGatewayConfig="$(cygpath -w "$scriptDir/sync-gateway-config-native.json")"

    echo "::group::Install Sync Gateway"

    curl "$syncGatewayUrl" -o "$syncGatewayMsi"

    powershell.exe -Command "Start-Process msiexec.exe -Wait -ArgumentList '/i $syncGatewayMsi /passive'"

    # Stop the service which was started during installation and wait until
    # it has fully released its process and ports before launching the test
    # instance with our custom config.
    powershell.exe -Command "\
        \$service = Get-Service -Name 'SyncGateway' -ErrorAction SilentlyContinue; \
        if (\$null -ne \$service) { \
            if (\$service.Status -ne 'Stopped') { \
                Stop-Service -Name 'SyncGateway' -Force -ErrorAction SilentlyContinue; \
                \$service.WaitForStatus('Stopped', [TimeSpan]::FromMinutes(2)); \
            } \
        }; \
        Get-Process sync_gateway -ErrorAction SilentlyContinue | Stop-Process -Force; \
        Start-Sleep -Seconds 2"

    rm "$syncGatewayMsi"

    echo "::endgroup::"

    rm -f "$syncGatewayWindowsLogFile"
    "C:\Program Files\Couchbase\Sync Gateway\sync_gateway.exe" \
        '-disable_persistent_config' \
        '-api.admin_interface_authentication=false' \
        '-bootstrap.use_tls_server=false' \
        "$syncGatewayConfig" \
        >"$syncGatewayWindowsLogFile" 2>&1
}

function startDockerService {
    id="$1"
    name="$2"
    echo "::group::Start $name"
    docker compose -f "$dockerComposeFile" up -d "$id"
    echo "::endgroup::"
}

function setupDocker() {
    echo "::group::Start Couchbase services"
    docker compose -f "$dockerComposeFile" up -d
    echo "::endgroup::"
    waitForSyncGateway
}

function teardownDocker() {
    docker compose -f "$dockerComposeFile" down
}

"$@"
