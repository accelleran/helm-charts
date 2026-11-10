# External charts

Republished upstream OCI charts. Each definition is `external/<name>.yaml` or `external/<name>/External.yaml`.

- Renovate bumps `version` from the upstream OCI repository
- CI does not lint or install these; they have no `Chart.yaml` in this repo
- On release, the upstream `.tgz` is pulled and published with chart-releaser; the OCI artifact is copied to GHCR with the upstream digest
- Stop republishing by deleting the yaml file. Names stay reserved while the definition exists.

See [External charts](../README.md#external-charts).
