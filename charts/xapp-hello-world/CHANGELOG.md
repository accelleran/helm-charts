# Changelog

## [3.0.2](https://github.com/accelleran/helm-charts/compare/xapp-hello-world-3.0.1...xapp-hello-world-3.0.2) (2024-07-22)


### Bug Fixes

* **deps:** Update accelleran/xapp-framework-package docker tag to v3.0.1 ([8ad03c0](https://github.com/accelleran/helm-charts/commit/8ad03c041c700cbe07ada583f8e8413894f09dae))

## [3.0.1](https://github.com/accelleran/helm-charts/compare/xapp-hello-world-3.0.0...xapp-hello-world-3.0.1) (2024-06-14)


### Bug Fixes

* Change default endpoint for NATS_URL ([#305](https://github.com/accelleran/helm-charts/issues/305)) ([28810ae](https://github.com/accelleran/helm-charts/commit/28810ae47f74a5be015235678901dba8df06fb13))
* Fix null config warning ([#302](https://github.com/accelleran/helm-charts/issues/302)) ([2f5e0b7](https://github.com/accelleran/helm-charts/commit/2f5e0b7fa91cf595b7d4b239b548ed5c21fb9fcb))

## [3.0.0](https://github.com/accelleran/helm-charts/compare/xapp-hello-world-2.1.2...xapp-hello-world-3.0.0) (2024-06-05)


### ⚠ BREAKING CHANGES

* fix typo in xappEndpoints
* **deps:** bump app version to 3.0.0
* remove drax node selector
* bump xapp-redis to 0.3.0
* **deps:** bump redis app version to 7.2.5-alpine3.20
* convert deployment to statefulset
* use image.tag to inject custom redis version
* change git init path to `/home/xapp/xapp`
* fix paths
* remove ingress

### Features

* Bump xapp-redis to 0.3.0 ([3affa71](https://github.com/accelleran/helm-charts/commit/3affa71971cc1ca50ac9440fdab6e1bb0432c3f4))


### Bug Fixes

* Change git init path to `/home/xapp/xapp` ([dbf0c29](https://github.com/accelleran/helm-charts/commit/dbf0c29ea78726dee151f8fcb2e7d49700f4b9f0))
* Convert deployment to statefulset ([6687974](https://github.com/accelleran/helm-charts/commit/6687974399d4efb356cdd5960c8307aac76993b5))
* **deps:** Bump app version to 3.0.0 ([b942c36](https://github.com/accelleran/helm-charts/commit/b942c36f9bd42a1fd1193289b63160ac6f90d64f))
* **deps:** Bump redis app version to 7.2.5-alpine3.20 ([9c3cb4f](https://github.com/accelleran/helm-charts/commit/9c3cb4f0b46c7aae13895913b68b8791167b41f4))
* Fix init containers after update to acc-generic-img:0.8.0 ([4de0f43](https://github.com/accelleran/helm-charts/commit/4de0f43ee3a459d2a2842454902ba419781db402))
* Fix paths ([d071875](https://github.com/accelleran/helm-charts/commit/d0718750560675dbef518f291e74f7628ef3b783))
* Fix pvc ([b5a5d53](https://github.com/accelleran/helm-charts/commit/b5a5d534bc4661772c0697c2319bb10944fd8622))
* Fix typo in xappEndpoints ([5319596](https://github.com/accelleran/helm-charts/commit/5319596ddf83bccb848134eb4f6bdb539a41b291))
* Remove drax node selector ([4fc5728](https://github.com/accelleran/helm-charts/commit/4fc572832e77c40df2c2becd7436b2d1f4542c79))
* Remove ingress ([d198ebb](https://github.com/accelleran/helm-charts/commit/d198ebbe8cf57d84f8f755cde0cd7157f1e66815))
* Set initImage tag explicitly to 0.8.0 ([3be5822](https://github.com/accelleran/helm-charts/commit/3be5822c9ba2e289bddd097479ccac172ed2e36f))
* Update xapp-hello-world Chart.lock ([c6044d9](https://github.com/accelleran/helm-charts/commit/c6044d95b4ed0566f333f3c97b2a6003287c71dc))
* Use image.tag to inject custom redis version ([c9fb5bf](https://github.com/accelleran/helm-charts/commit/c9fb5bf2ee7f1ce1c8d5effc974652719f1a35b1))
