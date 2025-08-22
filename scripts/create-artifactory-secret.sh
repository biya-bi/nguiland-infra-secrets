#!/bin/bash

set -eu

script_dir=`realpath "$(dirname $0)"`
project_dir=`realpath "${script_dir}/.."`
system_yaml_template=`realpath "${script_dir}/../templates/artifactory/system.yaml"`

namespace="infra"

set_connection_string() {
    local env="$1"
    local system_yaml="$2"

    local connection_string_dir="${NGUILAND_DATABASE_CONNECTION_STRING_DIR}"

    local url=$(cat "${connection_string_dir}/url")
    local username=$(cat "${connection_string_dir}/user")
    local password=$(cat "${connection_string_dir}/password")

    yq -i '(.shared.database.url = "'"${url}"'") | (.shared.database.username = "'"${username}"'") | (.shared.database.password = "'"${password}"'")' "${system_yaml}"
}

get_key() {
    local key_type="$1"

    local keys_dir="${NGUILAND_ARTIFACTORY_CONFIG_DIR}/keys"

    printf "$(cat ${keys_dir}/${key_type}.key)"
}

get_admin_credentials() {
    local system_name="$1"

    local credentials_dir="${NGUILAND_ARTIFACTORY_CONFIG_DIR}/${system_name}/admin"

    local username=$(cat "${credentials_dir}/user")
    local password=$(cat "${credentials_dir}/password")

    printf "${username}=${password}"
}

create_secret() {
    local env="$1"
    local system_yaml="$2"
    local system_name="$3"

    local secret_name="artifactory-${system_name}"
    local secret_yaml="${project_dir}/${env}/sops-age/${secret_name}.yaml"

    local join_key=$(get_key "join")
    local master_key=$(get_key "master")

    local admin_credentials=$(get_admin_credentials "${system_name}")

    kubectl create secret generic "${secret_name}" \
        --from-literal=join.key="${join_key}" \
        --from-literal=master.key="${master_key}" \
        --from-file=system.yaml="${system_yaml}" \
        --from-literal=bootstrap.creds="${admin_credentials}" \
        -o yaml \
        --namespace="${namespace}" \
        --dry-run=client \
        | grep -v "\s*creationTimestamp:\s*null" > "${secret_yaml}"

    cd "${project_dir}"

    sops -e -i "${env}/sops-age/artifactory-${system_name}.yaml"

    printf "The %s secret was created in the %s file" "${secret_name}" "${secret_yaml}"
}

get_temp_system_yaml() {
    local system_yaml=$(mktemp)
    cp "${system_yaml_template}" "${system_yaml}"
    printf "${system_yaml}"
}

main() {
    local expected_arg_count=2

    if [ "$#" -lt "${expected_arg_count}" ]; then
        printf "Error: Not enough arguments provided.\n"
        printf "Usage: $0 <env> <system_name>\n"
        exit 1
    fi

    local system_name=`echo "$2" | tr '[:upper:]' '[:lower:]'`

    if [ "${system_name}" != "oss" ] && [ "${system_name}" != "jcr" ]; then
        printf "%s is an invalid system name! Valid system names are [%s, %s]\n" "${system_name}" "oss" "jcr"
        exit 1
    fi

    local env="$1"
    local system_yaml=$(get_temp_system_yaml)

    set_connection_string "${env}" "${system_yaml}"
    create_secret "${env}" "${system_yaml}" "${system_name}"

    rm "${system_yaml}"
}

main "$@"

