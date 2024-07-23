#!/bin/bash

set -eu

namespace="infra"

secret_name="$1"
secret_yaml_file="$2"
db_user="$3"
db_password="$4"
db_url="$5"
console_user="$6"
console_password="$7"

kubectl create secret generic "${secret_name}" \
    --from-literal=db-user="${db_user}" \
    --from-literal=db-password="${db_password}" \
    --from-literal=db-url="${db_url}" \
    --from-literal=console-user="${console_user}" \
    --from-literal=console-password="${console_password}" \
    -o yaml \
    --namespace="${namespace}" \
    --dry-run=client \
    | grep -v "\s*creationTimestamp:\s*null" > "${secret_yaml_file}"
