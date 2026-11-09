# Archived charts

Charts in this directory are frozen.

- Renovate ignores this tree (`ignorePaths`)
- CI, release-please, and chart-releaser do not scan or publish from here
- Already-published versions remain available from GitHub Releases, `index.yaml`, and GHCR
- Their names stay reserved: `bin/check-chart-name-collisions` fails if an active or deprecated chart reuses one

Move a chart here with `bin/archive-chart`. See [Chart lifecycle](../README.md#chart-lifecycle).
