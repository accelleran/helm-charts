#!/bin/bash
#
# Shared helpers for bin/deprecate-chart and bin/archive-chart.

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Source this file from bin/deprecate-chart or bin/archive-chart." 1>&2
    exit 1
fi

GIT_ROOT="$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")"
RELEASE_PLEASE_CONFIG="${GIT_ROOT}/etc/release-please-config.json"
RELEASE_PLEASE_MANIFEST="${GIT_ROOT}/etc/.release-please-manifest.json"

function error() {
    echo "${1}" 1>&2
    exit 1
}

function warn() {
    echo "warning: ${1}" 1>&2
}

function require_tools() {
    command -v jq >/dev/null 2>&1 || error "jq is required"
    command -v git >/dev/null 2>&1 || error "git is required"
    command -v awk >/dev/null 2>&1 || error "awk is required"
    git -C "${GIT_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1 || error "not a git checkout: ${GIT_ROOT}"
}

function validate_chart_name() {
    local name="${1}"
    if [[ ! "${name}" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]]; then
        error "invalid chart name: ${name}"
    fi
}

function chart_location() {
    local name="${1}"
    if [[ -f "${GIT_ROOT}/charts/${name}/Chart.yaml" ]]; then
        printf '%s\n' "charts"
    elif [[ -f "${GIT_ROOT}/deprecated/${name}/Chart.yaml" ]]; then
        printf '%s\n' "deprecated"
    elif [[ -f "${GIT_ROOT}/archived/${name}/Chart.yaml" ]]; then
        printf '%s\n' "archived"
    elif [[ -f "${GIT_ROOT}/charts/${name}/External.yaml" ]]; then
        printf '%s\n' "external"
    else
        printf '%s\n' "missing"
    fi
}

function refuse_external_chart() {
    local name="${1}"
    error "${name} is an external chart (charts/${name}/External.yaml). Stop republishing it by deleting that directory."
}

function read_chart_name() {
    local chart_yaml="${1}"
    local name
    name="$(awk '
        /^name:[[:space:]]*/ {
            val = $0
            sub(/^name:[[:space:]]*/, "", val)
            gsub(/[\r\n]/, "", val)
            gsub(/^["'\'']|["'\'']$/, "", val)
            print val
            exit
        }
    ' "${chart_yaml}")"
    if [[ -z "${name}" ]]; then
        error "No top-level name: in ${chart_yaml}"
    fi
    printf '%s\n' "${name}"
}

function require_directory_matches_chart_name() {
    local name="${1}" root="${2}"
    local actual
    actual="$(read_chart_name "${GIT_ROOT}/${root}/${name}/Chart.yaml")"
    if [[ "${actual}" != "${name}" ]]; then
        error "Chart.yaml name '${actual}' does not match directory '${root}/${name}'"
    fi
}

function release_please_has_package() {
    local key="${1}"
    jq -e --arg key "${key}" '.packages | has($key)' "${RELEASE_PLEASE_CONFIG}" >/dev/null
}

function release_please_has_manifest() {
    local key="${1}"
    jq -e --arg key "${key}" 'has($key)' "${RELEASE_PLEASE_MANIFEST}" >/dev/null
}

function require_release_please_entry() {
    local key="${1}"
    local missing=""
    if ! release_please_has_package "${key}"; then
        missing+=" etc/release-please-config.json"
    fi
    if ! release_please_has_manifest "${key}"; then
        missing+=" etc/.release-please-manifest.json"
    fi
    if [[ -n "${missing}" ]]; then
        error "release-please has no '${key}' entry in:${missing}"
    fi
}

function require_release_please_destination_free() {
    local key="${1}"
    if release_please_has_package "${key}" || release_please_has_manifest "${key}"; then
        error "release-please already has an entry for '${key}'"
    fi
}

function release_please_summary() {
    local key="${1}"
    jq -r --arg key "${key}" '
        .packages[$key] as $pkg |
        "component=\($pkg.component) package-name=\($pkg["package-name"])"
    ' "${RELEASE_PLEASE_CONFIG}"
    jq -r --arg key "${key}" '"manifest=\(.[$key])"' "${RELEASE_PLEASE_MANIFEST}"
}

function rename_release_please_entry() {
    local from="${1}" to="${2}"
    local tmp

    require_release_please_entry "${from}"
    require_release_please_destination_free "${to}"

    tmp="$(mktemp)"
    jq --arg from "${from}" --arg to "${to}" '
        .packages |= (
            to_entries
            | map(if .key == $from then .key = $to else . end)
            | from_entries
        )
    ' "${RELEASE_PLEASE_CONFIG}" > "${tmp}"
    mv "${tmp}" "${RELEASE_PLEASE_CONFIG}"

    tmp="$(mktemp)"
    jq --arg from "${from}" --arg to "${to}" '
        to_entries
        | map(if .key == $from then .key = $to else . end)
        | from_entries
    ' "${RELEASE_PLEASE_MANIFEST}" > "${tmp}"
    mv "${tmp}" "${RELEASE_PLEASE_MANIFEST}"
}

function remove_release_please_entry() {
    local key="${1}"
    local tmp

    require_release_please_entry "${key}"

    tmp="$(mktemp)"
    jq --arg key "${key}" 'del(.packages[$key])' "${RELEASE_PLEASE_CONFIG}" > "${tmp}"
    mv "${tmp}" "${RELEASE_PLEASE_CONFIG}"

    tmp="$(mktemp)"
    jq --arg key "${key}" 'del(.[$key])' "${RELEASE_PLEASE_MANIFEST}" > "${tmp}"
    mv "${tmp}" "${RELEASE_PLEASE_MANIFEST}"
}

function mark_chart_yaml_deprecated() {
    local chart_yaml="${1}"
    local chart_name="${2}"
    command -v python3 >/dev/null 2>&1 || error "python3 is required to update Chart.yaml"
    python3 - "${chart_yaml}" "${chart_name}" <<'PY'
import io
import re
import sys

import yaml

path, expected_name = sys.argv[1], sys.argv[2]

with open(path, encoding="utf-8") as handle:
    original = handle.read()

lines = original.splitlines(keepends=True)


def body_of(line):
    if line.endswith("\r\n"):
        return line[:-2], "\r\n"
    if line.endswith("\n"):
        return line[:-1], "\n"
    return line, ""


def file_ending():
    for line in lines:
        _, ending = body_of(line)
        if ending:
            return ending
    return "\n"


def is_deprecated_text(text):
    return text.startswith("DEPRECATED")


def split_scalar(raw):
    if len(raw) >= 2 and raw[0] == raw[-1] and raw[0] in ('"', "'"):
        return raw[0], raw[1:-1], True
    return "", raw, False


def prefixed(raw):
    quote, text, quoted = split_scalar(raw)
    if is_deprecated_text(text):
        return raw, False
    text = f"DEPRECATED - {text}" if text else "DEPRECATED"
    if quoted:
        return f"{quote}{text}{quote}", True
    return text, True


newline = file_ending()
name = None
name_idx = None
desc_idx = None
dep_indexes = []

for index, line in enumerate(lines):
    text, _ = body_of(line)
    if text.startswith("name:") and name is None:
        name = text.split(":", 1)[1].strip().strip('"').strip("'")
        name_idx = index
    elif text.startswith("description:") and desc_idx is None:
        desc_idx = index
    elif text.startswith("deprecated:"):
        dep_indexes.append(index)

if name != expected_name:
    sys.stderr.write(
        f"Chart.yaml name {name!r} does not match directory {expected_name!r}\n"
    )
    sys.exit(1)

if desc_idx is None:
    if name_idx is None:
        sys.stderr.write(f"No top-level name: in {path}\n")
        sys.exit(1)
    insert_at = name_idx + 1
    lines.insert(insert_at, f"description: DEPRECATED{newline}")
    desc_idx = insert_at
    dep_indexes = [index + 1 if index >= insert_at else index for index in dep_indexes]

desc_text, desc_ending = body_of(lines[desc_idx])
match = re.match(r"^(description:)([ \t]*)(.*)$", desc_text)
if not match:
    sys.stderr.write(f"Could not parse description in {path}\n")
    sys.exit(1)

raw_value = match.group(3)
block_end = desc_idx + 1
if re.fullmatch(r"[>|][+-]?", raw_value.strip()) or raw_value.strip() == "":
    while block_end < len(lines):
        text, _ = body_of(lines[block_end])
        if text.startswith((" ", "\t")) and text.strip() != "":
            block_end += 1
            continue
        break
    content_idx = None
    for index in range(desc_idx + 1, block_end):
        text, ending = body_of(lines[index])
        if text.strip() == "":
            continue
        content_idx = index
        indent = re.match(r"^[ \t]*", text).group(0)
        content = text[len(indent):]
        if not is_deprecated_text(content):
            lines[index] = f"{indent}DEPRECATED - {content}{ending}"
        break
    if content_idx is None and raw_value.strip() == "":
        lines[desc_idx] = f"description:{match.group(2) or ' '}DEPRECATED{desc_ending}"
else:
    new_value, _changed = prefixed(raw_value)
    lines[desc_idx] = f"description:{match.group(2) or ' '}{new_value}{desc_ending}"
    while block_end < len(lines):
        text, _ = body_of(lines[block_end])
        if text.startswith((" ", "\t")) and text.strip() != "":
            block_end += 1
            continue
        break

if dep_indexes:
    for index in dep_indexes:
        text, ending = body_of(lines[index])
        lines[index] = f"deprecated: true{ending}"
else:
    lines.insert(block_end, f"deprecated: true{newline}")

updated = "".join(lines)
try:
    data = yaml.safe_load(io.StringIO(updated))
except yaml.YAMLError as exc:
    sys.stderr.write(f"Refusing to write invalid Chart.yaml: {exc}\n")
    sys.exit(1)

if not isinstance(data, dict):
    sys.stderr.write(f"Chart.yaml did not parse as a mapping: {path}\n")
    sys.exit(1)
if data.get("name") != expected_name:
    sys.stderr.write(f"Chart.yaml name changed unexpectedly in {path}\n")
    sys.exit(1)
if data.get("deprecated") is not True:
    sys.stderr.write(f"deprecated: true was not set in {path}\n")
    sys.exit(1)
description = data.get("description")
if not isinstance(description, str) or not description.startswith("DEPRECATED"):
    sys.stderr.write(f"description was not prefixed with DEPRECATED in {path}\n")
    sys.exit(1)

with open(path, "w", encoding="utf-8", newline="") as handle:
    handle.write(updated)
PY
}

function write_notes_banner() {
    local notes="${1}"
    local successor="${2}"
    local banner dest_line tmp

    if [[ -n "${successor}" ]]; then
        dest_line="* Migrate to the ${successor} chart."
    else
        dest_line="* No successor chart is designated."
    fi

    banner="$(cat <<EOF
********************************************************************************
* DEPRECATED
*
* This chart is deprecated.
${dest_line}
********************************************************************************
EOF
)"

    mkdir -p "$(dirname "${notes}")"
    if [[ -f "${notes}" ]] && grep -q '^\* DEPRECATED$' "${notes}"; then
        echo "templates/NOTES.txt already has a DEPRECATED banner; left it unchanged"
        return 0
    fi

    if [[ -f "${notes}" ]]; then
        tmp="$(mktemp)"
        {
            printf '%s\n\n' "${banner}"
            cat "${notes}"
        } > "${tmp}"
        mv "${tmp}" "${notes}"
        echo "added a DEPRECATED banner to templates/NOTES.txt"
    else
        printf '%s\n' "${banner}" > "${notes}"
        echo "created templates/NOTES.txt with a DEPRECATED banner"
    fi
}

function successor_warning() {
    local successor="${1}"
    local location
    [[ -n "${successor}" ]] || return 0
    location="$(chart_location "${successor}")"
    case "${location}" in
        charts|deprecated|external)
            ;;
        archived)
            warn "successor '${successor}' is archived"
            ;;
        *)
            warn "successor '${successor}' was not found in charts/ or deprecated/"
            ;;
    esac
}

function list_chart_paths() {
    local kind="${1}"
    "${GIT_ROOT}/bin/list-charts" "${kind}" --path --delimiter $'\n'
}

function path_is_listed() {
    local kind="${1}" path="${2}"
    local listing
    listing="$(list_chart_paths "${kind}")" || error "bin/list-charts ${kind} failed"
    grep -F -x "${path}" <<< "${listing}" >/dev/null
}

function verify_deprecated_chart() {
    local name="${1}"
    local path="${GIT_ROOT}/deprecated/${name}"

    "${GIT_ROOT}/bin/check-chart-name-collisions"
    echo "check-chart-name-collisions: ok"

    if ! path_is_listed lint "${path}"; then
        error "deprecated/${name} is missing from the ct lint list"
    fi
    echo "lint list: deprecated/${name} present"

    if path_is_listed test "${path}"; then
        error "deprecated/${name} is still in the ct install list"
    fi
    echo "install test list: deprecated/${name} absent"
}

function verify_archived_chart() {
    local name="${1}"
    local path="${GIT_ROOT}/archived/${name}"

    "${GIT_ROOT}/bin/check-chart-name-collisions"
    echo "check-chart-name-collisions: ok"

    if path_is_listed lint "${path}"; then
        error "archived/${name} is still in the ct lint list"
    fi
    if path_is_listed test "${path}"; then
        error "archived/${name} is still in the ct install list"
    fi
    echo "lint and install test lists: archived/${name} absent"
}

function show_staged_status() {
    local name="${1}"
    # Include every tier. A chart archived after being deprecated in the same
    # index is a rename from charts/, and git only prints that rename when the
    # original path is part of the pathspec.
    git -C "${GIT_ROOT}" status --short -- \
        "etc/release-please-config.json" \
        "etc/.release-please-manifest.json" \
        "charts/${name}" \
        "deprecated/${name}" \
        "archived/${name}"
    echo "Changes are staged. Review them and commit when ready."
}
