#!/bin/bash

set -eu

namespace="infra"

create_known_hosts_file() {
    local hosts=("$1")

    local known_hosts=$(mktemp)

    for host in ${hosts[@]}; do 
        ssh-keyscan -t "${private_key_type}" "${host}" >> "${known_hosts}"
    done

    printf "${known_hosts}"
}

create_secret() {
    local hosts="$1"

    local secret_name="$1"
    local secret_yaml_file="$2"
    local private_key_file="$3"
    local private_key_type="$4"
    local hosts="$5"

    local known_hosts=$(create_known_hosts_file "${hosts}")

    # The identity key is required by Flux to authenticate towards a Git repository
    kubectl create secret generic "${secret_name}" \
        --from-file=id_${private_key_type}="${private_key_file}" \
        --from-file=identity="${private_key_file}" \
        --from-file=known_hosts="${known_hosts}" \
        -o yaml \
        --namespace="${namespace}" \
        --dry-run=client \
        | grep -v "\s*creationTimestamp:\s*null" > "${secret_yaml_file}"

    # Remove the temp file that was created
    rm "${known_hosts}"
}

create_secret "$@"