# Changelog

## [0.2.0](https://github.com/accelleran/helm-charts/compare/firecell-nms-0.1.1...firecell-nms-0.2.0) (2026-10-28)


### ⚠ BREAKING CHANGES

* Flask API, Redis, chart Grafana, Namespace and Ingress are removed. Values move to backend.*, rbac.* and networkPolicy.*. Service names are nms-api, nms-db, nms-front and nms-victoria-metrics.

### Features

* Converge firecell-nms on the new NMS backend ([#1776](https://github.com/accelleran/helm-charts/issues/1776)) ([bff6cd2](https://github.com/accelleran/helm-charts/commit/bff6cd2af91aa446a60a8629db9104f6dd9e6064))


### Bug Fixes

* **deps:** Update mysql docker tag ([#1797](https://github.com/accelleran/helm-charts/issues/1797)) ([aa13b4f](https://github.com/accelleran/helm-charts/commit/aa13b4f366f08938e78a7bfc05cda199fc29f79c))
* **deps:** Update mysql docker tag to v8.0.46 ([#1795](https://github.com/accelleran/helm-charts/issues/1795)) ([45b9c5c](https://github.com/accelleran/helm-charts/commit/45b9c5c83adb288aeb804e20102aa4210a917875))
