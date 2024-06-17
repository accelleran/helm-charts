# Changelog

## [7.1.1](https://github.com/accelleran/helm-charts/compare/drax-7.1.0...drax-7.1.1) (2024-06-17)


### Bug Fixes

* **deps:** Update helm release cell-wrapper to v3.1.1 ([e8e32af](https://github.com/accelleran/helm-charts/commit/e8e32af4b35a46e2b067cbe6e23d81e1fca49c0c))

## [7.1.0](https://github.com/accelleran/helm-charts/compare/drax-7.0.1...drax-7.1.0) (2024-03-22)


### Features

* Add Mobility tab to CU-CP configuration on Dashboard ([7c9dd57](https://github.com/accelleran/helm-charts/commit/7c9dd57ea068f7024ad6a4018dfca64c3ae72e1c))
* External neighbors can now be configured via dRAX API ([e102a00](https://github.com/accelleran/helm-charts/commit/e102a006b07e31ec51d1e3948c36491371a1a911))
* Support O1 VES-style ANR notifications on Dashboard ([7c9dd57](https://github.com/accelleran/helm-charts/commit/7c9dd57ea068f7024ad6a4018dfca64c3ae72e1c))


### Bug Fixes

* Average all CU-UP counters across UEs ([b227c4b](https://github.com/accelleran/helm-charts/commit/b227c4b991795fd695ad1c10d1dc35cbfe99b977))
* **deps:** Update accelleran/config-api docker tag to v1.2.0 ([e102a00](https://github.com/accelleran/helm-charts/commit/e102a006b07e31ec51d1e3948c36491371a1a911))
* **deps:** Update accelleran/dash-front-back-end docker tag to v5.1.0 ([7c9dd57](https://github.com/accelleran/helm-charts/commit/7c9dd57ea068f7024ad6a4018dfca64c3ae72e1c))
* **deps:** Update helm release redis to v18.19.3 ([f695a10](https://github.com/accelleran/helm-charts/commit/f695a1095e3ee024236fe2877cf1948eded3e13d))
* **deps:** Update helm release redis to v18.19.4 ([9f775c0](https://github.com/accelleran/helm-charts/commit/9f775c0798c23260952d7974d0a8707853cebb3d))
* Fix grafana port injected as int into tpl ([#176](https://github.com/accelleran/helm-charts/issues/176)) ([1a02506](https://github.com/accelleran/helm-charts/commit/1a02506fbd1373b04882f48de8ea6975bf84bb2c))

## [7.0.1](https://github.com/accelleran/helm-charts/compare/drax-7.0.0...drax-7.0.1) (2024-03-14)


### Bug Fixes

* **deps:** Update accelleran/service-orchestrator docker tag to v1.1.0 ([8fd83ff](https://github.com/accelleran/helm-charts/commit/8fd83ffa9b8717e1958a029dad09850e1de177a8))
* **deps:** Update helm release grafana to v7.3.6 ([5b2d2a7](https://github.com/accelleran/helm-charts/commit/5b2d2a7a65cc4c46380c6071be8e4f926e051c76))
* **deps:** Update helm release grafana to v7.3.7 ([5d3353f](https://github.com/accelleran/helm-charts/commit/5d3353ff63bf702aac84db04dc9b75c0c7554523))
* **deps:** Update helm release kafka to v27.1.1 ([29ecc84](https://github.com/accelleran/helm-charts/commit/29ecc84fbec131a2079780b0d6ac9d96b8292dfa))
* **deps:** Update helm release kafka to v27.1.2 ([af16c98](https://github.com/accelleran/helm-charts/commit/af16c98c4c0c64797df4638eff8db302720ec9bc))
* **deps:** Update helm release nats to v1.1.10 ([9fe5adc](https://github.com/accelleran/helm-charts/commit/9fe5adc45fb5e3c42227ba38abc223a8f0a8c71a))
* **deps:** Update helm release prometheus to v25.17.0 ([8c2521f](https://github.com/accelleran/helm-charts/commit/8c2521fdda1c1ef7cfa899e34fe598864d50ca57))
* **deps:** Update helm release redis to v18.19.2 ([5c9df2d](https://github.com/accelleran/helm-charts/commit/5c9df2d3438cfcb9905fadd45d61ede06669f3a0))
* **deps:** Update helm release vector to v0.31.1 ([3a30299](https://github.com/accelleran/helm-charts/commit/3a3029938613d37480e1aa24d106a321a2a458db))
* Incorrect alias for CU-UP throughput in Grafana ([7ded86b](https://github.com/accelleran/helm-charts/commit/7ded86b20e627f36830a314fcbb6cdd379b39c47))
* Incorrect CU PM Counters in Grafana Dashboards ([4b05915](https://github.com/accelleran/helm-charts/commit/4b059153e6a25a1883067d1dc96c17858a509b70))
* Use MinStep in Grafana UE Monitoring dashboard ([4fa916e](https://github.com/accelleran/helm-charts/commit/4fa916e14315846d0fb86b3520e106a5d6d7f262))

## [7.0.0](https://github.com/accelleran/helm-charts/compare/drax-v6.5.3...drax-7.0.0) (2024-03-06)


### ⚠ BREAKING CHANGES

* update Dashboard app version to v5.0.0
* fix dashboard chart name ([#83](https://github.com/accelleran/helm-charts/issues/83))
* convert drax to common library charts ([#23](https://github.com/accelleran/helm-charts/issues/23))

### Features

* Add anonymous access to grafana dashboards ([#112](https://github.com/accelleran/helm-charts/issues/112)) ([9f04241](https://github.com/accelleran/helm-charts/commit/9f042418c4dfcbcdde51304bd079bb9fbda90b49))
* Add service-orchestrator configuration file ([54615b6](https://github.com/accelleran/helm-charts/commit/54615b6f888fa1ec817f764bae52a884a99a93ca))
* Added snssai pm counters ([#63](https://github.com/accelleran/helm-charts/issues/63)) ([e344977](https://github.com/accelleran/helm-charts/commit/e3449773d0458ee8c6ed0b0f126c6c1630fdd73b))
* Convert drax to common library charts ([#23](https://github.com/accelleran/helm-charts/issues/23)) ([f242126](https://github.com/accelleran/helm-charts/commit/f242126c35a9f89c636ec73ef6a3f98f5d3a9c38))
* Update Dashboard app version to v5.0.0 ([0896d8e](https://github.com/accelleran/helm-charts/commit/0896d8e5bc7f009650c11f47f8356ddc222b2f7d))
* Use nodeports iso loadbalancer IPs for external access to kafka ([#82](https://github.com/accelleran/helm-charts/issues/82)) ([11c10c0](https://github.com/accelleran/helm-charts/commit/11c10c06ff9fdf702704477817ed1f39b8b999b6))


### Bug Fixes

* Add init container to wait for kafka ([#110](https://github.com/accelleran/helm-charts/issues/110)) ([d1c97fa](https://github.com/accelleran/helm-charts/commit/d1c97fa7a5187923faa4eae28bae7e30db20b840))
* Add necessary labels for nats and redis service discovery ([a236dd0](https://github.com/accelleran/helm-charts/commit/a236dd08fc8995b0d49cf0efa3468e960944adf7))
* Change docs endpoint ([628639a](https://github.com/accelleran/helm-charts/commit/628639a8697da7fb7dc71daf1c484a5d8960137e))
* Comment out broken dashboards ([0068adc](https://github.com/accelleran/helm-charts/commit/0068adcada32705120f980cb7487b993baf10f61))
* **deps:** Update dashboard app version to 5.0.2 ([#123](https://github.com/accelleran/helm-charts/issues/123)) ([e79fd6b](https://github.com/accelleran/helm-charts/commit/e79fd6be7e78b6de8166af476eb6991e79cd5f78))
* **deps:** Update e2 app version to 5.2.14 ([5e587a8](https://github.com/accelleran/helm-charts/commit/5e587a89f63c0f3a9c269db8d341f038cf65c292))
* **deps:** Update golang-nkafka to 1.3.5 ([534a5dd](https://github.com/accelleran/helm-charts/commit/534a5dd7cd88020c3169fd7e49d5bc765db29624))
* **deps:** Update Helm release cell-wrapper to v3.0.1 ([#59](https://github.com/accelleran/helm-charts/issues/59)) ([06279a5](https://github.com/accelleran/helm-charts/commit/06279a57e4d810c9dde8acf5d47f26158c50e7a9))
* **deps:** Update Helm release cell-wrapper to v3.0.2 ([06d28ea](https://github.com/accelleran/helm-charts/commit/06d28ea5c0bb241478566e0f18eeccc7c1e5a652))
* **deps:** Update Helm release cell-wrapper to v3.0.3 ([34b5f7b](https://github.com/accelleran/helm-charts/commit/34b5f7bb1451b94b5877b25a20389c6765e5c38a))
* **deps:** Update helm release cell-wrapper to v3.1.0 ([8959a1f](https://github.com/accelleran/helm-charts/commit/8959a1f333776bdd36ac9a278b49c017ce863f6d))
* **deps:** Update Helm release common to v0.1.2 ([06a826b](https://github.com/accelleran/helm-charts/commit/06a826b4b6a2b2c9effa9b573073bfe613d1d4d7))
* **deps:** Update Helm release common to v0.2.0 ([1aac9cc](https://github.com/accelleran/helm-charts/commit/1aac9ccce09460dba36b5beed8e4f7eb45fb0a3e))
* **deps:** Update helm release common to v0.2.2 ([b228a5f](https://github.com/accelleran/helm-charts/commit/b228a5f3aaee93ad7ea4127362cf815d98bd48c2))
* **deps:** Update Helm release grafana to v7.3.0 ([4d0abac](https://github.com/accelleran/helm-charts/commit/4d0abacfcd362ecdcf55fac95b9c1252fa038e97))
* **deps:** Update Helm release grafana to v7.3.1 ([2fd5ccd](https://github.com/accelleran/helm-charts/commit/2fd5ccdaee83bf0331be821732c5696cb9580110))
* **deps:** Update Helm release grafana to v7.3.2 ([9ee46ae](https://github.com/accelleran/helm-charts/commit/9ee46ae9c7186ae11366c3009e2755a767e5bdc0))
* **deps:** Update helm release grafana to v7.3.3 ([32d5034](https://github.com/accelleran/helm-charts/commit/32d5034020394361486854d07836c5504487f33b))
* **deps:** Update Helm release kafka to v26.10.0 ([ba67558](https://github.com/accelleran/helm-charts/commit/ba675581528407cdd186cc0d011bc82800ea32d8))
* **deps:** Update Helm release kafka to v26.11.1 ([82af0b2](https://github.com/accelleran/helm-charts/commit/82af0b2b7c39660c8dcd017c5abc390a0b019c71))
* **deps:** Update Helm release kafka to v26.11.2 ([ff65a78](https://github.com/accelleran/helm-charts/commit/ff65a78b4996240ebed5f91b9438c8f72d0c1f05))
* **deps:** Update helm release kafka to v26.11.3 ([32d26a8](https://github.com/accelleran/helm-charts/commit/32d26a8c851b8bb6d5546ddfec59d0dc777901c1))
* **deps:** Update helm release kafka to v26.11.4 ([c109ea1](https://github.com/accelleran/helm-charts/commit/c109ea18ec450e451672681495f44fea35ea5f02))
* **deps:** Update Helm release kafka to v26.8.3 ([9718c3b](https://github.com/accelleran/helm-charts/commit/9718c3b2d0066357b00387aca9b32ef56804f485))
* **deps:** Update Helm release kafka to v26.8.4 ([c2a6641](https://github.com/accelleran/helm-charts/commit/c2a6641092805ea43bb4cfa071f9d0be0f6b72db))
* **deps:** Update Helm release kafka to v26.8.5 ([a538baf](https://github.com/accelleran/helm-charts/commit/a538baf45a9749865350a616fd4694d1f4fcb7f2))
* **deps:** Update Helm release kafka to v26.9.0 ([54a7453](https://github.com/accelleran/helm-charts/commit/54a745364c85ca95acf80e3f452bbb4b33d5d228))
* **deps:** Update helm release kafka to v27 ([#130](https://github.com/accelleran/helm-charts/issues/130)) ([1d99235](https://github.com/accelleran/helm-charts/commit/1d99235672a8559b32b83c0388a26b77b1926e35))
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
* **deps:** Update helm release prometheus to v25.15.0 ([f45dd4e](https://github.com/accelleran/helm-charts/commit/f45dd4e968c848f301d03a4bdf1096d6f3ea98f9))
* **deps:** Update helm release prometheus to v25.16.0 ([2742d30](https://github.com/accelleran/helm-charts/commit/2742d30541872bfe8e67a44c703f775ec2faffce))
* **deps:** Update Helm release redis to v18.11.0 ([#50](https://github.com/accelleran/helm-charts/issues/50)) ([99fdf92](https://github.com/accelleran/helm-charts/commit/99fdf92a2cdfcd62d622aeac3a85804635761191))
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
* **deps:** Update Helm release vector to v0.30.2 ([acd0d0b](https://github.com/accelleran/helm-charts/commit/acd0d0b89c82239c3ee58fbfb78bdb673a95f590))
* **deps:** Update Helm release vector to v0.31.0 ([be40b5b](https://github.com/accelleran/helm-charts/commit/be40b5baec0433551c12eeea9d54d6582ab21b66))
* Disable license ([0879950](https://github.com/accelleran/helm-charts/commit/087995051116e24b2fce63f3abe337ac84dc0a13))
* **drax/service-orchestrator:** Incorrect Content-Type in CU/xApp Deploy/Delete APIs ([#66](https://github.com/accelleran/helm-charts/issues/66)) ([01d38de](https://github.com/accelleran/helm-charts/commit/01d38de84fc44136cfe0571f9875529aab9b358a))
* Enable prometheus node exporter ([#81](https://github.com/accelleran/helm-charts/issues/81)) ([66d6f0a](https://github.com/accelleran/helm-charts/commit/66d6f0a58f17544e208e49cae68b6c778731a676))
* Fix dashboard chart name ([#83](https://github.com/accelleran/helm-charts/issues/83)) ([049c207](https://github.com/accelleran/helm-charts/commit/049c20719d453b16d1decae5aa3211579527d366))
* Fix external ric api to use nodePort 31315 instead of port 5000 ([d60244d](https://github.com/accelleran/helm-charts/commit/d60244dcef7c72678845c025c19414c02008aece))
* Fix globally enabling license for nkafka, service-monitor and service-orchestrator ([121a70b](https://github.com/accelleran/helm-charts/commit/121a70bb76c01ade3235418bee68dc3688e37324))
* Fix kafka requiring automount explicitly per componen ([8bdbb5e](https://github.com/accelleran/helm-charts/commit/8bdbb5e2f03ef3944992852bf74be4e70dbb24ff))
* Fix missing global section for linter ([61b50c6](https://github.com/accelleran/helm-charts/commit/61b50c6490aee00e11da86b7405f84c4da9f1e3b))
* Fix target port of service-orchestrator ([c845da9](https://github.com/accelleran/helm-charts/commit/c845da99df8483944c77881e888a5d9d9a8a1538))
* Generate dashboard serviceName and serviceNamespace via templates instead of configuration ([6d2a588](https://github.com/accelleran/helm-charts/commit/6d2a58806f3c305d782633b31d7db324f4f40a27))
* Incorrect URL for network-state-monitor OpenAPI JSON ([#122](https://github.com/accelleran/helm-charts/issues/122)) ([e0e8833](https://github.com/accelleran/helm-charts/commit/e0e8833ed069d5218e90cec65247056920a6a5d7))
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
