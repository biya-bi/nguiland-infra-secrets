#!/bin/bash

set -eu

script_dir=`realpath "$(dirname $0)"`
project_dir=`realpath "${script_dir}/.."`

secret_name="postgres"

create_secret() {
    local env="$1"

    local secret_yaml="${project_dir}/${env}/sops-age/${secret_name}.yaml"

    local postgres_dir="${NGUILAND_CONFIG_DIR}/${env}/postgres"

    local user=$(cat "${postgres_dir}/user")
    local password=$(cat "${postgres_dir}/password")
    local database=$(cat "${postgres_dir}/database")
    local extra_databases=$(cat "${postgres_dir}/extra_databases")

    kubectl create secret generic "${secret_name}" \
        --from-literal=user="${user}" \
        --from-literal=password="${password}" \
        --from-literal=db="${database}" \
        --from-literal=extra-dbs="${extra_databases}" \
        -o yaml \
        --namespace="${env}" \
        --dry-run=client \
        | grep -v "\s*creationTimestamp:\s*null" > "${secret_yaml}"
    
    cd "${project_dir}"

    sops -e -i "${secret_yaml}"

    printf "The %s secret was created in the %s file" "${secret_name}" "${secret_yaml}"
}

main() {
    local expected_arg_count=1

    if [ "$#" -lt "${expected_arg_count}" ]; then
        printf "Error: Not enough arguments provided.\n"
        printf "Usage: $0 <env>\n"
        exit 1
    fi

    local env="$1"

    create_secret "${env}"
}

main "$@"
