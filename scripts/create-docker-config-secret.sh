#!/bin/bash

set -eu

namespace="infra"

secret_name="$1"
config_json_file="$2"
secret_yaml_file="$3"

kubectl create secret generic "${secret_name}" \
    --type="kubernetes.io/dockerconfigjson" \
    --from-file=config.json="${config_json_file}" \
    --from-file=.dockerconfigjson="${config_json_file}" \
    -o yaml \
    --namespace="${namespace}" \
    --dry-run=client \
    | grep -v "\s*creationTimestamp:\s*null" > "${secret_yaml_file}"
