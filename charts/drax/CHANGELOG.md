# Changelog

## [7.0.0](https://github.com/accelleran/helm-charts/compare/drax-v6.5.3...drax-7.0.0) (2024-06-17)


### ⚠ BREAKING CHANGES

* convert drax to common library charts ([#23](https://github.com/accelleran/helm-charts/issues/23))

### Features

* Add service-orchestrator configuration file ([54615b6](https://github.com/accelleran/helm-charts/commit/54615b6f888fa1ec817f764bae52a884a99a93ca))
* Added snssai pm counters ([#63](https://github.com/accelleran/helm-charts/issues/63)) ([e344977](https://github.com/accelleran/helm-charts/commit/e3449773d0458ee8c6ed0b0f126c6c1630fdd73b))
* Convert drax to common library charts ([#23](https://github.com/accelleran/helm-charts/issues/23)) ([f242126](https://github.com/accelleran/helm-charts/commit/f242126c35a9f89c636ec73ef6a3f98f5d3a9c38))
* Use nodeports iso loadbalancer IPs for external access to kafka ([#82](https://github.com/accelleran/helm-charts/issues/82)) ([11c10c0](https://github.com/accelleran/helm-charts/commit/11c10c06ff9fdf702704477817ed1f39b8b999b6))


### Bug Fixes

* Add necessary labels for nats and redis service discovery ([a236dd0](https://github.com/accelleran/helm-charts/commit/a236dd08fc8995b0d49cf0efa3468e960944adf7))
* Comment out broken dashboards ([0068adc](https://github.com/accelleran/helm-charts/commit/0068adcada32705120f980cb7487b993baf10f61))
* **deps:** Update golang-nkafka to 1.3.5 ([534a5dd](https://github.com/accelleran/helm-charts/commit/534a5dd7cd88020c3169fd7e49d5bc765db29624))
* **deps:** Update Helm release cell-wrapper to v3.0.1 ([#59](https://github.com/accelleran/helm-charts/issues/59)) ([06279a5](https://github.com/accelleran/helm-charts/commit/06279a57e4d810c9dde8acf5d47f26158c50e7a9))
* **deps:** Update Helm release cell-wrapper to v3.0.2 ([06d28ea](https://github.com/accelleran/helm-charts/commit/06d28ea5c0bb241478566e0f18eeccc7c1e5a652))
* **deps:** Update Helm release cell-wrapper to v3.0.3 ([34b5f7b](https://github.com/accelleran/helm-charts/commit/34b5f7bb1451b94b5877b25a20389c6765e5c38a))
* **deps:** Update Helm release common to v0.1.2 ([06a826b](https://github.com/accelleran/helm-charts/commit/06a826b4b6a2b2c9effa9b573073bfe613d1d4d7))
* **deps:** Update Helm release common to v0.2.0 ([1aac9cc](https://github.com/accelleran/helm-charts/commit/1aac9ccce09460dba36b5beed8e4f7eb45fb0a3e))
* **deps:** Update Helm release grafana to v7.3.0 ([4d0abac](https://github.com/accelleran/helm-charts/commit/4d0abacfcd362ecdcf55fac95b9c1252fa038e97))
* **deps:** Update Helm release grafana to v7.3.1 ([2fd5ccd](https://github.com/accelleran/helm-charts/commit/2fd5ccdaee83bf0331be821732c5696cb9580110))
* **deps:** Update Helm release grafana to v7.3.2 ([9ee46ae](https://github.com/accelleran/helm-charts/commit/9ee46ae9c7186ae11366c3009e2755a767e5bdc0))
* **deps:** Update Helm release kafka to v26.10.0 ([ba67558](https://github.com/accelleran/helm-charts/commit/ba675581528407cdd186cc0d011bc82800ea32d8))
* **deps:** Update Helm release kafka to v26.11.1 ([82af0b2](https://github.com/accelleran/helm-charts/commit/82af0b2b7c39660c8dcd017c5abc390a0b019c71))
* **deps:** Update Helm release kafka to v26.11.2 ([ff65a78](https://github.com/accelleran/helm-charts/commit/ff65a78b4996240ebed5f91b9438c8f72d0c1f05))
* **deps:** Update helm release kafka to v26.11.3 ([32d26a8](https://github.com/accelleran/helm-charts/commit/32d26a8c851b8bb6d5546ddfec59d0dc777901c1))
* **deps:** Update Helm release kafka to v26.8.3 ([9718c3b](https://github.com/accelleran/helm-charts/commit/9718c3b2d0066357b00387aca9b32ef56804f485))
* **deps:** Update Helm release kafka to v26.8.4 ([c2a6641](https://github.com/accelleran/helm-charts/commit/c2a6641092805ea43bb4cfa071f9d0be0f6b72db))
* **deps:** Update Helm release kafka to v26.8.5 ([a538baf](https://github.com/accelleran/helm-charts/commit/a538baf45a9749865350a616fd4694d1f4fcb7f2))
* **deps:** Update Helm release kafka to v26.9.0 ([54a7453](https://github.com/accelleran/helm-charts/commit/54a745364c85ca95acf80e3f452bbb4b33d5d228))
* **deps:** Update Helm release kminion to v0.12.5 ([4fc82c9](https://github.com/accelleran/helm-charts/commit/4fc82c9aa08bf0072b17db01bdc200167f9d3837))
* **deps:** Update Helm release kminion to v0.12.6 ([488cad4](https://github.com/accelleran/helm-charts/commit/488cad498bcf1b4230cef13d3fc600cf3765d5e1))
* **deps:** Update Helm release kminion to v0.12.7 ([4d9e5f5](https://github.com/accelleran/helm-charts/commit/4d9e5f5f85f2fedb4cbfe5e0541addf289146d27))
* **deps:** Update Helm release loki-stack to v2.10.1 ([0ceac75](https://github.com/accelleran/helm-charts/commit/0ceac75d1a1528b238e9a118586edc06f6606731))
* **deps:** Update Helm release nats to v1.1.7 ([#43](https://github.com/accelleran/helm-charts/issues/43)) ([05f7ab0](https://github.com/accelleran/helm-charts/commit/05f7ab0c29f0305fa06607333b7dd7071a7732d0))
* **deps:** Update Helm release nats to v1.1.8 ([a8a95a6](https://github.com/accelleran/helm-charts/commit/a8a95a6497b996ddc798ecc710ed50b29474f8c5))
* **deps:** Update Helm release nats to v1.1.9 ([e5bafec](https://github.com/accelleran/helm-charts/commit/e5bafecf177e9ad19508b4a1e0e1a6cf79853005))
* **deps:** Update Helm release prometheus to v25.11.0 ([ac65cc3](https://github.com/accelleran/helm-charts/commit/ac65cc3888ac563cf3778724b939a47925b7720c))
* **deps:** Update Helm release prometheus to v25.11.1 ([c716f7c](https://github.com/accelleran/helm-charts/commit/c716f7cdc5938c2b88ec90ef39c08ffb89b2918b))
* **deps:** Update Helm release prometheus to v25.12.0 ([be3bbf9](https://github.com/accelleran/helm-charts/commit/be3bbf9cc6a8f9827fbbc008fb65471a19d4f9ac))
* **deps:** Update Helm release prometheus to v25.13.0 ([f40dc53](https://github.com/accelleran/helm-charts/commit/f40dc5358825dc0f1f24be4c8d5591fd3772d294))
* **deps:** Update helm release prometheus to v25.14.0 ([ed25008](https://github.com/accelleran/helm-charts/commit/ed250088611756c44ce093d3f3251be336cf099b))
* **deps:** Update Helm release redis to v18.11.0 ([#50](https://github.com/accelleran/helm-charts/issues/50)) ([99fdf92](https://github.com/accelleran/helm-charts/commit/99fdf92a2cdfcd62d622aeac3a85804635761191))
* **deps:** Update Helm release redis to v18.11.1 ([b25959c](https://github.com/accelleran/helm-charts/commit/b25959c1515a4d4024b235faa67b04adf3c44566))
* **deps:** Update Helm release redis to v18.12.0 ([30c46ad](https://github.com/accelleran/helm-charts/commit/30c46ad72f4701a082efbac28da084343df8099b))
* **deps:** Update Helm release redis to v18.12.1 ([4c36bdd](https://github.com/accelleran/helm-charts/commit/4c36bddfa8d0feaaeda5384aa087956b75ee3ff6))
* **deps:** Update Helm release redis to v18.13.0 ([a51eb34](https://github.com/accelleran/helm-charts/commit/a51eb349b39940aef672b628d9972300e59f64e2))
* **deps:** Update Helm release redis to v18.14.0 ([64d5e7b](https://github.com/accelleran/helm-charts/commit/64d5e7bcf95cd67c0d44ffbd204915899ceed2d2))
* **deps:** Update Helm release redis to v18.15.1 ([e323562](https://github.com/accelleran/helm-charts/commit/e32356257a43a902f439203f4d72ad0c1f47424e))
* **deps:** Update Helm release redis to v18.16.0 ([50a3769](https://github.com/accelleran/helm-charts/commit/50a3769082370a520a8d09f86ddbab9bd5c35bea))
* **deps:** Update Helm release redis to v18.16.1 ([5855eda](https://github.com/accelleran/helm-charts/commit/5855edab65194af94a0e76f4248732d3e29d091c))
* **deps:** Update Helm release vector to v0.30.2 ([acd0d0b](https://github.com/accelleran/helm-charts/commit/acd0d0b89c82239c3ee58fbfb78bdb673a95f590))
* **deps:** Update Helm release vector to v0.31.0 ([be40b5b](https://github.com/accelleran/helm-charts/commit/be40b5baec0433551c12eeea9d54d6582ab21b66))
* Disable license ([0879950](https://github.com/accelleran/helm-charts/commit/087995051116e24b2fce63f3abe337ac84dc0a13))
* **drax/service-orchestrator:** Incorrect Content-Type in CU/xApp Deploy/Delete APIs ([#66](https://github.com/accelleran/helm-charts/issues/66)) ([01d38de](https://github.com/accelleran/helm-charts/commit/01d38de84fc44136cfe0571f9875529aab9b358a))
* Enable prometheus node exporter ([#81](https://github.com/accelleran/helm-charts/issues/81)) ([66d6f0a](https://github.com/accelleran/helm-charts/commit/66d6f0a58f17544e208e49cae68b6c778731a676))
* Fix globally enabling license for nkafka, service-monitor and service-orchestrator ([121a70b](https://github.com/accelleran/helm-charts/commit/121a70bb76c01ade3235418bee68dc3688e37324))
* Fix kafka requiring automount explicitly per componen ([8bdbb5e](https://github.com/accelleran/helm-charts/commit/8bdbb5e2f03ef3944992852bf74be4e70dbb24ff))
* Fix missing global section for linter ([61b50c6](https://github.com/accelleran/helm-charts/commit/61b50c6490aee00e11da86b7405f84c4da9f1e3b))
* Fix target port of service-orchestrator ([c845da9](https://github.com/accelleran/helm-charts/commit/c845da99df8483944c77881e888a5d9d9a8a1538))
* Limit default storage requests ([4f12ea7](https://github.com/accelleran/helm-charts/commit/4f12ea73e875af8ebd4591f754670707b19a6ffd))
* Remove unnecessary capabilities in service-monitor ([e71a06f](https://github.com/accelleran/helm-charts/commit/e71a06f32e2aa8d85558c06156ee7e9254de5b0b))
* Remove unnecessary capabilities in service-orchestrator ([aea4836](https://github.com/accelleran/helm-charts/commit/aea4836a7a97ac9845806124b73af2704fdbc0e0))
* Remove warning for VECTOR_LOG ([6d11774](https://github.com/accelleran/helm-charts/commit/6d117746e9022781a1614a32a72ce332fc0dacdf))
* Replace deprecated fluent-bit with promtail ([#74](https://github.com/accelleran/helm-charts/issues/74)) ([3c896f4](https://github.com/accelleran/helm-charts/commit/3c896f40efeee7f7742481cf7077d3460eace953))
* Switch to redpanda chart repo for kminion ([#67](https://github.com/accelleran/helm-charts/issues/67)) ([da2221e](https://github.com/accelleran/helm-charts/commit/da2221e954dec7b4aadc34ac0afba3d21e92a4ae))
* Use nodeport to expose e2-t sctp ([#68](https://github.com/accelleran/helm-charts/issues/68)) ([f9f8253](https://github.com/accelleran/helm-charts/commit/f9f8253e714a0a1b3f9442aa0903b018ef6e03f0))


### Reverts

* Work around kminion config not allowing templating ([e57798c](https://github.com/accelleran/helm-charts/commit/e57798c557f26864683256e8b4231dd1f0864713))


### Miscellaneous Chores

* Release 7.0.0-rc.1 ([f0061e2](https://github.com/accelleran/helm-charts/commit/f0061e2225450ce605184317edc322c1f2c9f338))
* Release 7.0.0-rc.2 ([0cbe2e1](https://github.com/accelleran/helm-charts/commit/0cbe2e1c1d703b18d07a2e201c3173b71a065b15))
