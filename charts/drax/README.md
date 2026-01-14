# dRAX Helm Chart

This Helm chart deploys the `dRAX` product into a Kubernetes cluster. It uses:

- **CloudNativePG (CNPG)** to manage PostgreSQL clusters
- **Atlas Operator** to manage database schema and migrations

---

## Prerequisites

Before installing the `dRAX` Helm chart, the following components must be installed in your cluster:

---

### 1. Install CloudNativePG (CNPG) Operator

CloudNativePG is required to provision and manage the PostgreSQL cluster that dRAX depends on.

Install the operator using the official manifest:

# renovate: repository=https://cloudnative-pg.github.io/charts chart=cloudnative-pg
export CNPG_VERSION="0.24.0"

```bash
helm repo add cloudnative-pg https://cloudnative-pg.github.io/charts
helm repo update
helm upgrade --install cnpg cloudnative-pg/cloudnative-pg \
  --namespace drax-system \
  --create-namespace \
  --version "$CNPG_VERSION" \
  --timeout 5m \
  --atomic
```

### 2. Install Atlas Operator

The Atlas Operator is required by `dRAX` to manage database schema migrations for PostgreSQL. It watches for Atlas custom resources and applies schema changes to the target database.

Install the Atlas Operator using Helm:

# renovate: image=ghcr.io/ariga/charts/atlas-operator
export ATLAS_VERSION="0.7.10"

```bash
helm upgrade --install atlas-operator oci://ghcr.io/ariga/charts/atlas-operator \
  --namespace drax-system \
  --create-namespace \
  --version "$ATLAS_VERSION" \
  --timeout 5m \
  --atomic
```