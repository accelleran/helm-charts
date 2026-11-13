#!/bin/bash

set -euo pipefail

GIT_ROOT="$(realpath "$(dirname "$0")/../..")"

# renovate: github_repository=metallb/metallb versioning=semver
export METALLB_VERSION="v0.16.2"
"$GIT_ROOT"/bin/install-metallb | tee /tmp/metallb.log
metallb_ip_address="$(cat /tmp/metallb.log | grep "ip_address=" | cut -d= -f2)"
rm /tmp/metallb.log

# ci/default-values.yaml turns keycloak-init into a plain Job that removes itself
# 5s after finishing (ttlSecondsAfterFinished). Helm 4's default watcher wait
# then sees it as NotFound and never gets ready; Helm 3's legacy wait ignored Jobs.
# --helm-extra-set-args reaches only helm install/upgrade, not helm test.
printf "ct_install_args=--helm-extra-set-args \"--set=global.ipAddress=%s --wait=legacy\"\n" "$metallb_ip_address" \
    | tee -a "${GITHUB_OUTPUT:-/dev/null}"
