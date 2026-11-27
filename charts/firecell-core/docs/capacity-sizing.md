# Capacity sizing

Several firecell-core defaults are sized for a lab with a handful of UEs. This page lists the
values that cap how many UEs a release can serve, and how to size them. Measure the figures
marked *estimate* on your own deployment.

## 1. UE address pools

`coreConfig.dnns[].ipv4Subnet` is the pool the SMF allocates UE IPv4 addresses from, one per
PDU session of that DNN.

- The defaults are `12.1.1.0/25` (`oai`) and `14.1.1.0/25` (`ims`).
- A /25 holds **126 UE addresses**, because the network and broadcast addresses are not
  allocated. A 127th UE gets no address, so its PDU session to that DNN fails.

| UEs with a session on the DNN | Smallest prefix | UE addresses |
|---|---|---|
| up to 126 | /25 | 126 |
| up to 1,000 | /22 | 1,022 |
| up to 5,000 | /19 | 8,190 |
| up to 10,000 | /18 | 16,382 |

When you widen a pool:
- Set `ims.ueImsSubnet` to the same prefix as the `ims` DNN. The Kamailio P-CSCF routes
  `ims.ueImsSubnet` toward the UPF (`ims.upfN6Gateway`).
- Make sure the DN-side return routes to the UEs (routers, the N6 gateway, firewall rules)
  cover the wider prefix.
- Make sure the new prefix does not overlap any other subnet of the site.
- Changing the subnet of a running release changes the addresses that new sessions get.

## 2. UPF PDU session cap

`upf.maxPduSession` sets the UPF's PDU session cap (`support_features.max_pdu_session`, 1 to
65535).
- When it is empty with `configSchema: mr97`, the UPF keeps its built-in default (10000 in
  cn5g-upf v6.0.1).
- With `configSchema: legacy`, the chart writes 100.

Count sessions, not UEs. A UE with an internet session and an IMS session needs 2.

The UPF preallocates its BPF maps for the cap, so its memory use grows with it.
- *Estimate*: about 30 KB per session, or about 330 MB at 10,000 sessions.
- Set `upf.resources.limits.memory` (default 1Gi) with enough margin above that.
- To check the real figure, run `bpftool map show` on the UPF node after start-up.

## 3. UDSF Redis

Every AMF and SMF context the UDSF stores is kept in the `udsf-redis` Deployment.

**Persistence**
- `udsf.redis.persistence.appendonly` (default `true`) writes an append-only file to `/data`.
- With `persistence.volume: emptyDir` (the default), the data survives container restarts in
  the same pod, such as an OOM kill or a liveness kill.
- It does not survive pod deletion or rescheduling, a node reboot, or the upgrade that first
  turns persistence on.
- Use `persistence.volume: pvc` (claim `udsf-redis-data`, `persistence.size`,
  `persistence.storageClass`) to keep the data across those too.

**Memory**
- `udsf.redis.maxmemory` (default `160mb`) is enforced with the `noeviction` policy. A full
  Redis rejects new writes instead of dropping stored contexts.
- Keep `maxmemory` at about 60 % of `udsf.redis.resources.limits.memory` (default 256Mi). An
  append-only-file rewrite forks, and its copy-on-write pages count against the same limit.

To size it:
1. Register a known number of UEs, with their PDU sessions.
2. Read `used_memory` from `redis-cli INFO memory` and divide it by that UE count.
3. Multiply by the target UE count, add margin, and set `maxmemory` to the result.
4. Set the memory limit to about `maxmemory / 0.6`.
5. Set `persistence.size` to at least twice the data set, so an append-only-file rewrite has
   room.

## 4. MySQL

`mysql.resources.limits.cpu` defaults to 1 CPU, shared by the UDR, PCF, EIR and IMS databases.
Each registration reads the subscriber data and updates the authentication sequence number in
the UDR's database. Bursts of registrations therefore load MySQL directly.

For large UE counts, raise the CPU limit and watch MySQL latency and CPU throttling.

## 5. Replicas

Every NF runs as one replica, with no autoscaling. Control-plane capacity depends mostly on
how fast each NF processes requests, not on the number of node cores. Measure the
registration and PDU session rates your deployment sustains before planning for many
thousands of UEs.
