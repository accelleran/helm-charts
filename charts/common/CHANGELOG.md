# Changelog

## [0.4.0](https://github.com/accelleran/helm-charts/compare/common-0.3.13...common-0.4.0) (2025-02-19)


### ⚠ BREAKING CHANGES

* remove default license image suffix
* automatically update license in pods

### Features

* Automatically update license in pods ([880297c](https://github.com/accelleran/helm-charts/commit/880297c5e478d53b60974dd0380c5e956a9ced54))


### Bug Fixes

* Remove default license image suffix ([24a5f75](https://github.com/accelleran/helm-charts/commit/24a5f7547b76bf9a52a14fd59a5ef5d3510ecb58))

## [0.3.13](https://github.com/accelleran/helm-charts/compare/common-0.3.12...common-0.3.13) (2025-01-08)


### Features

* Allow to override license image suffix ([#879](https://github.com/accelleran/helm-charts/issues/879)) ([6a2050e](https://github.com/accelleran/helm-charts/commit/6a2050e863141346e6f87f219f60463b735d4e69))

## [0.3.12](https://github.com/accelleran/helm-charts/compare/common-0.3.11...common-0.3.12) (2025-01-08)


### Features

* Add accelleran license mount path ([#870](https://github.com/accelleran/helm-charts/issues/870)) ([0e34cbf](https://github.com/accelleran/helm-charts/commit/0e34cbf5b2e050836d0f0e187bd92e224576990f))

## [0.3.11](https://github.com/accelleran/helm-charts/compare/common-0.3.10...common-0.3.11) (2024-11-25)


### Features

* Add drax persistent log level label ([#788](https://github.com/accelleran/helm-charts/issues/788)) ([47e4589](https://github.com/accelleran/helm-charts/commit/47e4589abc4d33d34a51838f9ab7d7022dca40fe))

## [0.3.10](https://github.com/accelleran/helm-charts/compare/common-0.3.9...common-0.3.10) (2024-11-18)


### Features

* Allow to inject pod annotations via template args ([#743](https://github.com/accelleran/helm-charts/issues/743)) ([96896e8](https://github.com/accelleran/helm-charts/commit/96896e8f9ede25ca581fb59eeddf655e9e18b9c9))

## [0.3.9](https://github.com/accelleran/helm-charts/compare/common-0.3.8...common-0.3.9) (2024-10-07)


### Features

* Add tpl to load balancer service ip ([8130e21](https://github.com/accelleran/helm-charts/commit/8130e21b0b8e66635d8d88c1a69f42e9e0cfc410))
* Add ttlSecondsAfterFinished to job ([50ee770](https://github.com/accelleran/helm-charts/commit/50ee770e3ba1e5ce478d5fb84a8094ae0f6514fc))
* Allow to provide binary data to configmap ([535a9aa](https://github.com/accelleran/helm-charts/commit/535a9aafc032bc5e53752f9e26cd90cfaa1fd962))
* Allow to provide command and args via tpl args ([ae57227](https://github.com/accelleran/helm-charts/commit/ae57227ace6bc70f8fe8068125b6e1d8a906916a))


### Bug Fixes

* Fix app version when absent ([d4e64cc](https://github.com/accelleran/helm-charts/commit/d4e64cc9e3feb0db67f91c14af946500d69d8b92))

## [0.3.8](https://github.com/accelleran/helm-charts/compare/common-0.3.7...common-0.3.8) (2024-09-11)


### Bug Fixes

* Fix missing service block resulting in panic ([#527](https://github.com/accelleran/helm-charts/issues/527)) ([0fae62a](https://github.com/accelleran/helm-charts/commit/0fae62a0987bf1f14505ac0c18323c2d5c36091d))

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
