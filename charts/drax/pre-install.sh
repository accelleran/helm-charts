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

# Install cnpg

NAMESPACE="cnpg-system"
RELEASE_NAME="cnpg"
CHART_VERSION="0.24.0"

helm repo add cloudnative-pg https://cloudnative-pg.github.io/charts
helm repo update
helm upgrade --install "$RELEASE_NAME" cloudnative-pg/cloudnative-pg \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --version "$CHART_VERSION" \
  --wait \
  --timeout 5m \
  --atomic
kubectl wait --for=condition=established --timeout=60s crd/clusters.postgresql.cnpg.io
kubectl rollout status deployment/cnpg-cloudnative-pg -n "$NAMESPACE"

# Install atlas

NAMESPACE="atlas-system"
RELEASE_NAME="atlas-operator"
CHART_URI="oci://ghcr.io/ariga/charts/atlas-operator"

helm upgrade --install "$RELEASE_NAME" "$CHART_URI" \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --wait \
  --timeout 5m \
  --atomic

kubectl wait --for=condition=established --timeout=60s crd/atlasschemas.db.atlasgo.io

kubectl rollout status deployment/atlas-operator -n "$NAMESPACE"
