#!/bin/bash

set -eu

script_dir=`realpath "$(dirname $0)"`
project_dir=`realpath "${script_dir}/.."`
settings_xml_template=`realpath "${script_dir}/../templates/maven/settings.xml"`

secret_name="maven-settings"

get_credential_xpath() {
	local credential_name="$1"
	printf "//*[local-name()='settings']/*[local-name()='servers']/*[local-name()='server']/*[local-name()='${credential_name}']"
}

set_credentials() {
    local env="$1"
	local input_xml="$2"
	local output_xml="$3"

    local config_dir="${NGUILAND_CONFIG_DIR}/${env}/artifactory"

    local console_dir="${config_dir}/oss/console"

    local username=$(cat "${console_dir}/user")
    local password=$(cat "${console_dir}/password")

	local username_xpath=$(get_credential_xpath "username")
	local password_xpath=$(get_credential_xpath "password")

	xmlstarlet ed -u "${username_xpath}" -v "${username}" -u "${password_xpath}" -v "${password}" "${input_xml}" > "${output_xml}"
}

create_secret() {
    local env="$1"

    local settings_xml=$(mktemp)

    set_credentials "${env}" "${settings_xml_template}" "${settings_xml}"

    local secret_yaml="${project_dir}/${env}/sops-age/${secret_name}.yaml"

    kubectl create secret generic "${secret_name}" \
        --from-file=settings.xml="${settings_xml}" \
        -o yaml \
        --namespace="${env}" \
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
