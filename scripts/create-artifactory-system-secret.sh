#!/bin/bash

set -eu

namespace="infra"

secret_name="$1"
system_yaml_file="$2"
secret_yaml_file="$3"

kubectl create secret generic "${secret_name}" \
    --from-literal=join.key="${ARTIFACTORY_JOIN_KEY}" \
    --from-literal=master.key="${ARTIFACTORY_MASTER_KEY}" \
    --from-file=system.yaml="${system_yaml_file}" \
    -o yaml \
    --namespace="${namespace}" \
    --dry-run=client \
    | grep -v "\s*creationTimestamp:\s*null" > "${secret_yaml_file}"
