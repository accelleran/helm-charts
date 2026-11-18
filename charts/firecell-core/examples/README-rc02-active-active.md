# rc-02 active-active overlays (sandbox)

Sandboxed on branch `feat/rc02-active-active` (from helm-charts PR #1912 /
`wave/firecell-core-rc02-features`). Defaults stay HA-off.

## Image tags

Pin only `*:rc02-aa-<sha12>` images in site overlays. Do not retag product/rc-02
wave images.

## Layering (fc-ha)

```bash
helm upgrade --install firecell-core charts/firecell-core -n firecell-core \
  -f <site-base>.yaml \
  -f examples/values-fc-ha-aa-images.yaml \
  -f examples/values-fc-ha-mode2.yaml \
  -f examples/values-fc-ha-datastore-ha.yaml \
  -f examples/values-fc-ha-pxc-nrf.yaml \
  -f examples/values-fc-ha-smf-ha.yaml \
  -f examples/values-fc-ha-upf-pool.yaml \
  -f examples/values-fc-ha-full-compose.yaml
```

Keep `ha.fullActiveActive: false` until the live kill matrix + PDU resume pass.
When flipping to true, `validateFullAa` fails closed if Mode-2 / SMF×2 / NRF
mysql / UDSF / PXC / UPF×2 are incomplete.

## Lab harness

See `charts/firecell-core/scripts/mode2-cp-lab-test.sh` and `make test-mode2-cp`
notes in that script header (release name `firecell-core`).
