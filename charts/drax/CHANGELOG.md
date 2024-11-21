# Changelog

## [12.0.0](https://github.com/accelleran/helm-charts/compare/drax-11.0.2...drax-12.0.0) (2024-11-21)


### ⚠ BREAKING CHANGES

* drop debug and trace messages for loki storage ([#738](https://github.com/accelleran/helm-charts/issues/738))
* limit minio to a single drive ([#674](https://github.com/accelleran/helm-charts/issues/674))

### Bug Fixes

* **deps:** Update accelleran/service-monitor docker tag to v1.2.1 ([067ecef](https://github.com/accelleran/helm-charts/commit/067ecef7eb37d76adc07ddd8a766bc878c759b32))
* **deps:** Update accelleran/service-monitor docker tag to v1.2.2 ([552355a](https://github.com/accelleran/helm-charts/commit/552355a97230a31d19186624d64bab5846987a88))
* **deps:** Update accelleran/service-orchestrator docker tag to v1.3.0 ([316fcd0](https://github.com/accelleran/helm-charts/commit/316fcd09f432f827701fdeb77f387ac5fa186d8d))
* **deps:** Update helm release cell-wrapper to v6.0.3 ([efbae96](https://github.com/accelleran/helm-charts/commit/efbae96138db21fc2264101f42652373f843a4b7))
* **deps:** Update helm release common to v0.3.10 ([#750](https://github.com/accelleran/helm-charts/issues/750)) ([76fda7f](https://github.com/accelleran/helm-charts/commit/76fda7fc76c6926b402b49f3348b14a785af92f8))
* **deps:** Update helm release du-metrics-server to v0.4.2 ([8182162](https://github.com/accelleran/helm-charts/commit/8182162007a16c482d0889311e098e1121e52250))
* **deps:** Update helm release grafana to v8.6.0 ([219a77d](https://github.com/accelleran/helm-charts/commit/219a77dfbf9fd44b29114cd0aebfe27d610172dc))
* **deps:** Update helm release grafana-loki to v4.6.23 ([6396783](https://github.com/accelleran/helm-charts/commit/63967834ea31e8c651b6b86033cbaef66cce44c6))
* **deps:** Update helm release kafka to v31 ([#733](https://github.com/accelleran/helm-charts/issues/733)) ([ad16762](https://github.com/accelleran/helm-charts/commit/ad16762721caf12185047242eca9a26bb8df68c2))
* **deps:** Update helm release loki-deleter to v0.1.2 ([8e37af2](https://github.com/accelleran/helm-charts/commit/8e37af2b05ccf4d8bec0d434cc85a43a247979bd))
* **deps:** Update helm release loki-gateway to v0.1.6 ([3de6c81](https://github.com/accelleran/helm-charts/commit/3de6c81fe674f794da3a4e04688a827d047226e2))
* **deps:** Update helm release prometheus to v25.30.0 ([cb6c478](https://github.com/accelleran/helm-charts/commit/cb6c478a726404cdf03c09f898491c75808513e3))
* **deps:** Update helm release prometheus to v25.30.1 ([26d778f](https://github.com/accelleran/helm-charts/commit/26d778f8f664c86ca6d949faa79cfd26dc893f08))
* **deps:** Update helm release redis to v20.2.2 ([f1e258d](https://github.com/accelleran/helm-charts/commit/f1e258dcfb83ea74c5f7abc2ce6e6b56eb0bcf15))
* **deps:** Update helm release redis to v20.3.0 ([d2152bc](https://github.com/accelleran/helm-charts/commit/d2152bcdac7179661ab98c7d996cefeacebd532c))
* **deps:** Update helm release telemetry-collector to v1.1.4 ([54bcb59](https://github.com/accelleran/helm-charts/commit/54bcb59dcbb029e2a1714cc94234d9a8e8f835db))
* Drop debug and trace messages for loki storage ([#738](https://github.com/accelleran/helm-charts/issues/738)) ([f9cd9b4](https://github.com/accelleran/helm-charts/commit/f9cd9b4f2107474200201c290370ff0a51028d39))
* Limit minio to a single drive ([#674](https://github.com/accelleran/helm-charts/issues/674)) ([23f42ad](https://github.com/accelleran/helm-charts/commit/23f42ade1c865d1699a402580cce32d4ac04896c))

## [11.0.2](https://github.com/accelleran/helm-charts/compare/drax-11.0.1...drax-11.0.2) (2024-11-07)


### Bug Fixes

* Add buckets, fix influx url ([#716](https://github.com/accelleran/helm-charts/issues/716)) ([70fcdca](https://github.com/accelleran/helm-charts/commit/70fcdca15e474685ee4f259f32eab2fbaa2e2230))
* Create default influxdb2 bucket ([#719](https://github.com/accelleran/helm-charts/issues/719)) ([eb22a44](https://github.com/accelleran/helm-charts/commit/eb22a44e86879c8c72b1d096a7eef4bf1825e0ea))
* **deps:** Update accelleran/network-state-monitor docker tag to v1.3.0 ([9b032d0](https://github.com/accelleran/helm-charts/commit/9b032d05f2e5f2d6c8f95f2f4b56497d5793204f))
* **deps:** Update helm release grafana to v8.5.12 ([aa87b72](https://github.com/accelleran/helm-charts/commit/aa87b7295779a2640fe449a722de4a75605ea635))
* **deps:** Update helm release grafana-loki to v4.6.22 ([d292423](https://github.com/accelleran/helm-charts/commit/d292423a7e763e4a04e9f199b3c20db9519a947d))
* **deps:** Update helm release loki-deleter to v0.1.1 ([4cf256c](https://github.com/accelleran/helm-charts/commit/4cf256c59088320a57d3f82efd48e8c245f5ba51))
* **deps:** Update helm release prometheus to v25.29.0 ([e1a8adb](https://github.com/accelleran/helm-charts/commit/e1a8adbb47ecad8d849c1dbdddbb354aa8af3ba6))
* **deps:** Update helm release telemetry-collector to v1.1.3 ([07cbdfa](https://github.com/accelleran/helm-charts/commit/07cbdfabf865c6f6b140776ee695f88e33533c10))
* Set loki retention delete delay to 1m ([#708](https://github.com/accelleran/helm-charts/issues/708)) ([3373800](https://github.com/accelleran/helm-charts/commit/3373800c4c8d204090dde85d93ad5d5826e7be58))
* Tune parameters to delete loki logs ([#713](https://github.com/accelleran/helm-charts/issues/713)) ([6283a4a](https://github.com/accelleran/helm-charts/commit/6283a4a2d39d99307d19e34bc75d3c3af26a8a7f))

## [11.0.1](https://github.com/accelleran/helm-charts/compare/drax-11.0.0...drax-11.0.1) (2024-11-04)


### Bug Fixes

* **deps:** Update helm release grafana to v8.5.10 ([c7d207b](https://github.com/accelleran/helm-charts/commit/c7d207b6de4aa3403303825fb18c13a882813b1c))
* **deps:** Update helm release grafana to v8.5.11 ([ece0ccc](https://github.com/accelleran/helm-charts/commit/ece0ccc1d09c3008e033d05a7ca6e55dfb15ae90))
* **deps:** Update helm release grafana to v8.5.9 ([3715c13](https://github.com/accelleran/helm-charts/commit/3715c13799d898d1fb46eb4b55e26e3447774b0a))
* **deps:** Update helm release grafana-loki to v4.6.21 ([6689b84](https://github.com/accelleran/helm-charts/commit/6689b84c05c2ecf72767a4f72c9b0d5c3c00b1f4))
* **deps:** Update helm release kafka to v30.1.7 ([be08d22](https://github.com/accelleran/helm-charts/commit/be08d2227a83b457a4e619b95ec0d2e4ccacc42a))
* **deps:** Update helm release kafka to v30.1.8 ([32af3cb](https://github.com/accelleran/helm-charts/commit/32af3cb7a18633c2ec2decf626bec8bbf71c378a))
* **deps:** Update helm release loki-gateway to v0.1.4 ([023bb6d](https://github.com/accelleran/helm-charts/commit/023bb6da05713d9b3e3a0c4fca722ca9ae60ba80))
* Set loki retention delete delay ([#705](https://github.com/accelleran/helm-charts/issues/705)) ([b91d392](https://github.com/accelleran/helm-charts/commit/b91d39263245b8d52ccfb716bd42d8a923531445))

## [11.0.0](https://github.com/accelleran/helm-charts/compare/drax-10.1.0...drax-11.0.0) (2024-10-28)


### ⚠ BREAKING CHANGES

* support latest sdk ([#690](https://github.com/accelleran/helm-charts/issues/690))

### Features

* Add loki-deleter to drax ([0800895](https://github.com/accelleran/helm-charts/commit/0800895de3442f52220ad7e9a09ff7c2807f8f34))
* Support latest sdk ([#690](https://github.com/accelleran/helm-charts/issues/690)) ([102d159](https://github.com/accelleran/helm-charts/commit/102d159ee3ef2cf4071c1aef9b8ec9746ffdffbb))


### Bug Fixes

* Add retention to kafka to prevent node disk pressure ([#671](https://github.com/accelleran/helm-charts/issues/671)) ([32fed2e](https://github.com/accelleran/helm-charts/commit/32fed2ef11a3c8b1499c2067b79355feae782328))
* **deps:** Update accelleran/e2smrcappl docker tag to v6.0.1 ([cb07112](https://github.com/accelleran/helm-charts/commit/cb0711214429f9848f69cade5c06b89ff89e82a5))
* **deps:** Update accelleran/e2smrcappl docker tag to v6.0.2 ([45445a7](https://github.com/accelleran/helm-charts/commit/45445a7065d5adead987a5f0efb71bd59b2f8f86))
* **deps:** Update accelleran/e2smrcappl docker tag to v6.0.3 ([f8a3976](https://github.com/accelleran/helm-charts/commit/f8a397600e09b7c9ddbd165e2279c6d70de31363))
* **deps:** Update helm release grafana to v8.5.4 ([2615c26](https://github.com/accelleran/helm-charts/commit/2615c26f358ebb47da86502cd71b27144df4005c))
* **deps:** Update helm release grafana to v8.5.5 ([cfb69af](https://github.com/accelleran/helm-charts/commit/cfb69afd649576f34727d3ab109f08f6b601aa00))
* **deps:** Update helm release grafana to v8.5.6 ([9a01c90](https://github.com/accelleran/helm-charts/commit/9a01c90c89541e4c61a5e60e5595d930e308d61d))
* **deps:** Update helm release grafana to v8.5.8 ([2ae7fbe](https://github.com/accelleran/helm-charts/commit/2ae7fbeb8d210e627e0c9575aec1c5316475308d))
* **deps:** Update helm release grafana-loki to v4.6.19 ([f8896f1](https://github.com/accelleran/helm-charts/commit/f8896f10a7dc4493338ba178c6c29f5aaa4702d2))
* **deps:** Update helm release grafana-loki to v4.6.20 ([34dd1a2](https://github.com/accelleran/helm-charts/commit/34dd1a27bfcde501c976d880faedbb8801ced3c8))
* **deps:** Update helm release kafka to v30.1.6 ([47436eb](https://github.com/accelleran/helm-charts/commit/47436eb41aa18e8d290b49ffda3f378539416cb7))
* **deps:** Update helm release nats to v1.2.6 ([03f51f1](https://github.com/accelleran/helm-charts/commit/03f51f14411a15ad435709dfd2f9ced93e6236f2))
* **deps:** Update helm release prometheus to v25.28.0 ([2aa3b66](https://github.com/accelleran/helm-charts/commit/2aa3b661d10ce5bcc1fcae3855a38d769e665c92))
* **deps:** Update helm release redis to v20.2.1 ([d82a338](https://github.com/accelleran/helm-charts/commit/d82a3387f8b81bfa829263aa998a2df82ec474e9))
* **deps:** Update helm release vector to v0.37.0 ([29651ba](https://github.com/accelleran/helm-charts/commit/29651ba7a6ad01525c8262a6d4094ebf45b71ca7))
* **deps:** Update helm release xapp-hello-world to v5 ([#693](https://github.com/accelleran/helm-charts/issues/693)) ([0439da5](https://github.com/accelleran/helm-charts/commit/0439da513d101e2fc390b6183f1af74d9a4f7b96))
* Fix kafka bytes in and out per topic not displayed as a rate in grafana ([#670](https://github.com/accelleran/helm-charts/issues/670)) ([df1880a](https://github.com/accelleran/helm-charts/commit/df1880a4750ea21f11cd583b0e417f3fbbb1d25a))
* Update grafana dashboard plugin versions ([#672](https://github.com/accelleran/helm-charts/issues/672)) ([9439e04](https://github.com/accelleran/helm-charts/commit/9439e0445b8b7f627cffad5cb54dd7b1c033b8d3))

## [10.1.0](https://github.com/accelleran/helm-charts/compare/drax-10.0.0...drax-10.1.0) (2024-10-14)


### Features

* Add e2sm-ccc deployment template ([#659](https://github.com/accelleran/helm-charts/issues/659)) ([e59e088](https://github.com/accelleran/helm-charts/commit/e59e0884f068fe2f6579f24b7978df3d4138991a))


### Bug Fixes

* **deps:** Update accelleran/dash-front-back-end docker tag to v6.2.4 ([24cb573](https://github.com/accelleran/helm-charts/commit/24cb5733057071009101180a7f14cad6afa4e2a9))
* **deps:** Update helm release cell-wrapper to v6.0.2 ([a052efc](https://github.com/accelleran/helm-charts/commit/a052efcd9ec528a29daded2c314dd2a5dffa5b0a))
* **deps:** Update helm release grafana to v8.5.3 ([4293f26](https://github.com/accelleran/helm-charts/commit/4293f265073cc3890b527f972cc34cb266a814ec))
* **deps:** Update helm release minio to v5.3.0 ([1fac58a](https://github.com/accelleran/helm-charts/commit/1fac58a44c24c18e00e9d179b67ef3145fa3e7aa))

## [10.0.0](https://github.com/accelleran/helm-charts/compare/drax-9.0.1...drax-10.0.0) (2024-10-09)


### ⚠ BREAKING CHANGES

* **deps:** update helm release xapp-hello-world to v4 ([#644](https://github.com/accelleran/helm-charts/issues/644))
* bump e2 broker version ([#633](https://github.com/accelleran/helm-charts/issues/633))
* **deps:** update helm release cell-wrapper to v6 ([#631](https://github.com/accelleran/helm-charts/issues/631))
* **deps:** update helm release du-metrics-server to v0.4.0

### Features

* Bump e2 broker version ([#633](https://github.com/accelleran/helm-charts/issues/633)) ([46629f4](https://github.com/accelleran/helm-charts/commit/46629f47b64195286f0f6a0d2a5931ffd349bc8f))
* **deps:** Update helm release xapp-hello-world to v4 ([#644](https://github.com/accelleran/helm-charts/issues/644)) ([49c346d](https://github.com/accelleran/helm-charts/commit/49c346d7bacf1976f032476b5a4f6633d9e3ebaf))


### Bug Fixes

* Add an external logs user by default ([#611](https://github.com/accelleran/helm-charts/issues/611)) ([137d7ef](https://github.com/accelleran/helm-charts/commit/137d7efb11d17deaffd6062d34429230a9734419))
* Bump nkafka to v1.3.9 with cw v5.0.3 ([bcf336d](https://github.com/accelleran/helm-charts/commit/bcf336d044ce03404692690c6abdc4fe04899970))
* Change default telemetry collector values ([#636](https://github.com/accelleran/helm-charts/issues/636)) ([eb60ee6](https://github.com/accelleran/helm-charts/commit/eb60ee6143c7380962b1333ec1811a6f945ca852))
* **deps:** Update accelleran/dash-front-back-end docker tag to v6.2.3 ([33ccf78](https://github.com/accelleran/helm-charts/commit/33ccf787e7b6a09fa7e32a0b8c43216bb9f0ce89))
* **deps:** Update helm release cell-wrapper to v5.0.4 ([#627](https://github.com/accelleran/helm-charts/issues/627)) ([394e3a6](https://github.com/accelleran/helm-charts/commit/394e3a6d39c444d28c4281750e2964e400e278c7))
* **deps:** Update helm release cell-wrapper to v6 ([#631](https://github.com/accelleran/helm-charts/issues/631)) ([b8d60d0](https://github.com/accelleran/helm-charts/commit/b8d60d022845e345175f0ec00e131564c054c544))
* **deps:** Update helm release cell-wrapper to v6.0.1 ([612d354](https://github.com/accelleran/helm-charts/commit/612d3549a399889cf6a0240270237cdeb4fcaa57))
* **deps:** Update helm release common to v0.3.9 ([#621](https://github.com/accelleran/helm-charts/issues/621)) ([5783bbf](https://github.com/accelleran/helm-charts/commit/5783bbf75b6a5845dfc469d56849e2aae72d1d4c))
* **deps:** Update helm release du-metrics-server to v0.4.0 ([6d21eef](https://github.com/accelleran/helm-charts/commit/6d21eef43676ef12e9cd0aebd998d3b55439e3f3))
* **deps:** Update helm release du-metrics-server to v0.4.1 ([be964b5](https://github.com/accelleran/helm-charts/commit/be964b597558f511f147d53eb35daa450d816e4a))
* **deps:** Update helm release kafka to v30.1.5 ([b5ad922](https://github.com/accelleran/helm-charts/commit/b5ad9228d904f45da9cb7914a020dd248a89670c))
* **deps:** Update helm release redis to v20.2.0 ([7d1bf29](https://github.com/accelleran/helm-charts/commit/7d1bf29fe068c221003636bb90cf118d612d0633))
* **deps:** Update helm release telemetry-collector to v1.1.2 ([#638](https://github.com/accelleran/helm-charts/issues/638)) ([6b75bd7](https://github.com/accelleran/helm-charts/commit/6b75bd750be34b546c1e29b2a16a2b6d4ba7c357))
* Fix du metrics grafana dashboard ([#637](https://github.com/accelleran/helm-charts/issues/637)) ([2ab9e92](https://github.com/accelleran/helm-charts/commit/2ab9e928e4756b88c45f2eeb765828d8c5b22e98))

## [9.0.1](https://github.com/accelleran/helm-charts/compare/drax-9.0.0...drax-9.0.1) (2024-10-03)


### Bug Fixes

* **deps:** Update accelleran/config-api docker tag to v2.0.1 ([#594](https://github.com/accelleran/helm-charts/issues/594)) ([790f05a](https://github.com/accelleran/helm-charts/commit/790f05a701801d48ca133a579a943c44ba7e4a30))
* **deps:** Update helm release cell-wrapper to v5.0.3 ([550ad2e](https://github.com/accelleran/helm-charts/commit/550ad2e548059fa7c1b00487667382dd81102478))
* **deps:** Update helm release grafana to v8.5.2 ([cfe861e](https://github.com/accelleran/helm-charts/commit/cfe861e8ec89f49e1ced224412d6e57206eaddb2))
* **deps:** Update helm release grafana-loki to v4.6.17 ([f2069be](https://github.com/accelleran/helm-charts/commit/f2069be2c44ed0c4acc95610121ff6cb40fab224))
* **deps:** Update helm release grafana-loki to v4.6.18 ([611bedc](https://github.com/accelleran/helm-charts/commit/611bedc6bfdc1edcc469c9e27d4c8610e308db04))
* **deps:** Update helm release loki-gateway to v0.1.3 ([8403b67](https://github.com/accelleran/helm-charts/commit/8403b6776ba0a88abbf74e031875a9c25e117856))
* **deps:** Update helm release nats to v1.2.5 ([6e4c85a](https://github.com/accelleran/helm-charts/commit/6e4c85ad6f6cfbf6047be970f87b4f8ae3d22572))
* **deps:** Update helm release redis to v20.1.5 ([48887df](https://github.com/accelleran/helm-charts/commit/48887df7d7b34b84ef15ac8ec8d4e833611c52c4))
* **deps:** Update helm release redis to v20.1.6 ([bd7477f](https://github.com/accelleran/helm-charts/commit/bd7477f746374bbf25c156a01862bd0adf5f250c))
* **deps:** Update helm release redis to v20.1.7 ([1adabda](https://github.com/accelleran/helm-charts/commit/1adabda2df107dbe5278f368fd824f4247aa4d92))
* Fix du metrics grafana dasbhoard ([#587](https://github.com/accelleran/helm-charts/issues/587)) ([e812243](https://github.com/accelleran/helm-charts/commit/e812243d649bd7df7824c8f9463e95140fe025a7))
* Fix support for latest CU and CW versions ([cec7f94](https://github.com/accelleran/helm-charts/commit/cec7f940c4ad337d0425ff49918d74b108b83418))

## [9.0.0](https://github.com/accelleran/helm-charts/compare/drax-8.0.3...drax-9.0.0) (2024-09-23)


### ⚠ BREAKING CHANGES

* bump config api to version 2.0.0 ([#573](https://github.com/accelleran/helm-charts/issues/573))
* bump default cu version to 9 ([#561](https://github.com/accelleran/helm-charts/issues/561))
* add notification infrastructure ([#440](https://github.com/accelleran/helm-charts/issues/440))
* remove unused websocket port exposure
* **deps:** update accelleran/dash-front-back-end docker tag to v6

### Features

* Add extra resource ([#474](https://github.com/accelleran/helm-charts/issues/474)) ([2e33fec](https://github.com/accelleran/helm-charts/commit/2e33fec716543063d6771c1b2809031bacc73c2c))
* Add ingress ([#410](https://github.com/accelleran/helm-charts/issues/410)) ([fa62506](https://github.com/accelleran/helm-charts/commit/fa62506eeb2f2dda757caae487f17d61803dbc9d))
* Add notification infrastructure ([#440](https://github.com/accelleran/helm-charts/issues/440)) ([ba8669e](https://github.com/accelleran/helm-charts/commit/ba8669eab97f2428fbc014586bb9b79d4f731b7d))
* Add telemetry collector to drax ([#445](https://github.com/accelleran/helm-charts/issues/445)) ([0405584](https://github.com/accelleran/helm-charts/commit/0405584a421bbe3395c174f8473525d8823c4918))
* Add telemetry influxdb2 to drax ([#430](https://github.com/accelleran/helm-charts/issues/430)) ([6b57b82](https://github.com/accelleran/helm-charts/commit/6b57b821ddff48a348575588cc561f1cfff37906))
* Bump config api to version 2.0.0 ([#573](https://github.com/accelleran/helm-charts/issues/573)) ([0e0e55e](https://github.com/accelleran/helm-charts/commit/0e0e55ee747320ad5f41c603be4b153d974c26a2))


### Bug Fixes

* Adapt dashboard to loki-gateway changes ([#500](https://github.com/accelleran/helm-charts/issues/500)) ([19185f6](https://github.com/accelleran/helm-charts/commit/19185f6e4128e3fd9d38083eac67c161446ce0dd))
* Add missing node selectors ([#544](https://github.com/accelleran/helm-charts/issues/544)) ([066d419](https://github.com/accelleran/helm-charts/commit/066d4197045b570151eb28a2e0bedc1cf0e898bc))
* Bump default cu version to 9 ([#561](https://github.com/accelleran/helm-charts/issues/561)) ([fa7c9fe](https://github.com/accelleran/helm-charts/commit/fa7c9fe968a8fc922f72898770ad84efcfca0f4e))
* **deps:** Update accelleran/acc-generic-img docker tag to v0.8.1 ([0bcaef5](https://github.com/accelleran/helm-charts/commit/0bcaef5ff34ca091ea69f9990487809777db15ee))
* **deps:** Update accelleran/dash-front-back-end docker tag to v6 ([468767e](https://github.com/accelleran/helm-charts/commit/468767e86168b4b70b9c86fc032e21602bcde7ec))
* **deps:** Update accelleran/dash-front-back-end docker tag to v6.1.0 ([ae5a764](https://github.com/accelleran/helm-charts/commit/ae5a76439f5dc63fee51ffd08970948a987bffc6))
* **deps:** Update accelleran/dash-front-back-end docker tag to v6.1.1 ([9839705](https://github.com/accelleran/helm-charts/commit/983970596ddb2cc1cb37f79a1e4702dc7f71ae5f))
* **deps:** Update accelleran/dash-front-back-end docker tag to v6.1.2 ([223d5d1](https://github.com/accelleran/helm-charts/commit/223d5d1c5a98a7c75e23847b268c28f81e4f63cb))
* **deps:** Update accelleran/dash-front-back-end docker tag to v6.2.0 ([68f668b](https://github.com/accelleran/helm-charts/commit/68f668b87207e1ab72ed1a83eb4163b77d6e628e))
* **deps:** Update accelleran/dash-front-back-end docker tag to v6.2.1 ([8c61ec7](https://github.com/accelleran/helm-charts/commit/8c61ec7465a2560f30152b49159716a081a03f30))
* **deps:** Update accelleran/dash-front-back-end docker tag to v6.2.2 ([97d3e49](https://github.com/accelleran/helm-charts/commit/97d3e49908b2c141d6c01c7634f3bf3ffeee9b4a))
* **deps:** Update helm release cell-wrapper to v5 ([#512](https://github.com/accelleran/helm-charts/issues/512)) ([bf45d2e](https://github.com/accelleran/helm-charts/commit/bf45d2ee92db13796d1768de3c21e34bb30184c9))
* **deps:** Update helm release cell-wrapper to v5.0.1 ([c3e9450](https://github.com/accelleran/helm-charts/commit/c3e9450d4833b7797a4d7416f7efd369382a6c3c))
* **deps:** Update helm release cell-wrapper to v5.0.2 ([421cfa3](https://github.com/accelleran/helm-charts/commit/421cfa32f128a29f648ee9bd6493f180fca33551))
* **deps:** Update helm release common to v0.3.2 ([b861ce2](https://github.com/accelleran/helm-charts/commit/b861ce2b3c0369453e335281856ff08840e6aaa3))
* **deps:** Update helm release common to v0.3.3 ([bf10815](https://github.com/accelleran/helm-charts/commit/bf108152bd37539db6b2d353b4060e3f42a63e2e))
* **deps:** Update helm release common to v0.3.4 ([dd6b1c2](https://github.com/accelleran/helm-charts/commit/dd6b1c2a09a57bd5cc5a322416b2427a6332532b))
* **deps:** Update helm release common to v0.3.5 ([4cc4d8f](https://github.com/accelleran/helm-charts/commit/4cc4d8f1f503620132fede33bbd897df0d270ecb))
* **deps:** Update helm release common to v0.3.6 ([e225cc9](https://github.com/accelleran/helm-charts/commit/e225cc9428bb76a3cb6e54844f1d4058930b7902))
* **deps:** Update helm release common to v0.3.7 ([#506](https://github.com/accelleran/helm-charts/issues/506)) ([7ab297a](https://github.com/accelleran/helm-charts/commit/7ab297aeebd645f5c00399a04d4e1b159f24859e))
* **deps:** Update helm release common to v0.3.8 ([f7ca8ad](https://github.com/accelleran/helm-charts/commit/f7ca8ad8fd5dd79768da4d8b74aac0cd8eaac590))
* **deps:** Update helm release du-metrics-server to v0.3.0 ([d879588](https://github.com/accelleran/helm-charts/commit/d879588211fbf2edadc6065bb2a96036515b7f04))
* **deps:** Update helm release grafana to v8.3.6 ([0f4f257](https://github.com/accelleran/helm-charts/commit/0f4f2578f3972543904634aceaf97c3833f54605))
* **deps:** Update helm release grafana to v8.3.7 ([d142d44](https://github.com/accelleran/helm-charts/commit/d142d442ae6908ab24f59865bb56c0e6de2eb5a3))
* **deps:** Update helm release grafana to v8.3.8 ([454fae4](https://github.com/accelleran/helm-charts/commit/454fae4485d1a56265eb434150d9bdc8a2617c44))
* **deps:** Update helm release grafana to v8.4.0 ([0e5a38f](https://github.com/accelleran/helm-charts/commit/0e5a38f9a95d1e9a40c0415024002193e01004c0))
* **deps:** Update helm release grafana to v8.4.1 ([eed82cf](https://github.com/accelleran/helm-charts/commit/eed82cf7bc7ecf89bf4dbf5cf80a0e149f21b8f6))
* **deps:** Update helm release grafana to v8.4.2 ([547232d](https://github.com/accelleran/helm-charts/commit/547232d83e8654c7085bd375905f5608befc51b8))
* **deps:** Update helm release grafana to v8.4.3 ([e4c738e](https://github.com/accelleran/helm-charts/commit/e4c738e19e78e7edb1f1f5872235e498754154a5))
* **deps:** Update helm release grafana to v8.4.4 ([addc5b3](https://github.com/accelleran/helm-charts/commit/addc5b3add88a100404801d05bbf82b4f34ec2ab))
* **deps:** Update helm release grafana to v8.4.5 ([665fbda](https://github.com/accelleran/helm-charts/commit/665fbda279a16362f1ccb4cd11d9bf5b27647639))
* **deps:** Update helm release grafana to v8.4.6 ([06ae70b](https://github.com/accelleran/helm-charts/commit/06ae70b2a06031c163f2a8d11bd1466930f5426c))
* **deps:** Update helm release grafana to v8.4.7 ([aa6b30a](https://github.com/accelleran/helm-charts/commit/aa6b30a7adcf0c452d537b9260c7531dbdfb41e5))
* **deps:** Update helm release grafana to v8.4.8 ([b9a8281](https://github.com/accelleran/helm-charts/commit/b9a82818f25e1a306cacfa36b2dd4b280f8ed0d4))
* **deps:** Update helm release grafana to v8.5.0 ([1b92ef0](https://github.com/accelleran/helm-charts/commit/1b92ef03c1fd966b0bef74931600cdb8e1460051))
* **deps:** Update helm release grafana to v8.5.1 ([aac248c](https://github.com/accelleran/helm-charts/commit/aac248c9e920c18612f8837b7ba76ab850210a86))
* **deps:** Update helm release grafana-loki to v4.6.13 ([d5bda53](https://github.com/accelleran/helm-charts/commit/d5bda53a3378354f1cc59c5dc3c1f6e3f68ec4d3))
* **deps:** Update helm release grafana-loki to v4.6.14 ([6669ec1](https://github.com/accelleran/helm-charts/commit/6669ec11d9446061386aabc4fb186f912c3c136b))
* **deps:** Update helm release grafana-loki to v4.6.15 ([91f5b9a](https://github.com/accelleran/helm-charts/commit/91f5b9a5dd4f51c1074223895357e6ee70629184))
* **deps:** Update helm release grafana-loki to v4.6.16 ([67724bf](https://github.com/accelleran/helm-charts/commit/67724bf281bf50db2ac421e992a42bd2b300084e))
* **deps:** Update helm release kafka to v29.3.10 ([8d37915](https://github.com/accelleran/helm-charts/commit/8d37915d96730cc861a53ab74fc78ccdfc988f49))
* **deps:** Update helm release kafka to v29.3.11 ([c98207d](https://github.com/accelleran/helm-charts/commit/c98207dca80299efb15611e0003588ea1ce665d4))
* **deps:** Update helm release kafka to v29.3.12 ([d1b5388](https://github.com/accelleran/helm-charts/commit/d1b53888e09a077901181ac7104a137405152c7d))
* **deps:** Update helm release kafka to v29.3.13 ([dc91716](https://github.com/accelleran/helm-charts/commit/dc917160c669409cc19bd518d04641dbf40c8fed))
* **deps:** Update helm release kafka to v29.3.14 ([7a9c132](https://github.com/accelleran/helm-charts/commit/7a9c132cc70787c4186161834bb9fbf3211ec8d3))
* **deps:** Update helm release kafka to v30 ([#450](https://github.com/accelleran/helm-charts/issues/450)) ([03638b2](https://github.com/accelleran/helm-charts/commit/03638b25094daaef5f625ee80351a20ee5a354fb))
* **deps:** Update helm release kafka to v30.0.3 ([100b3bf](https://github.com/accelleran/helm-charts/commit/100b3bf52448757fe27d16b53ba0d7c10a32e490))
* **deps:** Update helm release kafka to v30.0.4 ([d7487e6](https://github.com/accelleran/helm-charts/commit/d7487e6d94f603960f8bc729cb1f5710f5897bc2))
* **deps:** Update helm release kafka to v30.0.5 ([f50a943](https://github.com/accelleran/helm-charts/commit/f50a943aea3e191d378d5f90cad82d547f1f99a5))
* **deps:** Update helm release kafka to v30.1.0 ([52bfb9f](https://github.com/accelleran/helm-charts/commit/52bfb9fb0df64d601ff5a7ef011df20b1edd43da))
* **deps:** Update helm release kafka to v30.1.1 ([2885994](https://github.com/accelleran/helm-charts/commit/2885994ae43836661f7a71fce9f70f713e6a214b))
* **deps:** Update helm release kafka to v30.1.2 ([cb5d15d](https://github.com/accelleran/helm-charts/commit/cb5d15d631a72ad545185f34e74cbb2db9b9bd81))
* **deps:** Update helm release kafka to v30.1.3 ([a235116](https://github.com/accelleran/helm-charts/commit/a2351160e2e7afff3438c009783309e2654267a2))
* **deps:** Update helm release kafka to v30.1.4 ([56b2204](https://github.com/accelleran/helm-charts/commit/56b2204bb1c1689bc0f52ef76f3ee644ac2099bb))
* **deps:** Update helm release loki-gateway to v0.1.1 ([7dcb450](https://github.com/accelleran/helm-charts/commit/7dcb450961d244d57529e0ccf1717dc31dd0d7ef))
* **deps:** Update helm release loki-gateway to v0.1.2 ([e476719](https://github.com/accelleran/helm-charts/commit/e47671967cb3764dfa81ab2194532287d6c06acd))
* **deps:** Update helm release nats to v1.2.2 ([281b093](https://github.com/accelleran/helm-charts/commit/281b093e985b367980730e3b10a335f39f02106b))
* **deps:** Update helm release nats to v1.2.3 ([d70f3d5](https://github.com/accelleran/helm-charts/commit/d70f3d5175a1b3387c51b18299b77f2b6c683ff7))
* **deps:** Update helm release nats to v1.2.4 ([da73bda](https://github.com/accelleran/helm-charts/commit/da73bda2aaf60db9918e43fb862909dcd6b36f14))
* **deps:** Update helm release prometheus to v25.24.2 ([9eb27dc](https://github.com/accelleran/helm-charts/commit/9eb27dcebd484ab6c27eb772e0d1c3ef016d0c2e))
* **deps:** Update helm release prometheus to v25.25.0 ([9f696da](https://github.com/accelleran/helm-charts/commit/9f696dadbae4a6a3f72e1d25fd8d082c8ef61ccc))
* **deps:** Update helm release prometheus to v25.26.0 ([0bafe76](https://github.com/accelleran/helm-charts/commit/0bafe7643bec6868c408f30057f26849a33158ea))
* **deps:** Update helm release prometheus to v25.27.0 ([969b8df](https://github.com/accelleran/helm-charts/commit/969b8df13ff32a45527fe783bf7c880721eee0da))
* **deps:** Update helm release promtail to v6.17.1 ([85b1ae1](https://github.com/accelleran/helm-charts/commit/85b1ae1b80bd29b9af4344ef81e97881aa3ad8b8))
* **deps:** Update helm release redis to v19.6.3 ([ef02d83](https://github.com/accelleran/helm-charts/commit/ef02d831d6acf2cfa7a8414b7d12be8ca5a39394))
* **deps:** Update helm release redis to v19.6.4 ([1c82558](https://github.com/accelleran/helm-charts/commit/1c825589abcafe3bdf8062bd82c4b229c8dfc0d0))
* **deps:** Update helm release redis to v20 ([#462](https://github.com/accelleran/helm-charts/issues/462)) ([eec9505](https://github.com/accelleran/helm-charts/commit/eec9505e219f556e02742150dc0a53727dca533e))
* **deps:** Update helm release redis to v20.0.1 ([45e247a](https://github.com/accelleran/helm-charts/commit/45e247adb645a3f7ab83dbd00c727f2628622adf))
* **deps:** Update helm release redis to v20.0.2 ([8ffc93e](https://github.com/accelleran/helm-charts/commit/8ffc93e9468a23c7d7b1429511b770f841548ea1))
* **deps:** Update helm release redis to v20.0.3 ([#471](https://github.com/accelleran/helm-charts/issues/471)) ([de81d67](https://github.com/accelleran/helm-charts/commit/de81d6772037be057ca81c87a5df62d0dd45fb26))
* **deps:** Update helm release redis to v20.0.4 ([3ab30bb](https://github.com/accelleran/helm-charts/commit/3ab30bb96f577c54a97d1951a35033c0278261de))
* **deps:** Update helm release redis to v20.0.5 ([5fe2e15](https://github.com/accelleran/helm-charts/commit/5fe2e15121eafd539ad041f9a345173b7e9bc43c))
* **deps:** Update helm release redis to v20.1.0 ([3db101b](https://github.com/accelleran/helm-charts/commit/3db101be6f0e92d35a932ca44f7c8a189b5b27cb))
* **deps:** Update helm release redis to v20.1.1 ([9835b6f](https://github.com/accelleran/helm-charts/commit/9835b6f5b2192ed61805a236fac99f37c74a7a3b))
* **deps:** Update helm release redis to v20.1.2 ([5c40275](https://github.com/accelleran/helm-charts/commit/5c4027536026dbcf953a8df36cd5cff0011bbc23))
* **deps:** Update helm release redis to v20.1.3 ([1c215ce](https://github.com/accelleran/helm-charts/commit/1c215ce1892ddd38d28dfc51f7452fab80c676f8))
* **deps:** Update helm release redis to v20.1.4 ([1adf4af](https://github.com/accelleran/helm-charts/commit/1adf4afa8aa7889ae67240f409cb7df172241886))
* **deps:** Update helm release telemetry-collector to v1.1.0 ([518cd8c](https://github.com/accelleran/helm-charts/commit/518cd8c49aaaee0ccc730b184bdf75a58d087fee))
* **deps:** Update helm release telemetry-collector to v1.1.1 ([afec121](https://github.com/accelleran/helm-charts/commit/afec12172c40fe2d20f0fb77a05be83f559b266e))
* **deps:** Update helm release vector to v0.35.0 ([89eca7f](https://github.com/accelleran/helm-charts/commit/89eca7fe4f709633a16cac599b68b23f653a6554))
* **deps:** Update helm release vector to v0.35.1 ([f11d2c9](https://github.com/accelleran/helm-charts/commit/f11d2c93ded70fd307de7944abec920106bd7271))
* **deps:** Update helm release vector to v0.35.3 ([0431a11](https://github.com/accelleran/helm-charts/commit/0431a11c3131a1a8ec54defb9325c50b3d89e7db))
* **deps:** Update helm release vector to v0.36.0 ([f9d9e7f](https://github.com/accelleran/helm-charts/commit/f9d9e7f40ef7438ee8c34465e9117674b3977004))
* **deps:** Update helm release vector to v0.36.1 ([cf7026e](https://github.com/accelleran/helm-charts/commit/cf7026e987587d66177002f0fae126bbfedf37f9))
* Fix indentation in telemetry collector config ([#560](https://github.com/accelleran/helm-charts/issues/560)) ([7b311db](https://github.com/accelleran/helm-charts/commit/7b311db2c5524763628139240928e06f4b965b5a))
* Fix loki queries not retrieving data older than 2 hours ([#559](https://github.com/accelleran/helm-charts/issues/559)) ([3c73af7](https://github.com/accelleran/helm-charts/commit/3c73af7d6d54837bfadaadd857f4f7cf311b9e10))
* Keep du influxdb auth secret on uninstall ([#549](https://github.com/accelleran/helm-charts/issues/549)) ([c32551e](https://github.com/accelleran/helm-charts/commit/c32551eb2dff4a73591db55a27696916ccebed57))
* Reduce log lines in grafana dashboard ([#552](https://github.com/accelleran/helm-charts/issues/552)) ([51e5b0a](https://github.com/accelleran/helm-charts/commit/51e5b0aaf493e299872947d32072f8a698ab8e1d))
* Remove unused websocket port exposure ([468767e](https://github.com/accelleran/helm-charts/commit/468767e86168b4b70b9c86fc032e21602bcde7ec))
* Switch to grafana promtail ([#554](https://github.com/accelleran/helm-charts/issues/554)) ([bce2d28](https://github.com/accelleran/helm-charts/commit/bce2d28d0240811a18cf89147a04ce62c5134c44))

## [8.0.3](https://github.com/accelleran/helm-charts/compare/drax-8.0.2...drax-8.0.3) (2024-07-18)


### Bug Fixes

* **deps:** Update accelleran/dash-front-back-end docker tag to v5.4.1 ([e59b6be](https://github.com/accelleran/helm-charts/commit/e59b6be6ee960136328d2c1554ec4c2541b0d4a0))
* **deps:** Update helm release grafana to v8.3.5 ([fc7b5dd](https://github.com/accelleran/helm-charts/commit/fc7b5dd1d6a4c55e035b4c598ea38da6c97da0ce))
* **deps:** Update helm release kafka to v29.3.9 ([700c268](https://github.com/accelleran/helm-charts/commit/700c26854077020665579ff40082c68601df5529))
* **deps:** Update helm release prometheus to v25.24.1 ([92df78b](https://github.com/accelleran/helm-charts/commit/92df78b5f7eb02992e346e91c05485a67d090a52))
* **deps:** Update helm release redis to v19.6.2 ([af43807](https://github.com/accelleran/helm-charts/commit/af438077cb1a12297103ab3f96eba9dd868558e7))

## [8.0.2](https://github.com/accelleran/helm-charts/compare/drax-8.0.1...drax-8.0.2) (2024-07-16)


### Bug Fixes

* **deps:** Update accelleran/dash-front-back-end docker tag to v5.4.0 ([ebecd82](https://github.com/accelleran/helm-charts/commit/ebecd8258ae88e24af03a0644803d0866f647db6))
* **deps:** Update accelleran/service-orchestrator docker tag to v1.2.0 ([53d2271](https://github.com/accelleran/helm-charts/commit/53d2271aed6f5f2ed8ed2df686519b00bce7e7c1))
* **deps:** Update helm release grafana to v8.1.1 ([2130d00](https://github.com/accelleran/helm-charts/commit/2130d000cf45fdd519e6bdc9af32545eaf77f7aa))
* **deps:** Update helm release grafana to v8.2.0 ([c8be9c0](https://github.com/accelleran/helm-charts/commit/c8be9c02a5afedf957bd10665cb702ca818a0cc4))
* **deps:** Update helm release grafana to v8.2.1 ([fb28fc3](https://github.com/accelleran/helm-charts/commit/fb28fc3981b36c7f7420000dedcbebd328a38925))
* **deps:** Update helm release grafana to v8.2.2 ([e02e37b](https://github.com/accelleran/helm-charts/commit/e02e37b87a8348f1aa0d28514bff8763c1b37f0a))
* **deps:** Update helm release grafana to v8.3.0 ([6ffc2e6](https://github.com/accelleran/helm-charts/commit/6ffc2e6f1a63cf9c8dee2915de1a7aec97e9c4c2))
* **deps:** Update helm release grafana to v8.3.1 ([ededb9d](https://github.com/accelleran/helm-charts/commit/ededb9ddf14d3d3884776de60c691bdff64a13ca))
* **deps:** Update helm release grafana to v8.3.2 ([79a3e4b](https://github.com/accelleran/helm-charts/commit/79a3e4b713d26eb835ed014b4a1735c8cb76aa07))
* **deps:** Update helm release grafana to v8.3.3 ([f1579ef](https://github.com/accelleran/helm-charts/commit/f1579ef9eed9eb5bb2eef7d63f09d58c7acb78cd))
* **deps:** Update helm release grafana to v8.3.4 ([8b73a33](https://github.com/accelleran/helm-charts/commit/8b73a33dddac14f0c18172ba2bf95a05349768a6))
* **deps:** Update helm release kafka to v29.3.3 ([cc11f0b](https://github.com/accelleran/helm-charts/commit/cc11f0bbdd043dcc6a1dbf345a8c08032ec1d191))
* **deps:** Update helm release kafka to v29.3.4 ([c3187d8](https://github.com/accelleran/helm-charts/commit/c3187d8843d62ce2b9f2fe66711613f4f6bbab9e))
* **deps:** Update helm release kafka to v29.3.5 ([3e404cf](https://github.com/accelleran/helm-charts/commit/3e404cfafa1e1e487a745bb861f2d328776354bf))
* **deps:** Update helm release kafka to v29.3.6 ([7912e5e](https://github.com/accelleran/helm-charts/commit/7912e5ee61c483c6c02abd8ab770a1367b2c3d99))
* **deps:** Update helm release kafka to v29.3.7 ([7502328](https://github.com/accelleran/helm-charts/commit/75023288351467ac34f7682a2e1c8c3e66f7e830))
* **deps:** Update helm release kafka to v29.3.8 ([97f3b82](https://github.com/accelleran/helm-charts/commit/97f3b826e5b36bce222484455fb5264d2bfa953b))
* **deps:** Update helm release kminion to v0.14.0 ([4e6083c](https://github.com/accelleran/helm-charts/commit/4e6083c4aefd1405e64abd7c87f64ddf1ed4e22c))
* **deps:** Update helm release nats to v1.2.0 ([1375b4c](https://github.com/accelleran/helm-charts/commit/1375b4c234a2b744a8c72c1e0bc09a0ba59dbf76))
* **deps:** Update helm release nats to v1.2.1 ([6f4c730](https://github.com/accelleran/helm-charts/commit/6f4c73062a4d6f48911256675e78d06061de1485))
* **deps:** Update helm release prometheus to v25.21.1 ([ad4a499](https://github.com/accelleran/helm-charts/commit/ad4a499097abaee7e4809ea7843f31a2617d8ba9))
* **deps:** Update helm release prometheus to v25.22.0 ([fd20da7](https://github.com/accelleran/helm-charts/commit/fd20da7d30dc35f5c09ddca7715636c589be51fc))
* **deps:** Update helm release prometheus to v25.22.1 ([8df83d1](https://github.com/accelleran/helm-charts/commit/8df83d12434eca2ac761faae7022aba875cef509))
* **deps:** Update helm release prometheus to v25.23.0 ([7f81f9c](https://github.com/accelleran/helm-charts/commit/7f81f9cb2272da2f565445d078515094bc658beb))
* **deps:** Update helm release prometheus to v25.24.0 ([6026956](https://github.com/accelleran/helm-charts/commit/60269562afde7355d962ee35bc98aa2866499034))
* **deps:** Update helm release redis to v19.5.4 ([2aa529a](https://github.com/accelleran/helm-charts/commit/2aa529a6746a448f0413f18718fdb94ee5d39ae1))
* **deps:** Update helm release redis to v19.5.5 ([6fe6a40](https://github.com/accelleran/helm-charts/commit/6fe6a40d9d2dcd1423a6270babc37e07cbe795fb))
* **deps:** Update helm release redis to v19.6.0 ([3ce4dcd](https://github.com/accelleran/helm-charts/commit/3ce4dcd37b0e7c470d8926abdf010d4a815b85a1))
* **deps:** Update helm release redis to v19.6.1 ([18805cb](https://github.com/accelleran/helm-charts/commit/18805cb413107f939ea9c9ee6fcb4f694d23e0b3))
* **deps:** Update helm release vector to v0.34.0 ([035e323](https://github.com/accelleran/helm-charts/commit/035e323e16e89b50085511368e942531b0f9b571))
* Enable cu deployment ([#393](https://github.com/accelleran/helm-charts/issues/393)) ([a64ab83](https://github.com/accelleran/helm-charts/commit/a64ab836a2e5ba67755d08ad7a2784783e35bb70))
* Fix nodecomponent parsing ([#394](https://github.com/accelleran/helm-charts/issues/394)) ([fc70e1e](https://github.com/accelleran/helm-charts/commit/fc70e1e8d81e00ec6106bff0ce456f6620f9aee1))

## [8.0.1](https://github.com/accelleran/helm-charts/compare/drax-8.0.0...drax-8.0.1) (2024-06-17)


### Bug Fixes

* Bump nkafka version for cu-5.0.0 ([#320](https://github.com/accelleran/helm-charts/issues/320)) ([9b28717](https://github.com/accelleran/helm-charts/commit/9b28717607c5a8e87ea5783a4ccffff8e69a2478))
* **deps:** Update accelleran/dash-front-back-end docker tag to v5.3.2 ([f52d306](https://github.com/accelleran/helm-charts/commit/f52d306197886c2931e82b904696a25ccd40d069))
* **deps:** Update accelleran/network-state-monitor docker tag to v1.2.1 ([#311](https://github.com/accelleran/helm-charts/issues/311)) ([587e0ab](https://github.com/accelleran/helm-charts/commit/587e0abe1679a374318d541395fd987bc00a8337))
* **deps:** Update accelleran/service-monitor docker tag to v1.1.1 ([7f4d80b](https://github.com/accelleran/helm-charts/commit/7f4d80b9fe44a177bb662cc6e379f15473b06371))
* **deps:** Update helm release cell-wrapper to v4.0.1 ([7b69197](https://github.com/accelleran/helm-charts/commit/7b6919751a1e619f5dbf738b6237b28b1977351b))
* **deps:** Update helm release cell-wrapper to v4.0.2 ([5e1b722](https://github.com/accelleran/helm-charts/commit/5e1b722bb1e1cbbcb28d6305c9fccc1a10d71345))
* **deps:** Update helm release common to v0.3.1 ([f0121bd](https://github.com/accelleran/helm-charts/commit/f0121bd9089ea7a3c6b527438ebad672806d861d))
* **deps:** Update helm release grafana to v8.0.1 ([1c4a0e6](https://github.com/accelleran/helm-charts/commit/1c4a0e65458017f205159cfaee75c2e1d39b1b09))
* **deps:** Update helm release grafana to v8.0.2 ([04b4cbd](https://github.com/accelleran/helm-charts/commit/04b4cbd94997e38cbb553bda816e7546c9ba633e))
* **deps:** Update helm release kafka to v29.3.1 ([7a6d4ac](https://github.com/accelleran/helm-charts/commit/7a6d4acb335f787555daf1a7d946c35364d78670))
* **deps:** Update helm release kafka to v29.3.2 ([#324](https://github.com/accelleran/helm-charts/issues/324)) ([ffb1a17](https://github.com/accelleran/helm-charts/commit/ffb1a173247ef7dc3f9146760030acdc11d1748e))
* **deps:** Update helm release redis to v19.5.3 ([babb22e](https://github.com/accelleran/helm-charts/commit/babb22e555da1e7bc93141bc65c135c21be8a17e))
* Expose nats, influx, loki to certain nodeports ([#306](https://github.com/accelleran/helm-charts/issues/306)) ([bc3ab96](https://github.com/accelleran/helm-charts/commit/bc3ab9670ef2f70b611273b9049db767323d579f))

## [8.0.0](https://github.com/accelleran/helm-charts/compare/drax-7.1.0...drax-8.0.0) (2024-06-07)


### ⚠ BREAKING CHANGES

* **deps:** update drax to common chart 0.3.0
* **deps:** update helm release cell-wrapper to v4
* disable nats and redis by default ([#278](https://github.com/accelleran/helm-charts/issues/278))
* rework loki dashboard to single log panel ([#276](https://github.com/accelleran/helm-charts/issues/276))
* use different topics for DU metrics ([#271](https://github.com/accelleran/helm-charts/issues/271))
* **deps:** update helm release redis to v19 ([#173](https://github.com/accelleran/helm-charts/issues/173))
* **deps:** update helm release kafka to v29 ([#254](https://github.com/accelleran/helm-charts/issues/254))

### Features

* Add du metrics dashboard ([#197](https://github.com/accelleran/helm-charts/issues/197)) ([72ebd74](https://github.com/accelleran/helm-charts/commit/72ebd742518bc6a7da8ad2ec963eda8818e1c5f2))
* Add metrics to 5g DU metrics dashboard ([#219](https://github.com/accelleran/helm-charts/issues/219)) ([bb77bfc](https://github.com/accelleran/helm-charts/commit/bb77bfcda2376967b6e8e535046273df978c3243))
* Allow external logs in loki ([#214](https://github.com/accelleran/helm-charts/issues/214)) ([95c40a3](https://github.com/accelleran/helm-charts/commit/95c40a3c36dc27160123cfa8f85e0c211ed300bc))
* Enable kafka publishing for du-metrics-server ([#231](https://github.com/accelleran/helm-charts/issues/231)) ([9ab1ccf](https://github.com/accelleran/helm-charts/commit/9ab1ccfeaff0903d701d4ed8754f410e8982f701))
* Expose all CU beacons and UeInfo messages ([#267](https://github.com/accelleran/helm-charts/issues/267)) ([ea39aa9](https://github.com/accelleran/helm-charts/commit/ea39aa98b4c93196ced60a95b06b6627bfcbe219))
* Increase max entries limit per query to 10000 in loki ([#273](https://github.com/accelleran/helm-charts/issues/273)) ([33c95a8](https://github.com/accelleran/helm-charts/commit/33c95a89c87f4dbb9019a0768556cb2b0ec7e5e2))
* Rework loki dashboard to single log panel ([#276](https://github.com/accelleran/helm-charts/issues/276)) ([169fd30](https://github.com/accelleran/helm-charts/commit/169fd30ccb86c75d924783cfa21559960bc112d4))


### Bug Fixes

* **deps:** Update accelleran/config-api docker tag to v1.3.0 ([2e2ec63](https://github.com/accelleran/helm-charts/commit/2e2ec6357831e0d5499930559cc8eb4acec157c5))
* **deps:** Update accelleran/config-api docker tag to v1.3.1 ([b367efa](https://github.com/accelleran/helm-charts/commit/b367efa88105b8a9f7e1a1a8421c9f0b40f88d76))
* **deps:** Update accelleran/dash-front-back-end docker tag to v5.2.0 ([357e044](https://github.com/accelleran/helm-charts/commit/357e044167682ec94978d9b550cd5f1fdbaa5a47))
* **deps:** Update accelleran/dash-front-back-end docker tag to v5.2.1 ([be3a250](https://github.com/accelleran/helm-charts/commit/be3a2509d4ca9d99ac056404c977ce09d4890ca6))
* **deps:** Update accelleran/dash-front-back-end docker tag to v5.2.2 ([5bc25b2](https://github.com/accelleran/helm-charts/commit/5bc25b271ee336595938ad877ca5371ff216fca9))
* **deps:** Update accelleran/dash-front-back-end docker tag to v5.3.0 ([9ba6232](https://github.com/accelleran/helm-charts/commit/9ba62327f852e32e811d278cec3e4b829d348625))
* **deps:** Update accelleran/network-state-monitor docker tag to v1.2.0 ([fe16a82](https://github.com/accelleran/helm-charts/commit/fe16a8219be8e5221d2ccf5248b59758dea1e7a5))
* **deps:** Update drax to common chart 0.3.0 ([43cb011](https://github.com/accelleran/helm-charts/commit/43cb011ae62ef0849dda405989af61b8c93531b5))
* **deps:** Update e2 to 5.2.15 ([#241](https://github.com/accelleran/helm-charts/issues/241)) ([8640aaf](https://github.com/accelleran/helm-charts/commit/8640aafdd7d6b1ea0072f1dacc5d4f55851583d1))
* **deps:** Update helm release cell-wrapper to v4 ([43cb011](https://github.com/accelleran/helm-charts/commit/43cb011ae62ef0849dda405989af61b8c93531b5))
* **deps:** Update helm release common to v0.2.3 ([2720172](https://github.com/accelleran/helm-charts/commit/2720172fa39bfc8c82ee656029c09200f21647aa))
* **deps:** Update helm release du-metrics-server to v0.1.1 ([8f46e06](https://github.com/accelleran/helm-charts/commit/8f46e064b5b01743e63a6167908e9faca583dff4))
* **deps:** Update helm release du-metrics-server to v0.1.2 ([40b11b9](https://github.com/accelleran/helm-charts/commit/40b11b9b26d5851367ec507986c03949997e79f4))
* **deps:** Update helm release du-metrics-server to v0.2.0 ([e4b73e2](https://github.com/accelleran/helm-charts/commit/e4b73e21aa5620e15eacf6d09081f827d845dc97))
* **deps:** Update helm release du-metrics-server to v0.2.1 ([8e88672](https://github.com/accelleran/helm-charts/commit/8e88672ef604cdc9564df782dada12f52c12e3ca))
* **deps:** Update helm release grafana to v7.3.10 ([d510c7e](https://github.com/accelleran/helm-charts/commit/d510c7e55a5a629ac5e8ff934f0073fff849980c))
* **deps:** Update helm release grafana to v7.3.11 ([c826db1](https://github.com/accelleran/helm-charts/commit/c826db1917330f3a4562cb6206363cd4da33ecb9))
* **deps:** Update helm release grafana to v7.3.12 ([75e8d67](https://github.com/accelleran/helm-charts/commit/75e8d67dec896e2c25c83771d088d4a49b014057))
* **deps:** Update helm release grafana to v7.3.8 ([34a39ca](https://github.com/accelleran/helm-charts/commit/34a39ca54d44d97a34a73d61bcf7367cc09c3ff1))
* **deps:** Update helm release grafana to v7.3.9 ([7dc3495](https://github.com/accelleran/helm-charts/commit/7dc349511637e62bf061b051e18a612ff50154c6))
* **deps:** Update helm release grafana to v8 ([#269](https://github.com/accelleran/helm-charts/issues/269)) ([ec40f3b](https://github.com/accelleran/helm-charts/commit/ec40f3bcd098ce6db236cceab362d24e86369ec4))
* **deps:** Update helm release kafka to v29 ([#254](https://github.com/accelleran/helm-charts/issues/254)) ([9c30985](https://github.com/accelleran/helm-charts/commit/9c3098558c1e55ef58eb8d5074feedb275f27c94))
* **deps:** Update helm release kafka to v29.2.2 ([7d2f2ba](https://github.com/accelleran/helm-charts/commit/7d2f2bad6e3594788691839ac6fb122c69bf466d))
* **deps:** Update helm release kafka to v29.2.3 ([898455e](https://github.com/accelleran/helm-charts/commit/898455edd850d9b46836bc71f9ebf58fb2879999))
* **deps:** Update helm release kafka to v29.2.4 ([f216ac3](https://github.com/accelleran/helm-charts/commit/f216ac3365814ec9bd83f2186ca2321474ed763b))
* **deps:** Update helm release kminion to v0.12.8 ([acb92a3](https://github.com/accelleran/helm-charts/commit/acb92a3baebbd0202eac79d1174c0fdd4caa09d7))
* **deps:** Update helm release kminion to v0.13.0 ([caf3b27](https://github.com/accelleran/helm-charts/commit/caf3b27c83a2db963fb73a19b2483a081a02ea05))
* **deps:** Update helm release loki-stack to v2.10.2 ([#263](https://github.com/accelleran/helm-charts/issues/263)) ([296f2b1](https://github.com/accelleran/helm-charts/commit/296f2b11369f01cdcc029b35a5159357cdf2cfd2))
* **deps:** Update helm release nats to v1.1.11 ([ca65524](https://github.com/accelleran/helm-charts/commit/ca6552466091a7b8bc997f3added20ab02dea9ea))
* **deps:** Update helm release nats to v1.1.12 ([da5f102](https://github.com/accelleran/helm-charts/commit/da5f1027547c83f5c68f56ce524218db3f2b35c0))
* **deps:** Update helm release prometheus to v25.18.0 ([7bf4254](https://github.com/accelleran/helm-charts/commit/7bf42542f249c1fbb0c3b65262064797ad64b3bd))
* **deps:** Update helm release prometheus to v25.19.0 ([9036981](https://github.com/accelleran/helm-charts/commit/90369812e7d2f9466393c78646e1c27fdaa6bc26))
* **deps:** Update helm release prometheus to v25.19.1 ([c1a7a58](https://github.com/accelleran/helm-charts/commit/c1a7a58b5a431a508be64594dd67e6308ff5e57b))
* **deps:** Update helm release prometheus to v25.20.0 ([9375ef1](https://github.com/accelleran/helm-charts/commit/9375ef17f1ef07029abd4c9adbde397d51ab8142))
* **deps:** Update helm release prometheus to v25.20.1 ([#205](https://github.com/accelleran/helm-charts/issues/205)) ([55f0d4a](https://github.com/accelleran/helm-charts/commit/55f0d4a51eba56aca3885bfebf7d8f0ad4f53046))
* **deps:** Update helm release prometheus to v25.21.0 ([0911fad](https://github.com/accelleran/helm-charts/commit/0911fad7b8efe6d755dbff0842fdaa1d3555fdd0))
* **deps:** Update helm release redis to v19 ([#173](https://github.com/accelleran/helm-charts/issues/173)) ([979ae1e](https://github.com/accelleran/helm-charts/commit/979ae1e51d665263c457c7a9ecc30e64ac001843))
* **deps:** Update helm release redis to v19.5.2 ([f649761](https://github.com/accelleran/helm-charts/commit/f6497616674d6f113d3bab8c7d10bf19e47db602))
* **deps:** Update helm release vector to v0.32.0 ([b0319ee](https://github.com/accelleran/helm-charts/commit/b0319ee112d3392ae9c15bf5cc6de4611df5487d))
* **deps:** Update helm release vector to v0.32.1 ([c31e6be](https://github.com/accelleran/helm-charts/commit/c31e6be43d0831bf14c4f2d7d5c772a5006d0439))
* **deps:** Update helm release vector to v0.33.0 ([b0b1094](https://github.com/accelleran/helm-charts/commit/b0b10940b8cd50294ff2372bbac2804bd38f9e72))
* **deps:** Update helm release xapp-hello-world to v3 ([#288](https://github.com/accelleran/helm-charts/issues/288)) ([796cabc](https://github.com/accelleran/helm-charts/commit/796cabc20927129e9a965b36a4c4a5094ec18870))
* Disable nats and redis by default ([#278](https://github.com/accelleran/helm-charts/issues/278)) ([c472498](https://github.com/accelleran/helm-charts/commit/c472498b31777491f8e697d2902a732f8551601a))
* Fix Chart.lock files of drax subcharts ([#298](https://github.com/accelleran/helm-charts/issues/298)) ([0c01a37](https://github.com/accelleran/helm-charts/commit/0c01a37db0b14feccdcef77e0cb370c4962ce12f))
* Fix ue label transformations in DU metrics dashboard ([#260](https://github.com/accelleran/helm-charts/issues/260)) ([2654fda](https://github.com/accelleran/helm-charts/commit/2654fda5e4ce1da15c82ffe2f3727f88d4027986))
* Increase kafka resource preset ([#275](https://github.com/accelleran/helm-charts/issues/275)) ([f30c33f](https://github.com/accelleran/helm-charts/commit/f30c33fd0c75600c314ba272dfe26b018d51684e))
* Use different topics for DU metrics ([#271](https://github.com/accelleran/helm-charts/issues/271)) ([039d109](https://github.com/accelleran/helm-charts/commit/039d109c0a002bf8d71021d5ad6f5adfca8e5f5d))

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
