# Changelog

## [8.0.0](https://github.com/accelleran/helm-charts/compare/cu-cp-7.1.0...cu-cp-8.0.0) (2024-06-05)


### ⚠ BREAKING CHANGES

* disable NATS/Redis in CU by default ([#125](https://github.com/accelleran/helm-charts/issues/125))
* **deps:** update cu-cp to common chart 0.3.0 ([#249](https://github.com/accelleran/helm-charts/issues/249))
* **deps:** update helm release redis to v19 ([#173](https://github.com/accelleran/helm-charts/issues/173))
* **deps:** update cucp to 5.0.6 ([#242](https://github.com/accelleran/helm-charts/issues/242))

### Bug Fixes

* **deps:** Update accelleran/cucp-netconf docker tag to v5.0.7 ([01884b4](https://github.com/accelleran/helm-charts/commit/01884b4e1a9ca382025ae4b8a0d6507f55dae3d2))
* **deps:** Update cu-cp to common chart 0.3.0 ([#249](https://github.com/accelleran/helm-charts/issues/249)) ([d5c4357](https://github.com/accelleran/helm-charts/commit/d5c43575941b055a3e692e1d96833189ede5461b))
* **deps:** Update cucp to 5.0.6 ([#242](https://github.com/accelleran/helm-charts/issues/242)) ([c8de466](https://github.com/accelleran/helm-charts/commit/c8de4664f1428c2afe9af9fb7650da6f118a16f2))
* **deps:** Update helm release common to v0.2.3 ([2720172](https://github.com/accelleran/helm-charts/commit/2720172fa39bfc8c82ee656029c09200f21647aa))
* **deps:** Update helm release nats to v1.1.12 ([da5f102](https://github.com/accelleran/helm-charts/commit/da5f1027547c83f5c68f56ce524218db3f2b35c0))
* **deps:** Update helm release redis to v19 ([#173](https://github.com/accelleran/helm-charts/issues/173)) ([979ae1e](https://github.com/accelleran/helm-charts/commit/979ae1e51d665263c457c7a9ecc30e64ac001843))
* Disable NATS/Redis in CU by default ([#125](https://github.com/accelleran/helm-charts/issues/125)) ([7e90a3f](https://github.com/accelleran/helm-charts/commit/7e90a3f4324e71d14160cde49ab477ae455fc3d1))
* Fix ds-ctrl init image not being used ([#245](https://github.com/accelleran/helm-charts/issues/245)) ([e1ccd30](https://github.com/accelleran/helm-charts/commit/e1ccd304173e56fe425c064c0d7cd753f26f6e54))

## [7.1.0](https://github.com/accelleran/helm-charts/compare/cu-cp-7.0.0...cu-cp-7.1.0) (2024-04-29)


### Features

* Add close-f1-connection-on-cell-deactivation feature flag ([#180](https://github.com/accelleran/helm-charts/issues/180)) ([c81a9f3](https://github.com/accelleran/helm-charts/commit/c81a9f353d752b5a197009fffb9e2572c276c3dd))


### Bug Fixes

* **deps:** Update helm release nats to v1.1.10 ([9fe5adc](https://github.com/accelleran/helm-charts/commit/9fe5adc45fb5e3c42227ba38abc223a8f0a8c71a))
* **deps:** Update helm release nats to v1.1.11 ([ca65524](https://github.com/accelleran/helm-charts/commit/ca6552466091a7b8bc997f3added20ab02dea9ea))
* **deps:** Update helm release redis to v18.19.2 ([5c9df2d](https://github.com/accelleran/helm-charts/commit/5c9df2d3438cfcb9905fadd45d61ede06669f3a0))
* **deps:** Update helm release redis to v18.19.3 ([f695a10](https://github.com/accelleran/helm-charts/commit/f695a1095e3ee024236fe2877cf1948eded3e13d))
* **deps:** Update helm release redis to v18.19.4 ([9f775c0](https://github.com/accelleran/helm-charts/commit/9f775c0798c23260952d7974d0a8707853cebb3d))

## [7.0.0](https://github.com/accelleran/helm-charts/compare/cu-cp-v6.0.0...cu-cp-7.0.0) (2024-03-06)


### ⚠ BREAKING CHANGES

* use f1-u and ng-u options ([#129](https://github.com/accelleran/helm-charts/issues/129))
* convert cu-cp to common library charts ([#18](https://github.com/accelleran/helm-charts/issues/18))

### Features

* Convert cu-cp to common library charts ([#18](https://github.com/accelleran/helm-charts/issues/18)) ([5edc3fe](https://github.com/accelleran/helm-charts/commit/5edc3fe48649446bdeaa07d8619d8e4d1345de1f))
* Use f1-u and ng-u options ([#129](https://github.com/accelleran/helm-charts/issues/129)) ([5b4e443](https://github.com/accelleran/helm-charts/commit/5b4e443b117204168e024bde026a506783d068b3))


### Bug Fixes

* **deps:** Update acc-generic-img to 0.8.0 ([#41](https://github.com/accelleran/helm-charts/issues/41)) ([b8ad80d](https://github.com/accelleran/helm-charts/commit/b8ad80d8d4dffc75235d8ae1cb1228f72fbae9a2))
* **deps:** Update cu app version to 4.3.8 ([d052190](https://github.com/accelleran/helm-charts/commit/d05219086f62af7e6a7345b11c6cc403d37d7e11))
* **deps:** Update cu-cp app version to 4.3.10 ([1775071](https://github.com/accelleran/helm-charts/commit/177507155c1c36fb556033f6ea95ded87bcce013))
* **deps:** Update Helm release common to v0.1.1 ([#33](https://github.com/accelleran/helm-charts/issues/33)) ([4f0f7ff](https://github.com/accelleran/helm-charts/commit/4f0f7ff97bc32d4aaf651712d33ee311a32b70ab))
* **deps:** Update Helm release common to v0.1.2 ([06a826b](https://github.com/accelleran/helm-charts/commit/06a826b4b6a2b2c9effa9b573073bfe613d1d4d7))
* **deps:** Update Helm release common to v0.2.0 ([1aac9cc](https://github.com/accelleran/helm-charts/commit/1aac9ccce09460dba36b5beed8e4f7eb45fb0a3e))
* **deps:** Update helm release common to v0.2.2 ([b228a5f](https://github.com/accelleran/helm-charts/commit/b228a5f3aaee93ad7ea4127362cf815d98bd48c2))
* **deps:** Update Helm release nats to v1.1.7 ([#31](https://github.com/accelleran/helm-charts/issues/31)) ([997431c](https://github.com/accelleran/helm-charts/commit/997431c50e7df3db36e5ca5ac63fece681cac720))
* **deps:** Update Helm release nats to v1.1.8 ([a8a95a6](https://github.com/accelleran/helm-charts/commit/a8a95a6497b996ddc798ecc710ed50b29474f8c5))
* **deps:** Update Helm release nats to v1.1.9 ([e5bafec](https://github.com/accelleran/helm-charts/commit/e5bafecf177e9ad19508b4a1e0e1a6cf79853005))
* **deps:** Update Helm release redis to v18.11.0 ([56de74f](https://github.com/accelleran/helm-charts/commit/56de74f1e49abb8aa9a0f16406675ce781a152c5))
* **deps:** Update Helm release redis to v18.11.1 ([b25959c](https://github.com/accelleran/helm-charts/commit/b25959c1515a4d4024b235faa67b04adf3c44566))
* **deps:** Update Helm release redis to v18.12.0 ([30c46ad](https://github.com/accelleran/helm-charts/commit/30c46ad72f4701a082efbac28da084343df8099b))
* **deps:** Update Helm release redis to v18.12.1 ([4c36bdd](https://github.com/accelleran/helm-charts/commit/4c36bddfa8d0feaaeda5384aa087956b75ee3ff6))
* **deps:** Update Helm release redis to v18.13.0 ([a51eb34](https://github.com/accelleran/helm-charts/commit/a51eb349b39940aef672b628d9972300e59f64e2))
* **deps:** Update Helm release redis to v18.14.0 ([64d5e7b](https://github.com/accelleran/helm-charts/commit/64d5e7bcf95cd67c0d44ffbd204915899ceed2d2))
* **deps:** Update Helm release redis to v18.15.1 ([e323562](https://github.com/accelleran/helm-charts/commit/e32356257a43a902f439203f4d72ad0c1f47424e))
* **deps:** Update Helm release redis to v18.16.0 ([50a3769](https://github.com/accelleran/helm-charts/commit/50a3769082370a520a8d09f86ddbab9bd5c35bea))
* **deps:** Update Helm release redis to v18.16.1 ([5855eda](https://github.com/accelleran/helm-charts/commit/5855edab65194af94a0e76f4248732d3e29d091c))
* **deps:** Update helm release redis to v18.17.0 ([54514d7](https://github.com/accelleran/helm-charts/commit/54514d763d26c2051a5a7e49ce6645e02f2139bf))
* **deps:** Update helm release redis to v18.17.1 ([3a038c5](https://github.com/accelleran/helm-charts/commit/3a038c57104dd829e3dc238cb6d0fd8ddd68bda3))
* **deps:** Update helm release redis to v18.18.0 ([36060b5](https://github.com/accelleran/helm-charts/commit/36060b532b857d1c3b264d7197be49b08474c495))
* **deps:** Update Helm release redis to v18.9.1 ([b0e692c](https://github.com/accelleran/helm-charts/commit/b0e692cbae0f4f6de407182f8b7e0c7f335a1724))
