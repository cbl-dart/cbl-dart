#!/usr/bin/env bash

set -e

scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dockerComposeFile="$scriptDir/docker-compose.yaml"
syncGatewayVersion=3.0.3

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

function startSyncGatewayMacOS {
    optDir="/opt"
    syncGatewayZip="couchbase-sync-gateway-community_${syncGatewayVersion}_x86_64.zip"
    syncGatewayUrl="https://packages.couchbase.com/releases/couchbase-sync-gateway/$syncGatewayVersion/$syncGatewayZip"
    syncGatewayInstallDir="$optDir/couchbase-sync-gateway"
    syncGatewayUser="sync_gateway"
    syncGatewayConfig="$scriptDir/sync-gateway-config.json"

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
        "$syncGatewayConfig"
}

function startSyncGatewayWindows {
    syncGatewayMsi="couchbase-sync-gateway-community_${syncGatewayVersion}_x86_64.msi"
    syncGatewayUrl="https://packages.couchbase.com/releases/couchbase-sync-gateway/$syncGatewayVersion/$syncGatewayMsi"
    syncGatewayConfig="$(cygpath -w "$scriptDir/sync-gateway-config.json")"

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
        "$syncGatewayConfig"
}

function startDockerService {
    id="$1"
    name="$2"
    echo "::group::Start $name"
    docker-compose -f "$dockerComposeFile" up -d "$id"
    echo "::endgroup::"
}

function setupDocker() {
    startDockerService sync-gateway "Sync Gateway"
    waitForSyncGateway
}

function teardownDocker() {
    docker-compose -f "$dockerComposeFile" down
}

"$@"
