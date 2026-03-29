#!/bin/bash

set -eu

script_dir=`realpath "$(dirname $0)"`
project_dir=`realpath "${script_dir}/.."`
system_yaml_template=`realpath "${script_dir}/../templates/artifactory/system.yaml"`

namespace="infra"

set_connection_string() {
    local env="$1"
    local system_yaml="$2"
    local system_name="$3"

    local config_dir="${NGUILAND_CONFIG_DIR}/${env}/artifactory"

    local connection_string_dir="${config_dir}/${system_name}/database"

    local url=$(cat "${connection_string_dir}/url")
    local username=$(cat "${connection_string_dir}/user")
    local password=$(cat "${connection_string_dir}/password")

    yq -i '(.shared.database.url = "'"${url}"'") | (.shared.database.username = "'"${username}"'") | (.shared.database.password = "'"${password}"'")' "${system_yaml}"
}

get_key() {
    local key_type="$1"

    local config_dir="${NGUILAND_CONFIG_DIR}/${env}/artifactory"

    local keys_dir="${config_dir}/keys"

    printf "$(cat ${keys_dir}/${key_type}.key)"
}

# Get an authentication field for a given system.
# The bootstrap_user file contains the username followed by @, which could be followed by an IP, instance name or *.
# The user file on the other hand contains just the username as can be typed by a user.
# To set the admin credentials in the secret, we will need the content of the bootstrap_user file rather than that of the user file.
# The user file will be necessary for other types of credentials such as those required in Maven settings and Docker configurations.
#
# Parameters:
#   $1 - system name
#   $2 - field name ("user", "password", or "bootstrap_user")
#
# Returns:
#   Prints the value of the requested field to stdout.
#
# Errors:
#   Returns non-zero if the field is invalid or the file does not exist.
get_authentication_field() {
    local system_name="${1:?missing system_name}"
    local field_type="${2:?missing field_type}"

    # --- Validate field name ---
    case "$field_type" in
        user|password|bootstrap_user)
            ;;
        *)
            echo "Error: field_type must be 'user', 'password', or 'bootstrap_user'" >&2
            return 1
            ;;
    esac

    local config_dir="${NGUILAND_CONFIG_DIR}/${env}/artifactory"
    local console_dir="${config_dir}/${system_name}/console"
    local file_path="${console_dir}/${field_type}"

    # --- Check file exists ---
    if [[ ! -f "$file_path" ]]; then
        echo "Error: file not found: $file_path" >&2
        return 1
    fi

    # --- Read file safely ---
    local authentication_field
    authentication_field=$(<"$file_path")

    # --- Safe output ---
    printf '%s' "$authentication_field"
}

create_secret() {
    local env="$1"
    local system_yaml="$2"
    local system_name="$3"

    local secret_name="artifactory-${system_name}"
    local secret_yaml="${project_dir}/${env}/sops-age/${secret_name}.yaml"

    local join_key=$(get_key "join")
    local master_key=$(get_key "master")

    local user=$(get_authentication_field "${system_name}" "user")
    local password=$(get_authentication_field "${system_name}" "password")
    local bootstrap_user=$(get_authentication_field "${system_name}" "bootstrap_user")
    local bootstrap_credentials="${bootstrap_user}=${password}"

    kubectl create secret generic "${secret_name}" \
        --from-literal=join.key="${join_key}" \
        --from-literal=master.key="${master_key}" \
        --from-file=system.yaml="${system_yaml}" \
        --from-literal=bootstrap.creds="${bootstrap_credentials}" \
        --from-literal=user="${user}" \
        --from-literal=password="${password}" \
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

    set_connection_string "${env}" "${system_yaml}" "${system_name}"
    create_secret "${env}" "${system_yaml}" "${system_name}"

    rm "${system_yaml}"
}

main "$@"

