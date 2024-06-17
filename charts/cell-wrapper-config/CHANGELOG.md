# Changelog

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
