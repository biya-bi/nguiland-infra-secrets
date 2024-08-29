#!/bin/bash

set -euo pipefail

namespace="infra"

secret_name="$1"
secret_yaml_file="$2"
cert_file="$3"
key_file="$4"

kubectl create secret tls "${secret_name}" \
    --cert="${cert_file}" \
    --key="${key_file}" \
    --output yaml \
    --namespace="${namespace}" \
    --dry-run=client \
    | grep -v "\s*creationTimestamp:\s*null" > "${secret_yaml_file}"
