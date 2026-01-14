#!/bin/bash

set -euo pipefail

GIT_ROOT="$(realpath "$(dirname "$0")/../..")"

# renovate: github_repository=metallb/metallb versioning=semver
export METALLB_VERSION="v0.15.3"
"$GIT_ROOT"/bin/install-metallb | tee /tmp/metallb.log
metallb_ip_address="$(cat /tmp/metallb.log | grep "ip_address=" | cut -d= -f2)"
rm /tmp/metallb.log

printf "ct_install_args=--helm-extra-set-args \"--set=global.ipAddress=%s\"\n" "$metallb_ip_address" \
    | tee -a "${GITHUB_OUTPUT:-/dev/null}"

# renovate: repository=https://cloudnative-pg.github.io/charts chart=cloudnative-pg
export CNPG_VERSION="0.24.0"
# renovate: image=ghcr.io/ariga/charts/atlas-operator
export ATLAS_VERSION="0.7.10"

NAMESPACE="drax-system"

helm repo add cloudnative-pg https://cloudnative-pg.github.io/charts
helm repo update
helm upgrade --install cnpg cloudnative-pg/cloudnative-pg \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --version "$CNPG_VERSION" \
  --timeout 5m \
  --atomic
kubectl wait --for=condition=established --timeout=60s crd/clusters.postgresql.cnpg.io
kubectl rollout status deployment/cnpg-cloudnative-pg -n "$NAMESPACE"

helm upgrade --install atlas-operator oci://ghcr.io/ariga/charts/atlas-operator \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --version "$ATLAS_VERSION" \
  --timeout 5m \
  --atomic
kubectl wait --for=condition=established --timeout=60s crd/atlasschemas.db.atlasgo.io
kubectl rollout status deployment/atlas-operator -n "$NAMESPACE"