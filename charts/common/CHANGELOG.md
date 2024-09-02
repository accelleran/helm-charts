# Changelog

## [0.3.7](https://github.com/accelleran/helm-charts/compare/common-0.3.6...common-0.3.7) (2024-09-02)


### Features

* Add statefulset template ([#502](https://github.com/accelleran/helm-charts/issues/502)) ([98b70c3](https://github.com/accelleran/helm-charts/commit/98b70c36cbf4ffa2ed1b82f544d32187772f7590))

## [0.3.6](https://github.com/accelleran/helm-charts/compare/common-0.3.5...common-0.3.6) (2024-08-22)


### Features

* Allow to inject templates in annotations ([#479](https://github.com/accelleran/helm-charts/issues/479)) ([70b66d4](https://github.com/accelleran/helm-charts/commit/70b66d40279f6a46d57636d9769c150d0f96a962))

## [0.3.5](https://github.com/accelleran/helm-charts/compare/common-0.3.4...common-0.3.5) (2024-08-22)


### Features

* Add extraResources tpl ([#473](https://github.com/accelleran/helm-charts/issues/473)) ([bda16ce](https://github.com/accelleran/helm-charts/commit/bda16ced019635c08dc3c4472dd830e7111b6ce2))

## [0.3.4](https://github.com/accelleran/helm-charts/compare/common-0.3.3...common-0.3.4) (2024-08-09)


### Features

* Add pod disruption budget template ([#457](https://github.com/accelleran/helm-charts/issues/457)) ([86fbf9f](https://github.com/accelleran/helm-charts/commit/86fbf9fb0b8c7777a033df626478dc83e03369b0))
* Add pod template ([#453](https://github.com/accelleran/helm-charts/issues/453)) ([4fffb98](https://github.com/accelleran/helm-charts/commit/4fffb98cd9bdca611409f222f1633b06ec737c1a))

## [0.3.3](https://github.com/accelleran/helm-charts/compare/common-0.3.2...common-0.3.3) (2024-07-22)


### Bug Fixes

* Add option to not set ingress tls secret name or hosts ([#416](https://github.com/accelleran/helm-charts/issues/416)) ([ef7b18e](https://github.com/accelleran/helm-charts/commit/ef7b18e0704f4fab9a3619b1481e729bacc62c97))

## [0.3.2](https://github.com/accelleran/helm-charts/compare/common-0.3.1...common-0.3.2) (2024-07-18)


### Features

* Add ingress templates ([#372](https://github.com/accelleran/helm-charts/issues/372)) ([bfde558](https://github.com/accelleran/helm-charts/commit/bfde5584c16286d06ed552abbe8c444bda451ace))

## [0.3.1](https://github.com/accelleran/helm-charts/compare/common-0.3.0...common-0.3.1) (2024-06-14)


### Features

* Add component label ([#318](https://github.com/accelleran/helm-charts/issues/318)) ([d300d88](https://github.com/accelleran/helm-charts/commit/d300d883b0fa36f6e960f348b8360a2179b2f265))

## [0.3.0](https://github.com/accelleran/helm-charts/compare/common-0.2.3...common-0.3.0) (2024-06-03)


### ⚠ BREAKING CHANGES

* give an error message when a service is disabled without setting an (external) hostname ([#142](https://github.com/accelleran/helm-charts/issues/142))
* switch to image values that renovate automatically updates ([#246](https://github.com/accelleran/helm-charts/issues/246))

### Features

* Give an error message when a service is disabled without setting an (external) hostname ([#142](https://github.com/accelleran/helm-charts/issues/142)) ([e297459](https://github.com/accelleran/helm-charts/commit/e297459fc9b51007616fd3ce5b862d594c5aa05a))


### Bug Fixes

* Switch to image values that renovate automatically updates ([#246](https://github.com/accelleran/helm-charts/issues/246)) ([e45b60a](https://github.com/accelleran/helm-charts/commit/e45b60af421cb985d8f3d25a9f190f00fcddee5d))

## [0.2.3](https://github.com/accelleran/helm-charts/compare/common-0.2.2...common-0.2.3) (2024-05-22)


### Bug Fixes

* Fix extraEnvs ([#221](https://github.com/accelleran/helm-charts/issues/221)) ([908b5fa](https://github.com/accelleran/helm-charts/commit/908b5fadc2b829f696ae9ca77cbed46aca3897cf))

## [0.2.2](https://github.com/accelleran/helm-charts/compare/common-0.2.1...common-0.2.2) (2024-03-06)


### Reverts

* Give an error message when a service is disabled without setting an (external) hostname ([a52eae5](https://github.com/accelleran/helm-charts/commit/a52eae59f9c5b8f737077ce0a065e906ae9da6ff))

## [0.2.1](https://github.com/accelleran/helm-charts/compare/common-0.2.0...common-0.2.1) (2024-03-06)


### Features

* Give an error message when a service is disabled without setting an (external) hostname ([3b3fc14](https://github.com/accelleran/helm-charts/commit/3b3fc14d50b28adfd3129c489d2093bed6696dec))

## [0.2.0](https://github.com/accelleran/helm-charts/compare/common-0.1.2...common-0.2.0) (2024-02-02)


### ⚠ BREAKING CHANGES

* fix fallback to globally defined accelleran license details

### Bug Fixes

* Fix fallback to globally defined accelleran license details ([f1b1534](https://github.com/accelleran/helm-charts/commit/f1b1534261b0d437a9d6ff956092e03515c8579f))

## [0.1.2](https://github.com/accelleran/helm-charts/compare/common-0.1.1...common-0.1.2) (2024-01-31)


### Bug Fixes

* Fix error in partOf when global undefined ([d4f518f](https://github.com/accelleran/helm-charts/commit/d4f518f3cd549b72acb4f1a9db6467194e435225))

## [0.1.1](https://github.com/accelleran/helm-charts/compare/common-0.1.0...common-0.1.1) (2024-01-29)


### Features

* Add secret template ([#26](https://github.com/accelleran/helm-charts/issues/26)) ([b5d4908](https://github.com/accelleran/helm-charts/commit/b5d490862362eb9b94dbd89b30d89131b5dd12d8))


### Performance Improvements

* Use `-1` offset iso `beginning` for kafka init container ([#27](https://github.com/accelleran/helm-charts/issues/27)) ([a8b5898](https://github.com/accelleran/helm-charts/commit/a8b58987a45c5d2687110da25e6773bd4ba4dc84))
