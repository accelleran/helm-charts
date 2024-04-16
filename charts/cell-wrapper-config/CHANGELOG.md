# Changelog

## [0.2.5](https://github.com/accelleran/helm-charts/compare/cell-wrapper-config-0.2.4...cell-wrapper-config-0.2.5) (2024-04-16)


### Bug Fixes

* **deps:** Update helm release common to v0.2.2 ([b228a5f](https://github.com/accelleran/helm-charts/commit/b228a5f3aaee93ad7ea4127362cf815d98bd48c2))
* Flatten xml ([#193](https://github.com/accelleran/helm-charts/issues/193)) ([637b8a2](https://github.com/accelleran/helm-charts/commit/637b8a28510bd01b88a1fbf0d1bfb4a95fe0c155))

## [0.2.4](https://github.com/accelleran/helm-charts/compare/cell-wrapper-config-0.2.3...cell-wrapper-config-0.2.4) (2024-02-26)


### Bug Fixes

* Fix volume mount failing cronjobs ([40550e2](https://github.com/accelleran/helm-charts/commit/40550e2c578d89a4e2cf8edce1d9ee14d48fa1f5))

## [0.2.3](https://github.com/accelleran/helm-charts/compare/cell-wrapper-config-0.2.2...cell-wrapper-config-0.2.3) (2024-02-19)


### Bug Fixes

* Add wait init container to prevent failure due to netconf not being ready yet ([#86](https://github.com/accelleran/helm-charts/issues/86)) ([dd01537](https://github.com/accelleran/helm-charts/commit/dd0153789c5472a303458e8526ba335409602021))
* Prevent deletions for undefined config parts ([#88](https://github.com/accelleran/helm-charts/issues/88)) ([9351480](https://github.com/accelleran/helm-charts/commit/935148088043250fdfb9aff0a9995a35c3bde72c))

## [0.2.2](https://github.com/accelleran/helm-charts/compare/cell-wrapper-config-0.2.1...cell-wrapper-config-0.2.2) (2024-02-13)


### Features

* Allow to set log configuration ([bac292e](https://github.com/accelleran/helm-charts/commit/bac292e597014ddccdc12c71ccaa5e8e8170eefa))


### Bug Fixes

* Fix deleting all DUs iso only the configured ones ([5456d4a](https://github.com/accelleran/helm-charts/commit/5456d4a5199a308a5fdcc32e5958d085ff900074))

## [0.2.1](https://github.com/accelleran/helm-charts/compare/cell-wrapper-config-0.2.0...cell-wrapper-config-0.2.1) (2024-02-02)


### Bug Fixes

* **deps:** Update Helm release common to v0.2.0 ([1aac9cc](https://github.com/accelleran/helm-charts/commit/1aac9ccce09460dba36b5beed8e4f7eb45fb0a3e))

## [0.2.0](https://github.com/accelleran/helm-charts/compare/cell-wrapper-config-0.1.0...cell-wrapper-config-0.2.0) (2024-02-01)


### ⚠ BREAKING CHANGES

* line up helm release and cell config lifetime ([#35](https://github.com/accelleran/helm-charts/issues/35))

### Features

* Line up helm release and cell config lifetime ([#35](https://github.com/accelleran/helm-charts/issues/35)) ([d642181](https://github.com/accelleran/helm-charts/commit/d6421811eeb92df8c669a0792906d8d03737c8b2))


### Bug Fixes

* **deps:** Update Helm release common to v0.1.1 ([#33](https://github.com/accelleran/helm-charts/issues/33)) ([4f0f7ff](https://github.com/accelleran/helm-charts/commit/4f0f7ff97bc32d4aaf651712d33ee311a32b70ab))
* **deps:** Update Helm release common to v0.1.2 ([06a826b](https://github.com/accelleran/helm-charts/commit/06a826b4b6a2b2c9effa9b573073bfe613d1d4d7))
