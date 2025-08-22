#!/bin/bash

set -eu

script_dir=`realpath "$(dirname $0)"`
project_dir=`realpath "${script_dir}/.."`
settings_xml_template=`realpath "${script_dir}/../templates/maven/settings.xml"`

namespace="infra"

secret_name="maven-settings"

get_credential_path() {
	local credential_name="$1"
	printf "//*[local-name()='settings']/*[local-name()='servers']/*[local-name()='server']/*[local-name()='${credential_name}']"
}

set_credentials() {
    local env="$1"
	local input_path="$2"
	local output_path="$3"

    local credentials_dir="${NGUILAND_ARTIFACTORY_CONFIG_DIR}/oss/admin"

    local username=$(cat "${credentials_dir}/user")
    local password=$(cat "${credentials_dir}/password")

	local username_path=$(get_credential_path "username")
	local password_path=$(get_credential_path "password")

	xmlstarlet ed -u "${username_path}" -v "${username}" -u "${password_path}" -v "${password}" "${input_path}" > "${output_path}"
}

create_secret() {
    local env="$1"

    local settings_xml=$(mktemp)

    set_credentials "${env}" "${settings_xml_template}" "${settings_xml}"

    local secret_yaml="${project_dir}/${env}/sops-age/${secret_name}.yaml"

    kubectl create secret generic "${secret_name}" \
        --from-file=settings.xml="${settings_xml}" \
        -o yaml \
        --namespace="${namespace}" \
        --dry-run=client \
        | grep -v "\s*creationTimestamp:\s*null" > "${secret_yaml}"

    cd "${project_dir}"

    sops -e -i "${secret_yaml}"

    printf "The %s secret was created in the %s file" "${secret_name}" "${secret_yaml}"

    rm "${settings_xml}"
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
