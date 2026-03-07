#!/usr/bin/env bash

set -e

CBS_HOST="couchbase-server"
CBS_PORT=8091
CBS_ADMIN_USER="Administrator"
CBS_ADMIN_PASS="password"
BUCKET_NAME="db"
SG_RBAC_USER="sync_gateway"
SG_RBAC_PASS="sync_gateway"

echo "Waiting for Couchbase Server REST API..."
until curl -sf "http://${CBS_HOST}:${CBS_PORT}/pools" >/dev/null 2>&1; do
    sleep 2
done
echo "Couchbase Server REST API is ready"

echo "Initializing cluster..."
curl -sf -X POST "http://${CBS_HOST}:${CBS_PORT}/clusterInit" \
    -d "hostname=127.0.0.1" \
    -d "dataPath=/opt/couchbase/var/lib/couchbase/data" \
    -d "indexPath=/opt/couchbase/var/lib/couchbase/data" \
    -d "services=kv,index,n1ql" \
    -d "memoryQuota=256" \
    -d "indexMemoryQuota=256" \
    -d "username=${CBS_ADMIN_USER}" \
    -d "password=${CBS_ADMIN_PASS}" \
    -d "port=SAME" \
    -d "indexerStorageMode=plasma"

echo "Setting index replicas to 0 for single-node cluster..."
curl -sf -X POST "http://${CBS_HOST}:${CBS_PORT}/settings/indexes" \
    -u "${CBS_ADMIN_USER}:${CBS_ADMIN_PASS}" \
    -d "numReplica=0" \
    -d "storageMode=plasma"

echo "Creating bucket '${BUCKET_NAME}'..."
curl -sf -X POST "http://${CBS_HOST}:${CBS_PORT}/pools/default/buckets" \
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
curl -sf -X POST "http://${CBS_HOST}:${CBS_PORT}/pools/default/buckets/${BUCKET_NAME}" \
    -u "${CBS_ADMIN_USER}:${CBS_ADMIN_PASS}" \
    -d "enableCrossClusterVersioning=true"

echo "Creating RBAC user '${SG_RBAC_USER}' for Sync Gateway..."
curl -sf -X PUT "http://${CBS_HOST}:${CBS_PORT}/settings/rbac/users/local/${SG_RBAC_USER}" \
    -u "${CBS_ADMIN_USER}:${CBS_ADMIN_PASS}" \
    -d "password=${SG_RBAC_PASS}" \
    -d "roles=bucket_full_access[${BUCKET_NAME}],bucket_admin[${BUCKET_NAME}]"

echo "Couchbase Server initialization complete."
