# Deprecated charts

Charts in this directory are end-of-life but still releasable.

- Renovate bumps first-party (`accelleran/`, `firecell/`) Docker images and Helm dependencies from `https://accelleran.github.io/helm-charts/`
- CI still lints them; `ct install` is skipped
- release-please and chart-releaser still publish new versions

Move a chart here with `bin/deprecate-chart`. Pass `--no-metadata` to leave `Chart.yaml` and `NOTES.txt` unchanged. See [Chart lifecycle](../README.md#chart-lifecycle).
