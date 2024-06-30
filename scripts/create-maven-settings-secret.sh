#!/bin/bash

set -eu

namespace="infra"

secret_name="$1"
settings_xml_file="$2"
secret_yaml_file="$3"

kubectl create secret generic "${secret_name}" \
    --from-file=settings.xml="${settings_xml_file}" \
    -o yaml \
    --namespace="${namespace}" \
    --dry-run=client \
    | grep -v "\s*creationTimestamp:\s*null" > "${secret_yaml_file}"
