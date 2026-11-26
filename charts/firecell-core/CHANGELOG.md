# Changelog

## [0.3.0](https://github.com/accelleran/helm-charts/compare/firecell-core-0.2.0...firecell-core-0.3.0) (2026-11-26)


### ⚠ BREAKING CHANGES

* **firecell-core:** images from ghcr.io/accelleran; pull secret needs GHCR credentials.

### Features

* **firecell-core,firecell-cu,firecell-du,firecell-nms:** Write a release-info ConfigMap ([10e3484](https://github.com/accelleran/helm-charts/commit/10e3484a062e8e84fd7b2ea61b590d10f2780518))
* **firecell-core:** Add 5MBS: coreConfig.smf.mbs and the UDR MbsSubscriptionData table ([11ea3d1](https://github.com/accelleran/helm-charts/commit/11ea3d18813351ba088b40aa2cc0eee3d7fd8d28))
* **firecell-core:** Add AMF and SMF switch seeds: CAG/SNPN, RedCap, UE-AMBR, T3512, PDU types ([203d0b4](https://github.com/accelleran/helm-charts/commit/203d0b48afdca38082755b9451cf54110b80bd35))
* **firecell-core:** Add AMF callback host, RRC INACTIVE, SMF N4 restore and threads, UPF keys ([bed3d5b](https://github.com/accelleran/helm-charts/commit/bed3d5b737ef73b732331efbbda5b39aefd1df61))
* **firecell-core:** Add coreConfig.smf.handover.dataForwarding / indirectForwardingTimerMs ([aa78eab](https://github.com/accelleran/helm-charts/commit/aa78eab594b9cd6afa43493db712eb7fccc31797))
* **firecell-core:** Add IWF review items: Rx realm, state volume, NetworkPolicy, P-CSCF down ([222dee0](https://github.com/accelleran/helm-charts/commit/222dee06ff4cfb491712137835720448a4c355f8))
* **firecell-core:** Add SBI TLS and OAuth2, off by default ([f75b63f](https://github.com/accelleran/helm-charts/commit/f75b63fd4510a207fe7b458cf32ad6a2fd061fa3))
* **firecell-core:** Add the AM policy and N5 switches and the NGAP call trace profile ([2d4a4e9](https://github.com/accelleran/helm-charts/commit/2d4a4e920f5ea96c695fde8e0b28abb6577dd75b))
* **firecell-core:** Add the EIR block (off by default) and the AMF eir.* keys ([7170ce3](https://github.com/accelleran/helm-charts/commit/7170ce3ef1657e7a3ec0e86483c3f60a9fd1c9d6))
* **firecell-core:** Add the End Marker switch and the UPF Ethernet DL flooding keys ([a377a27](https://github.com/accelleran/helm-charts/commit/a377a2795e520072fed86dfaaf18690254536783))
* **firecell-core:** Add the IMS DB password Secret, Cx gateway provisioning and CSCF wiring ([6f80073](https://github.com/accelleran/helm-charts/commit/6f800735f0125c902c469fe35a88e60bebe5a868))
* **firecell-core:** Add the IMS Rx-N5 IWF Deployment and Service, off by default ([e55fff4](https://github.com/accelleran/helm-charts/commit/e55fff4c8719ece33e3ce0f631c7299723047c04))
* **firecell-core:** Add the NEF block, off by default ([56f1bf3](https://github.com/accelleran/helm-charts/commit/56f1bf3f29843bac5ff20d0b731c4eb5cd110e0e))
* **firecell-core:** Add the NEF/EIR MnS port, handover delay, PCF area restriction and trace ([089d788](https://github.com/accelleran/helm-charts/commit/089d788814658b60fa373a25a749b286bd8a68f0))
* **firecell-core:** Add the NSSF block, EIR authProfile auto, NMS client certificate ([f64047e](https://github.com/accelleran/helm-charts/commit/f64047e072c8f6557d6b9f3eafd9a0e015d0e0f6))
* **firecell-core:** Add the PCF SliceDnnPolicyDecision tables ([4621191](https://github.com/accelleran/helm-charts/commit/46211916983897a927b88801be74e83a6d0835c6))
* **firecell-core:** Add the rc-02 GHCR example overlay; default the AMF UE-AMBR to 10 Gbps ([f79aeef](https://github.com/accelleran/helm-charts/commit/f79aeeff5d948aa774ed54cef01ee462048abe5e))
* **firecell-core:** Add UDM SUCI profiles, SMF Location root, NEA2, framed routing, paging fanout ([d73c5d1](https://github.com/accelleran/helm-charts/commit/d73c5d1d76e0f10b6f2c0d2028e9751fd63e375e))
* **firecell-core:** Alternative P-CSCF for P-CSCF restoration, off by default ([2625ee1](https://github.com/accelleran/helm-charts/commit/2625ee14cb0abc7563d5d10ace958cc88cf3e358))
* **firecell-core:** CoreConfig.amf.edrx, seeds of the eDRX switches (L1-A1-3) ([015eded](https://github.com/accelleran/helm-charts/commit/015eded33a5f0353537948d17e94208bcdad82df))
* **firecell-core:** Default to the GHCR release images, add a pre-upgrade database step ([b2ca7b6](https://github.com/accelleran/helm-charts/commit/b2ca7b6b53a000853b5243466add325d30c38224))
* **firecell-core:** Make SBI certificates in the chart; turn SBI TLS, OAuth2, NEF, EIR on ([7c5cd7c](https://github.com/accelleran/helm-charts/commit/7c5cd7c4d9427be9f376929d41a2e86cee37af36))
* **firecell-core:** Put the Rx-N5 IWF under SBI TLS/OAuth2; IMS domain and Diameter fixes ([7f7f43f](https://github.com/accelleran/helm-charts/commit/7f7f43ff0f0b6378995e573f981976b16997edfd))
* **firecell-core:** Send the P-CSCF Rx to the rx-n5-iwf when ims.rxN5Iwf.enabled is set ([1988f92](https://github.com/accelleran/helm-charts/commit/1988f92398a7a5afd240122b4e963a7ac047a09b))
* **firecell-core:** Support IPv6 PDU sessions: SMF ipv6 block, CP relay, N6 IPv6, overlay ([46f8ab1](https://github.com/accelleran/helm-charts/commit/46f8ab1f3ca8e0efb22ddc99fe55337cd6bcff89))


### Bug Fixes

* **deps:** Update dependency mysql to v8.4 ([a9bfc1e](https://github.com/accelleran/helm-charts/commit/a9bfc1eedc464a87b463e6d93d4a5982c5fe078c))
* **deps:** Update docker.io/accelleran/cn5g-amf docker tag to v6.0.1 ([98ea6b4](https://github.com/accelleran/helm-charts/commit/98ea6b4cbc161db41962115047e673def1e146e6))
* **deps:** Update docker.io/library/busybox docker tag to v1.38.0 ([#1881](https://github.com/accelleran/helm-charts/issues/1881)) ([a75b0ef](https://github.com/accelleran/helm-charts/commit/a75b0ef609eb327a019854717b70e04c67387f7a))
* **firecell-core:** Add TLS and EIR commercial render guards, 5MBS join, NEF and SNPN notes ([7e29dcf](https://github.com/accelleran/helm-charts/commit/7e29dcf149073efd54e50aa5eebf9ba5d9923242))
* **firecell-core:** Default the core log level to info ([200fdfd](https://github.com/accelleran/helm-charts/commit/200fdfd74474cfd28d590594ce7344440772a3e1))
* **firecell-core:** Fix post-flight IMS and API checks, MnS CM datastore, I-CSCF SIP port ([e02ecd9](https://github.com/accelleran/helm-charts/commit/e02ecd93f4acaabb514651e72e04ba61f0fb2d79))
* **firecell-core:** Fix release-info, post-flight, OAuth2 guard, IMS Secret and db-upgrade ([a46b982](https://github.com/accelleran/helm-charts/commit/a46b98289ab988ecd1a22de56755ecd4795d18d3))
* **firecell-core:** Give the IMS Cx gateway the image pull secrets ([34edd2a](https://github.com/accelleran/helm-charts/commit/34edd2ad3e9626cded4d0401da211b188cd34834))
* **firecell-core:** Guard handover and AMF values, set the NEF host with TLS, fix certificate SANs ([22d7fee](https://github.com/accelleran/helm-charts/commit/22d7feebab305344e4d2cdb2f73aecf18ed4f571))
* **firecell-core:** Keep explicit false booleans, follow upf.enableSnat, drop lab IMS addresses ([01825c2](https://github.com/accelleran/helm-charts/commit/01825c2bb841d0e2115e5187232dbfef34f3a39d))
* **firecell-core:** Let the NSSF switch follow nssf.enabled; IMS N6 warning, NMS Role, README ([9d62385](https://github.com/accelleran/helm-charts/commit/9d623855c388cbd946a9dcd3b738996ba79bd039))
* **firecell-core:** Pull the IMS images at the package version ([49c385e](https://github.com/accelleran/helm-charts/commit/49c385e34e2b7305c0634e778460067db2216ca6))
* **firecell-core:** Pull the NF images from Docker Hub again ([36f6872](https://github.com/accelleran/helm-charts/commit/36f687250dfd3d9f81a5684481b0dd61f790a214))
* **firecell-core:** Recreate the AMF when UDSF is on ([1d5eb86](https://github.com/accelleran/helm-charts/commit/1d5eb862030817da2bac86755b7b660bf0148e2e))
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
