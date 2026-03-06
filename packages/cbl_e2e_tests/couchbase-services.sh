#!/usr/bin/env bash

set -e

scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dockerComposeFile="$scriptDir/docker-compose.yaml"
couchbaseServerVersion=8.0.0
syncGatewayVersion=4.0.3
couchbaseServerAdminUser="Administrator"
couchbaseServerAdminPass="password"
couchbaseServerBucket="db"
sgRbacUser="sync_gateway"
sgRbacPass="sync_gateway"

function waitForService() {
    name="$1"
    url="$2"
    maxAttempts=50
    delayBetweenAttempts=5
    attempt=0

    echo "::group::Wait for $name"

    while true; do
        echo "Attempt $attempt to connect to $name"
        curl --silent -o /dev/null "$url" && break

        attempt=$((attempt + 1))

        if ((attempt == maxAttempts)); then
            echo "$name was not reachable after $maxAttempts"
            exit 1
        fi

        sleep $delayBetweenAttempts
    done

    echo "$name is reachable"

    echo "::endgroup::"
}

function waitForSyncGateway() {
    waitForService "Sync Gateway" localhost:4984
}

function waitForCouchbaseServer() {
    waitForService "Couchbase Server" http://localhost:8091/pools
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
    local cbsAppDir="/Applications/Couchbase Server.app"

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

    # Start CBS headlessly to bypass the GUI license dialog that CBS 8.0
    # shows on first launch. Run from the couchbase-core directory so CBS
    # finds its relative paths.
    local cbsCoreDir="$cbsAppDir/Contents/Resources/couchbase-core"
    (cd "$cbsCoreDir" && ./bin/couchbase-server -- -noinput &)
}

function startCouchbaseServerWindows() {
    local cbsMsi="couchbase-server-enterprise_${couchbaseServerVersion}-windows_amd64.msi"
    local cbsUrl="https://packages.couchbase.com/releases/${couchbaseServerVersion}/${cbsMsi}"

    echo "::group::Install Couchbase Server"

    curl -LO "$cbsUrl"
    # /qn for fully silent install. The CouchbaseServer Windows service
    # starts automatically after installation.
    powershell.exe -Command "Start-Process msiexec.exe -Wait -ArgumentList '/i $cbsMsi /qn'"
    rm "$cbsMsi"

    # Ensure the CouchbaseServer service is running. CBS 8.0 may not
    # auto-start the service with fully silent (/qn) install.
    sc.exe start CouchbaseServer || true

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

    cd "$syncGatewayInstallDir"
    bin/sync_gateway \
        '-disable_persistent_config' \
        '-api.admin_interface_authentication=false' \
        '-bootstrap.use_tls_server=false' \
        "$syncGatewayConfig"
}

function startSyncGatewayWindows {
    syncGatewayMsi="couchbase-sync-gateway-community_${syncGatewayVersion}_x86_64.msi"
    syncGatewayUrl="https://packages.couchbase.com/releases/couchbase-sync-gateway/$syncGatewayVersion/$syncGatewayMsi"
    syncGatewayConfig="$(cygpath -w "$scriptDir/sync-gateway-config-native.json")"

    echo "::group::Install Sync Gateway"

    curl "$syncGatewayUrl" -o "$syncGatewayMsi"

    powershell.exe -Command "Start-Process msiexec.exe -Wait -ArgumentList '/i $syncGatewayMsi /passive'"

    # Stop the service which was started during installation.
    sc.exe stop SyncGateway || true

    rm "$syncGatewayMsi"

    echo "::endgroup::"

    "C:\Program Files\Couchbase\Sync Gateway\sync_gateway.exe" \
        '-disable_persistent_config' \
        '-api.admin_interface_authentication=false' \
        '-bootstrap.use_tls_server=false' \
        "$syncGatewayConfig"
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
