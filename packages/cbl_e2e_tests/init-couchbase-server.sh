#!/usr/bin/env bash

set -e

serverAddress=couchbase
clusterUsername=Admin
clusterPassword=password

echo "::group::Init Couchbase Server"

# Create a one node cluster
couchbase-cli cluster-init \
    -c "$serverAddress" \
    --cluster-username "$clusterUsername" \
    --cluster-password "$clusterPassword" \
    --services data,index,query \
    --cluster-ramsize 256 \
    --cluster-index-ramsize 256

# Create the default bucket
couchbase-cli bucket-create \
    -c "$serverAddress" \
    -u "$clusterUsername" \
    -p "$clusterPassword" \
    --bucket default \
    --bucket-type couchbase \
    --bucket-ramsize 100

# Create the Sync Gateway RBAC user
couchbase-cli user-manage \
    -c "$serverAddress" \
    -u "$clusterUsername" \
    -p "$clusterPassword" \
    --set \
    --auth-domain local \
    --rbac-name sync-gateway \
    --rbac-username sync-gateway \
    --rbac-password password \
    --roles admin

echo "::endgroup::"
