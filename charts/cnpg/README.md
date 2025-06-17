# CloudNativePG Cluster Helm Chart

## Prerequisites

You must install the CloudNativePG operator and its CRDs before installing this chart:

```bash
helm repo add cloudnative-pg https://cloudnative-pg.github.io/charts
helm repo update
helm upgrade --install cnpg cloudnative-pg/cloudnative-pg \
    --namespace cnpg-system \
    --create-namespace \
    --version 0.24.0 \
    --wait \
    --timeout 5m \
    --atomic