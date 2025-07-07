#!/bin/bash

set -euo pipefail

GIT_ROOT="$(realpath "$(dirname "$0")/../..")"

# renovate: github_repository=metallb/metallb versioning=semver
export METALLB_VERSION="v0.15.2"
"$GIT_ROOT"/bin/install-metallb | tee /tmp/metallb.log
metallb_ip_address="$(cat /tmp/metallb.log | grep "ip_address=" | cut -d= -f2)"
rm /tmp/metallb.log

printf "ct_install_args=--helm-extra-set-args \"--set=global.ipAddress=%s\"\n" "$metallb_ip_address" \
    | tee -a "${GITHUB_OUTPUT:-/dev/null}"


"$GIT_ROOT"/bin/install-cnpg
"$GIT_ROOT"/bin/install-atlas