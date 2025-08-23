#!/bin/bash

set -eu

script_dir=`realpath "$(dirname $0)"`
project_dir=`realpath "${script_dir}/.."`

namespace="infra"

secret_name="keycloak"

create_secret() {
    local env="$1"

    local secret_yaml="${project_dir}/${env}/sops-age/${secret_name}.yaml"

    local config_dir="${NGUILAND_CONFIG_DIR}/${env}/keycloak"

    local database_dir="${config_dir}/database"
    local db_user=$(cat "${database_dir}/user")
    local db_password=$(cat "${database_dir}/password")
    local db_url=$(cat "${database_dir}/url")

    local console_dir="${config_dir}/console"
    local console_user=$(cat "${console_dir}/user")
    local console_password=$(cat "${console_dir}/password")

    kubectl create secret generic "${secret_name}" \
        --from-literal=db-user="${db_user}" \
        --from-literal=db-password="${db_password}" \
        --from-literal=db-url="${db_url}" \
        --from-literal=console-user="${console_user}" \
        --from-literal=console-password="${console_password}" \
        -o yaml \
        --namespace="${namespace}" \
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
