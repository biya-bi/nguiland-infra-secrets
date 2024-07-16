#!/bin/bash

set -eu

script_dir=`realpath "$(dirname $0)"`
project_dir=`realpath "${script_dir}/.."`

namespace="infra"

create_secret() {
    local secret_name="$1"
    local system_yaml_file="$2"
    local secret_yaml_file="$3"

    kubectl create secret generic "${secret_name}" \
        --from-literal=join.key="${ARTIFACTORY_JOIN_KEY}" \
        --from-literal=master.key="${ARTIFACTORY_MASTER_KEY}" \
        --from-file=system.yaml="${system_yaml_file}" \
        -o yaml \
        --namespace="${namespace}" \
        --dry-run=client \
        | grep -v "\s*creationTimestamp:\s*null" > "${secret_yaml_file}"
}

main() {
    local system_name=`echo "$1" | tr '[:upper:]' '[:lower:]'`
    if [ "${system_name}" != "oss" ] && [ "${system_name}" != "jcr" ]; then
        printf "%s is an invalid system name! Valid system names are [%s, %s]\n" "${system_name}" "oss" "jcr"
        exit 1
    else
        local secret_name="artifactory-${system_name}"
        local env="$2"
        local system_yaml_file="$3"
        local secret_yaml_file="${project_dir}/${env}/sops-age/${secret_name}.yaml"

        create_secret "${secret_name}" "${system_yaml_file}" "${secret_yaml_file}"

        printf "The %s secret was created in the %s file" "${secret_name}" "${secret_yaml_file}"
    fi
}

main "$@"