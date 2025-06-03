# CloudNativePG Cluster Helm Chart

## Prerequisites

You must install the CloudNativePG operator and its CRDs before installing this chart:

```bash
helm install cnpg cloudnative-pg/cloudnative-pg \
  --namespace cnpg-system \
  --create-namespace \
  --version 0.24.0
