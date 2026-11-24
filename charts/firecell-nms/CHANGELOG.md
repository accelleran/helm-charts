# Changelog

## [0.2.2](https://github.com/accelleran/helm-charts/compare/firecell-nms-0.2.1...firecell-nms-0.2.2) (2026-11-24)


### Features

* **firecell-core,firecell-cu,firecell-du,firecell-nms:** Write a release-info ConfigMap ([10e3484](https://github.com/accelleran/helm-charts/commit/10e3484a062e8e84fd7b2ea61b590d10f2780518))
* **firecell-nms:** Add the support bundle scratch space and log store settings ([982fb19](https://github.com/accelleran/helm-charts/commit/982fb191f41df8c3ca3f3e3bedfaba1ad2e72468))
* **firecell-nms:** Let support bundles read workloads, events and nodes ([4af99bb](https://github.com/accelleran/helm-charts/commit/4af99bb0ea60e2c22a979206d331cbccdff0d668))


### Bug Fixes

* **deps:** Update dependency mysql to v8.4.13 ([2548f49](https://github.com/accelleran/helm-charts/commit/2548f49ad251a626a812a24cfd3b750f753fc659))
* **deps:** Update docker.io/library/mysql docker tag to v8.4.11 ([#1880](https://github.com/accelleran/helm-charts/issues/1880)) ([4696205](https://github.com/accelleran/helm-charts/commit/46962055add6033353f805786f5fcf4a5f86e602))
* **deps:** Update docker.io/victoriametrics/victoria-metrics docker tag to v1.156.0 ([2765887](https://github.com/accelleran/helm-charts/commit/2765887155564fada37df09d8cc1f4d5c5015597))
* **deps:** Update docker.io/victoriametrics/victoria-metrics docker tag to v1.93.16 ([7d8afc6](https://github.com/accelleran/helm-charts/commit/7d8afc635804ab6a052f84d7d004809ad3146a95))
* **deps:** Update firecell-nms images to v6.0.1 ([45ba71d](https://github.com/accelleran/helm-charts/commit/45ba71d0079d34b4379edee03fe516cc1140592f))
* **firecell-cu,firecell-nms:** Align the CU-UP gNB ID and the NMS seed with the other charts' defaults ([#1879](https://github.com/accelleran/helm-charts/issues/1879)) ([eeb9241](https://github.com/accelleran/helm-charts/commit/eeb9241b1c513e6cbdd2ccd71c806d596d89bbe5))
* **firecell-nms:** Keep an hour of CM observations, not a week ([708ecee](https://github.com/accelleran/helm-charts/commit/708ecee22cb0924f33126bbb5821f8eae3234479))
* **firecell-nms:** Let support bundles read Services ([7824f5b](https://github.com/accelleran/helm-charts/commit/7824f5b856176e009fab49ddc9226c8bc277a91c))
* **firecell-nms:** Let support bundles read the NMS's own namespace ([9a119e7](https://github.com/accelleran/helm-charts/commit/9a119e7cd0248d97238a3446cb1d192c920bc277))

## [0.2.1](https://github.com/accelleran/helm-charts/compare/firecell-nms-0.2.0...firecell-nms-0.2.1) (2026-11-05)


### Features

* **firecell-nms:** Default to published 6.0.0 Docker Hub images ([5ad8169](https://github.com/accelleran/helm-charts/commit/5ad816913f18adaee0c3767b0abfecbb281c1b03))

## [0.2.0](https://github.com/accelleran/helm-charts/compare/firecell-nms-0.1.1...firecell-nms-0.2.0) (2026-10-28)


### ⚠ BREAKING CHANGES

* Flask API, Redis, chart Grafana, Namespace and Ingress are removed. Values move to backend.*, rbac.* and networkPolicy.*. Service names are nms-api, nms-db, nms-front and nms-victoria-metrics.

### Features

* Converge firecell-nms on the new NMS backend ([#1776](https://github.com/accelleran/helm-charts/issues/1776)) ([bff6cd2](https://github.com/accelleran/helm-charts/commit/bff6cd2af91aa446a60a8629db9104f6dd9e6064))


### Bug Fixes

* **deps:** Update mysql docker tag ([#1797](https://github.com/accelleran/helm-charts/issues/1797)) ([aa13b4f](https://github.com/accelleran/helm-charts/commit/aa13b4f366f08938e78a7bfc05cda199fc29f79c))
* **deps:** Update mysql docker tag to v8.0.46 ([#1795](https://github.com/accelleran/helm-charts/issues/1795)) ([45b9c5c](https://github.com/accelleran/helm-charts/commit/45b9c5c83adb288aeb804e20102aa4210a917875))
