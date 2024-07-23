#!/bin/bash

set -eu

namespace="infra"

secret_name="$1"
secret_yaml_file="$2"
user="$3"
password="$4"
database="$5"
extra_databases="$6"

kubectl create secret generic "${secret_name}" \
    --from-literal=user="${user}" \
    --from-literal=password="${password}" \
    --from-literal=db="${database}" \
    --from-literal=extra-dbs="${extra_databases}" \
    -o yaml \
    --namespace="${namespace}" \
    --dry-run=client \
    | grep -v "\s*creationTimestamp:\s*null" > "${secret_yaml_file}"
