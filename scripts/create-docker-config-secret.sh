#!/bin/bash

set -eu

script_dir=`realpath "$(dirname $0)"`
project_dir=`realpath "${script_dir}/.."`
template_dir=`realpath "${script_dir}/../templates/docker"`

namespace="infra"

secret_name="docker-config"

get_credentials() {
    local env="$1"

    local credentials_dir="${NGUILAND_ARTIFACTORY_CONFIG_DIR}/jcr/console"

    local username=$(cat "${credentials_dir}/user")
    local password=$(cat "${credentials_dir}/password")

    printf "${username}:${password}"
}

create_secret() {
    local env="$1"

    local credentials=$(get_credentials "${env}")

    local auth=`printf "${credentials}" | base64`

    local config_json_template="${template_dir}/config-${env}.json"

    local config_json=$(mktemp)

    jq --arg auth "${auth}" '.auths[].auth=$auth' "${config_json_template}" > "${config_json}"

    local secret_yaml="${project_dir}/${env}/sops-age/${secret_name}.yaml"

    kubectl create secret generic "${secret_name}" \
        --type="kubernetes.io/dockerconfigjson" \
        --from-file=config.json="${config_json}" \
        --from-file=.dockerconfigjson="${config_json}" \
        -o yaml \
        --namespace="${namespace}" \
        --dry-run=client \
        | grep -v "\s*creationTimestamp:\s*null" > "${secret_yaml}"

    cd "${project_dir}"

    sops -e -i "${secret_yaml}"

    printf "The %s secret was created in the %s file" "${secret_name}" "${secret_yaml}"

    rm "${config_json}"
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
