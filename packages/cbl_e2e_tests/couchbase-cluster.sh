#!/usr/bin/env bash

set -e

scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dockerComposeFile="$scriptDir/docker-compose.yaml"
initCouchbaseServerScript="$scriptDir/init-couchbase-server.sh"
couchbaseServerVersionMacOS=6.6.0
syncGatewayVersionMacOS=2.8.2

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

function waitForCouchbaseServer() {
    waitForService "Couchbase Server" localhost:8091
}

function waitForSyncGateway() {
    waitForService "Sync Gateway" localhost:4984
}

function installCouchbaseServerMacOS {
    applicationsDir="/Applications"
    couchbaseServerDMG="couchbase-server-community_$couchbaseServerVersionMacOS-macos_x86_64.dmg"
    couchbaseServerUrl="https://packages.couchbase.com/releases/$couchbaseServerVersionMacOS/$couchbaseServerDMG"
    couchbaseServerAppName="Couchbase Server.app"
    couchbaseServerDMGMountPoint="/Volumes/Couchbase Installer "
    couchbaseServerApp="$applicationsDir/$couchbaseServerAppName"
    couchbaseServerAppBin="$couchbaseServerApp/Contents/Resources/couchbase-core/bin"

    echo "::group::Install Couchbase Server"

    curl "$couchbaseServerUrl" -o "$couchbaseServerDMG"
    sudo hdiutil attach "$couchbaseServerDMG"
    cp -R "$couchbaseServerDMGMountPoint/$couchbaseServerAppName" "$applicationsDir"
    sudo hdiutil detach "$couchbaseServerDMGMountPoint"
    rm "$couchbaseServerDMG"

    sudo xattr -d -r com.apple.quarantine "$couchbaseServerApp"
    open "$couchbaseServerApp"

    export PATH="$couchbaseServerAppBin:$PATH"

    # Make server reachable under "couchbase" host name so that
    # the Sync Gatway config can use the same server address for Docker
    # and direct install.
    echo "127.0.0.1 couchbase" | sudo tee -a /etc/hosts

    echo "::endgroup::"
}

function installSyncGatewayMacOS {
    optDir="/opt"
    syncGatewayZip="couchbase-sync-gateway-community_${syncGatewayVersionMacOS}_x86_64.zip"
    syncGatewayUrl="https://packages.couchbase.com/releases/couchbase-sync-gateway/$syncGatewayVersionMacOS/$syncGatewayZip"
    syncGatewayInstallDir="$optDir/couchbase-sync-gateway"
    syncGatewayUser="sync_gateway"
    syncGatewayConfig="$scriptDir/sync-gateway-config.json"

    echo "::group::Install Sync Gateway"

    curl "$syncGatewayUrl" -o "$syncGatewayZip"
    sudo unzip "$syncGatewayZip" -d "$optDir"
    rm "$syncGatewayZip"

    sudo sysadminctl -addUser "$syncGatewayUser"
    sudo dseditgroup -o create "$syncGatewayUser"
    sudo dseditgroup -o edit -a "$syncGatewayUser" -t user "$syncGatewayUser"

    cd "$syncGatewayInstallDir/service"
    sudo ./sync_gateway_service_install.sh --cfgpath="$syncGatewayConfig"

    echo "::endgroup::"
}

function setupMacOS() {
    installCouchbaseServerMacOS
    waitForCouchbaseServer
    "$initCouchbaseServerScript"
    installSyncGatewayMacOS
    waitForSyncGateway
}

function startDockerService {
    id="$1"
    name="$2"
    echo "::group::Start $name"
    docker-compose -f "$dockerComposeFile" up -d "$id"
    echo "::endgroup::"
}

function initCouchbaseServerDocker() {
    docker run \
        --rm \
        -v "$initCouchbaseServerScript:/init.sh:ro" \
        --network cbl_e2e_tests_default \
        couchbase:community-6.6.0 \
        /init.sh
}

function setupDocker() {
    startDockerService couchbase "Couchbase Server"
    waitForCouchbaseServer
    initCouchbaseServerDocker
    startDockerService sync-gateway "Sync Gateway"
    waitForSyncGateway
}

function teardownDocker() {
    docker-compose -f "$dockerComposeFile" down
}

"$@"
