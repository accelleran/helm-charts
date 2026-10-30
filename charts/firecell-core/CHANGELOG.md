# Changelog

## [0.2.0](https://github.com/accelleran/helm-charts/compare/firecell-core-0.1.0...firecell-core-0.2.0) (2026-10-30)


### Features

* **firecell-core,firecell-cu,firecell-du:** Default to the published CI images ([#1801](https://github.com/accelleran/helm-charts/issues/1801)) ([50ae587](https://github.com/accelleran/helm-charts/commit/50ae5871ee06450fd24f2b725d640c73191fe422))
* **firecell-core:** Add Kamailio IMS + Cx-on-UDR engine path ([1f1cb43](https://github.com/accelleran/helm-charts/commit/1f1cb43dc198545133ebc8a34ea1e21b5911dfd6))
* **firecell-core:** Make Kamailio IMS the default engine ([3548615](https://github.com/accelleran/helm-charts/commit/35486155505fbd4c85975a24cf1c8f8aced07282))
* **firecell-core:** Multus N3/N6 for non-hostNetwork OAI UPF ([a11259e](https://github.com/accelleran/helm-charts/commit/a11259ef66cdadc6fa52649ce48f48871e60e5b0))
* **firecell-core:** Set the UPF FCAPS PM push period, default 5 s ([9158d7d](https://github.com/accelleran/helm-charts/commit/9158d7d8aebe08b19d4e177e79231ec686f7ef81))
* **firecell-core:** Support Option 1 bridge/generic and Option 2 host-device/native UPF XDP modes ([1a0d890](https://github.com/accelleran/helm-charts/commit/1a0d890e93d5d23fca2639f698c90c923a83a838))
* **firecell-core:** Upf.multus.rpsCpus to spread generic-XDP softirq ([9146d16](https://github.com/accelleran/helm-charts/commit/9146d1653b88faa046a37863e89165e7c445afea))


### Bug Fixes

* **deps:** Update mysql docker tag ([#1797](https://github.com/accelleran/helm-charts/issues/1797)) ([aa13b4f](https://github.com/accelleran/helm-charts/commit/aa13b4f366f08938e78a7bfc05cda199fc29f79c))
* **firecell-core:** Gate UPF XDP datapath on Multus separately from hostNetwork ([83f0d2e](https://github.com/accelleran/helm-charts/commit/83f0d2e68f7d1266b95ba3cd9dc7d6b38a5c9e57))
* **firecell-core:** Refresh SMF KI-1 N3 F-TEID binding on UPF pod IP change ([1dd1526](https://github.com/accelleran/helm-charts/commit/1dd152689644e72ce49270d14dbdbf3e400ff1a6))
* **firecell-core:** Serve the NF healthz endpoint with busybox httpd ([de03bb5](https://github.com/accelleran/helm-charts/commit/de03bb5f3b2aa0dccb430deb02820114af2c89af))
* **firecell-core:** Upf.multus.rpsCpus quoted, only where RPS acts, checked writes ([c8aea09](https://github.com/accelleran/helm-charts/commit/c8aea093460fa529e924e5f1e5319d3a84fd5472))


### Miscellaneous Chores

* Release firecell-core 0.2.0-rc.1 ([20b2f58](https://github.com/accelleran/helm-charts/commit/20b2f58981ab2ac63d23032aac59e1e290a8f3ed))
