# Changelog

## [0.2.1](https://github.com/accelleran/helm-charts/compare/firecell-du-0.2.0...firecell-du-0.2.1) (2026-11-14)


### Features

* **firecell-cu,firecell-du:** NetconfVerbosity sets the netopeer2 log level ([d201997](https://github.com/accelleran/helm-charts/commit/d201997506b9e103238440581ee851905c3c74c7))
* **firecell-du:** Liteon, vvdn and mti, and ofh.vendorProfile (FEAT-0016) ([5c084e9](https://github.com/accelleran/helm-charts/commit/5c084e94bf4ecabaab76b51a7356b1e6c4262ede))
* **firecell-du:** Ru.vendor simulator for an O-RU simulator (FEAT-0016) ([8217d9a](https://github.com/accelleran/helm-charts/commit/8217d9ad4c0c8d4895cb3312ba18d790f3698b64))
* **firecell-du:** Split 8 radios (AW2S, B210, ZMQ) and ru.split / ru.vendor / ru.sdr.* ([86b75f1](https://github.com/accelleran/helm-charts/commit/86b75f10dd71f1bfcc7b65ba0e39a84e9bc1aca8))


### Bug Fixes

* **firecell-du:** Load liboai_device.so from the image and check the host Swallow libs ([15766f3](https://github.com/accelleran/helm-charts/commit/15766f35a8b262d18788667fc360f9221b685056))
* **firecell-du:** Set terminationGracePeriodSeconds so the DU can switch the RU off at stop ([33236a3](https://github.com/accelleran/helm-charts/commit/33236a38c2cfbba7fd19024c351773bb596a4224))

## [0.2.0](https://github.com/accelleran/helm-charts/compare/firecell-du-0.1.0...firecell-du-0.2.0) (2026-10-30)


### Features

* **firecell-core,firecell-cu,firecell-du:** Default to the published CI images ([#1801](https://github.com/accelleran/helm-charts/issues/1801)) ([50ae587](https://github.com/accelleran/helm-charts/commit/50ae5871ee06450fd24f2b725d640c73191fe422))
* **firecell-cu,firecell-du:** Default to the published ran 0.1.0 image ([f36f5ac](https://github.com/accelleran/helm-charts/commit/f36f5ac5c13c5fff9d983f91dc8865a7628624c6))


### Miscellaneous Chores

* Release firecell-du 0.2.0-rc.1 ([f230e10](https://github.com/accelleran/helm-charts/commit/f230e10748392405f057e924183aa200e81ddef4))
