#!/bin/bash
#
# Shared helpers for listing and validating top-level external/ chart
# definitions. Source this file; do not execute it.
#
# Recognized layouts:
#   external/<name>.yaml
#   external/<name>/External.yaml

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Source this file from bin scripts that work with external charts." 1>&2
    exit 1
fi

GIT_ROOT="$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")"

shopt -s nullglob

function yaml_name() {
    awk '
        /^name:[[:space:]]*/ {
            val = $0
            sub(/^name:[[:space:]]*/, "", val)
            gsub(/[\r\n]/, "", val)
            gsub(/^["'\'']|["'\'']$/, "", val)
            print val
            exit
        }
    ' "$1"
}

# Print recognized definition paths, one per line.
function list_external_chart_files() {
    local f
    for f in "${GIT_ROOT}"/external/*.yaml "${GIT_ROOT}"/external/*/External.yaml ; do
        [[ -f "${f}" ]] || continue
        printf '%s\n' "${f}"
    done
}

# Expected published name from the path (flat stem or nested directory).
function external_chart_expected_name() {
    local file="${1}"
    local base dir
    base="$(basename "${file}")"
    dir="$(basename "$(dirname "${file}")")"
    if [[ "${base}" == "External.yaml" && "${dir}" != "external" ]]; then
        printf '%s\n' "${dir}"
    else
        printf '%s\n' "${base%.yaml}"
    fi
}

# True when name: matches the path. Prints a diagnostic to stderr on failure.
function external_chart_name_matches_path() {
    local file="${1}"
    local rel expected actual
    rel="${file#"${GIT_ROOT}/"}"
    expected="$(external_chart_expected_name "${file}")"
    actual="$(yaml_name "${file}")"
    if [[ -z "${actual}" ]]; then
        echo "No name: in ${rel}" 1>&2
        return 1
    fi
    if [[ "${actual}" != "${expected}" ]]; then
        echo "name: '${actual}' does not match ${rel} (expected '${expected}')" 1>&2
        return 1
    fi
    return 0
}

# Print the definition path for this chart name (flat preferred), or nothing.
function external_chart_file_for() {
    local name="${1}"
    if [[ -f "${GIT_ROOT}/external/${name}.yaml" ]]; then
        printf '%s\n' "${GIT_ROOT}/external/${name}.yaml"
    elif [[ -f "${GIT_ROOT}/external/${name}/External.yaml" ]]; then
        printf '%s\n' "${GIT_ROOT}/external/${name}/External.yaml"
    fi
}

function is_external_chart() {
    [[ -n "$(external_chart_file_for "${1}")" ]]
}
