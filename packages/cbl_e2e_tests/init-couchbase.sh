#!/usr/bin/env bash

set -e

CBS_HOST="${CBS_HOST:-couchbase-server}"
CBS_PORT="${CBS_PORT:-8091}"
# The hostname the node should use to identify itself. In Docker this should be
# 127.0.0.1 (the node's own loopback) even though we connect via the service
# name.
CBS_CLUSTER_HOSTNAME="${CBS_CLUSTER_HOSTNAME:-${CBS_HOST}}"
CBS_ADMIN_USER="${CBS_ADMIN_USER:-Administrator}"
CBS_ADMIN_PASS="${CBS_ADMIN_PASS:-password}"
BUCKET_NAME="${BUCKET_NAME:-db}"
SG_RBAC_USER="${SG_RBAC_USER:-sync_gateway}"
SG_RBAC_PASS="${SG_RBAC_PASS:-sync_gateway}"

# Retry a command up to $1 times with $2 second delay between attempts.
retry() {
    local max_attempts=$1; shift
    local delay=$1; shift
    local attempt=0
    until "$@"; do
        attempt=$((attempt + 1))
        if ((attempt >= max_attempts)); then
            echo "Command failed after $max_attempts attempts: $*"
            return 1
        fi
        echo "Attempt $attempt/$max_attempts failed, retrying in ${delay}s..."
        sleep "$delay"
    done
}

echo "Waiting for Couchbase Server REST API..."
until curl -sf "http://${CBS_HOST}:${CBS_PORT}/pools" >/dev/null 2>&1; do
    sleep 2
done
echo "Couchbase Server REST API is ready"

echo "Initializing cluster..."
retry 10 5 curl -sf -X POST "http://${CBS_HOST}:${CBS_PORT}/clusterInit" \
    -d "hostname=${CBS_CLUSTER_HOSTNAME}" \
    -d "services=kv,index,n1ql" \
    -d "memoryQuota=256" \
    -d "indexMemoryQuota=256" \
    -d "username=${CBS_ADMIN_USER}" \
    -d "password=${CBS_ADMIN_PASS}" \
    -d "port=SAME" \
    -d "indexerStorageMode=plasma"

echo "Setting index replicas to 0 for single-node cluster..."
retry 5 3 curl -sf -X POST "http://${CBS_HOST}:${CBS_PORT}/settings/indexes" \
    -u "${CBS_ADMIN_USER}:${CBS_ADMIN_PASS}" \
    -d "numReplica=0" \
    -d "storageMode=plasma"

echo "Creating bucket '${BUCKET_NAME}'..."
retry 5 3 curl -sf -X POST "http://${CBS_HOST}:${CBS_PORT}/pools/default/buckets" \
    -u "${CBS_ADMIN_USER}:${CBS_ADMIN_PASS}" \
    -d "name=${BUCKET_NAME}" \
    -d "ramQuota=100" \
    -d "bucketType=couchbase" \
    -d "flushEnabled=1"

echo "Waiting for bucket '${BUCKET_NAME}' to be ready..."
attempt=0
until curl -sf "http://${CBS_HOST}:${CBS_PORT}/pools/default/buckets/${BUCKET_NAME}" \
    -u "${CBS_ADMIN_USER}:${CBS_ADMIN_PASS}" | grep -q '"status":"healthy"'; do
    attempt=$((attempt + 1))
    if ((attempt > 30)); then
        echo "Bucket was not ready after 30 attempts"
        exit 1
    fi
    sleep 2
done
echo "Bucket '${BUCKET_NAME}' is ready"

echo "Enabling cross-cluster versioning on bucket '${BUCKET_NAME}'..."
retry 5 3 curl -sf -X POST "http://${CBS_HOST}:${CBS_PORT}/pools/default/buckets/${BUCKET_NAME}" \
    -u "${CBS_ADMIN_USER}:${CBS_ADMIN_PASS}" \
    -d "enableCrossClusterVersioning=true"

echo "Creating RBAC user '${SG_RBAC_USER}' for Sync Gateway..."
retry 5 3 curl -sf -X PUT "http://${CBS_HOST}:${CBS_PORT}/settings/rbac/users/local/${SG_RBAC_USER}" \
    -u "${CBS_ADMIN_USER}:${CBS_ADMIN_PASS}" \
    -d "password=${SG_RBAC_PASS}" \
    -d "roles=bucket_full_access[${BUCKET_NAME}],bucket_admin[${BUCKET_NAME}]"

echo "Couchbase Server initialization complete."
