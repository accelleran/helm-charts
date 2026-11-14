# Changelog

## [0.2.1](https://github.com/accelleran/helm-charts/compare/firecell-core-0.2.0...firecell-core-0.2.1) (2026-11-14)


### Features

* **firecell-core:** Add the PCF SliceDnnPolicyDecision tables ([4621191](https://github.com/accelleran/helm-charts/commit/46211916983897a927b88801be74e83a6d0835c6))


### Bug Fixes

* **deps:** Update dependency mysql to v8.4 ([a9bfc1e](https://github.com/accelleran/helm-charts/commit/a9bfc1eedc464a87b463e6d93d4a5982c5fe078c))
* **deps:** Update docker.io/library/busybox docker tag to v1.38.0 ([#1881](https://github.com/accelleran/helm-charts/issues/1881)) ([a75b0ef](https://github.com/accelleran/helm-charts/commit/a75b0ef609eb327a019854717b70e04c67387f7a))
* **firecell-core:** The AMF reads its CM intent from the ConfigMap, like every other NF ([7fe09b0](https://github.com/accelleran/helm-charts/commit/7fe09b072a3555d39e21a6c36a4eb5c841ec3778))

## [0.2.0](https://github.com/accelleran/helm-charts/compare/firecell-core-0.1.0...firecell-core-0.2.0) (2026-11-05)


### ⚠ BREAKING CHANGES

* **firecell-core:** default extDn off
* **firecell-core:** default AMF/SMF enableUdsf to yes
* **firecell-core:** default udsf on and fcAcsAgent off
* **firecell-core:** remove Open5GS UPF (cn5g-o5gs / upf.type=o5gs)

### Features

* **firecell-core,firecell-cu,firecell-du:** Default to the published CI images ([#1801](https://github.com/accelleran/helm-charts/issues/1801)) ([50ae587](https://github.com/accelleran/helm-charts/commit/50ae5871ee06450fd24f2b725d640c73191fe422))
* **firecell-core:** Add Kamailio IMS + Cx-on-UDR engine path ([1f1cb43](https://github.com/accelleran/helm-charts/commit/1f1cb43dc198545133ebc8a34ea1e21b5911dfd6))
* **firecell-core:** Attach ext-dn to the UPF N6 bridge for the NMS UE ping ([#1815](https://github.com/accelleran/helm-charts/issues/1815)) ([1e9bdeb](https://github.com/accelleran/helm-charts/commit/1e9bdebacc8c3223343b7122c7e3949019577d16))
* **firecell-core:** Default AMF/SMF enableUdsf to yes ([976608d](https://github.com/accelleran/helm-charts/commit/976608daf0f270cfd60073dfecbebf8c50dc3417))
* **firecell-core:** Default extDn off ([a7d44f4](https://github.com/accelleran/helm-charts/commit/a7d44f497f2fd4a6f56872ea0d1beb6507fc24a1))
* **firecell-core:** Default to published 6.0.0 Docker Hub images ([62a9abe](https://github.com/accelleran/helm-charts/commit/62a9abe4af02bd9fb64520a7892851e236131ac7))
* **firecell-core:** Default udsf on and fcAcsAgent off ([619c891](https://github.com/accelleran/helm-charts/commit/619c891da14b5bc10b2701bc8a1f84699be4ece3))
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


### Code Refactoring

* **firecell-core:** Remove Open5GS UPF (cn5g-o5gs / upf.type=o5gs) ([236ce2a](https://github.com/accelleran/helm-charts/commit/236ce2a314eab787fadd0d6ce8b6bd3ce55d92b0))
