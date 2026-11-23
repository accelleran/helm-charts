#!/usr/bin/env python3
"""Render tests of the fc-acs component of the firecell-nms chart.

Runs `helm template` on the chart with fc-acs off and on, and checks what
must hold whatever else changes: the MySQL root password reaches the
create-database init container only, the fc-acs Secret survives uninstall,
and the southbound Service is a NodePort or a LoadBalancer as configured.

Usage: charts/firecell-nms/tests/acs-render-test.py  (needs helm and PyYAML)
"""

import json
import pathlib
import subprocess
import sys

try:
    import yaml
except ImportError:
    sys.exit("PyYAML is required: pip install pyyaml")

CHART = pathlib.Path(__file__).resolve().parent.parent
BACKEND_SECRET = "nms-secrets"
failures = []


def render(*sets):
    cmd = ["helm", "template", "t", str(CHART), "--namespace", "firecell-nms"]
    for s in sets:
        cmd += ["--set", s]
    out = subprocess.run(cmd, check=True, capture_output=True, text=True).stdout
    return [d for d in yaml.safe_load_all(out) if d]


def find(docs, kind, name):
    for d in docs:
        if d["kind"] == kind and d["metadata"]["name"] == name:
            return d
    return None


def check(cond, message):
    print(("ok   " if cond else "FAIL ") + message)
    if not cond:
        failures.append(message)


def test_disabled():
    docs = render()
    acs = [f'{d["kind"]}/{d["metadata"]["name"]}' for d in docs if "fc-acs" in d["metadata"]["name"]]
    check(not acs, f"acs disabled: no fc-acs object rendered (got {acs})")
    check("fc-acs" not in json.dumps(docs), "acs disabled: no manifest mentions fc-acs")
    np_docs = render("networkPolicy.enabled=true")
    api_np = find(np_docs, "NetworkPolicy", "nms-api")
    check("fc-acs" not in json.dumps(api_np), "acs disabled: nms-api NetworkPolicy does not admit fc-acs")
    check(find(np_docs, "NetworkPolicy", "fc-acs") is None, "acs disabled: no fc-acs NetworkPolicy")


def test_enabled():
    docs = render("acs.enabled=true")
    dep = find(docs, "Deployment", "fc-acs")
    check(dep is not None, "acs enabled: Deployment fc-acs rendered")
    if dep is None:
        return
    spec = dep["spec"]
    pod = spec["template"]["spec"]
    check(spec["replicas"] == 1 and spec["strategy"]["type"] == "Recreate", "one replica, Recreate")

    main = next(c for c in pod["containers"] if c["name"] == "fc-acs")
    check("database-root-password" not in json.dumps(main), "main container has no database-root-password reference")
    check(BACKEND_SECRET not in json.dumps(main), "main container has no reference to the backend Secret")
    env = {e["name"]: e for e in main["env"]}
    check(env["FC_ACS_DATABASE_URL"]["valueFrom"]["secretKeyRef"] == {"name": "fc-acs", "key": "database-url"},
          "FC_ACS_DATABASE_URL from fc-acs/database-url")
    check(env["FC_ACS_NORTHBOUND_TOKEN_FILE"]["value"] == "/etc/fc-acs/secrets/northbound-token", "token file path")
    check(env["FC_ACS_CREDENTIAL_KEY_FILE"]["value"] == "/etc/fc-acs/secrets/credential-key", "credential key file path")
    check(env["FC_ACS_LOG_LEVEL"]["value"] == "info", "log level info")
    check(env["FC_ACS_NMS_URL"]["value"] == "http://nms-api.firecell-nms.svc.cluster.local:8080", "NMS URL is nms-api:8080")
    ports = {p["name"]: p["containerPort"] for p in main["ports"]}
    check(ports == {"southbound": 7547, "northbound": 8080}, f"ports southbound 7547, northbound 8080 (got {ports})")
    check(main["livenessProbe"]["httpGet"]["path"] == "/api/v1/health", "liveness GET /api/v1/health")
    check(main["readinessProbe"]["httpGet"]["path"] == "/api/v1/ready", "readiness GET /api/v1/ready")
    check(main["securityContext"]["readOnlyRootFilesystem"] is True, "read-only root filesystem")
    check(pod["securityContext"]["runAsNonRoot"] is True, "pod runs as non-root")

    init = next(c for c in pod["initContainers"] if c["name"] == "create-database")
    init_env = {e["name"]: e["valueFrom"]["secretKeyRef"] for e in init["env"] if "valueFrom" in e}
    check({"name": BACKEND_SECRET, "key": "database-root-password"} in init_env.values(),
          "init container reads database-root-password from the backend Secret")
    check({"name": "fc-acs", "key": "database-password"} in init_env.values(),
          "init container reads fc-acs/database-password")
    check(init["image"] == "docker.io/library/mysql:8.4.13", f"init container uses the nms-db image (got {init['image']})")
    script = init["command"][-1]
    check("MYSQL_PWD" in script and "-p" not in script.split(), "root password passed through MYSQL_PWD, not argv")

    vols = pod["volumes"]
    check(BACKEND_SECRET not in json.dumps(vols), "no pod volume references the backend Secret")
    secret_vol = next(v for v in vols if v["name"] == "secrets")["secret"]
    check(secret_vol["secretName"] == "fc-acs"
          and sorted(i["key"] for i in secret_vol["items"]) == ["credential-key", "northbound-token"],
          "secret volume mounts only northbound-token and credential-key of fc-acs")

    secret = find(docs, "Secret", "fc-acs")
    check(secret is not None, "Secret fc-acs rendered")
    if secret:
        check(secret["metadata"].get("annotations", {}).get("helm.sh/resource-policy") == "keep",
              "Secret fc-acs has helm.sh/resource-policy: keep")
        check(sorted(secret["data"]) == ["credential-key", "database-password", "database-url", "northbound-token"],
              "Secret fc-acs keys")

    svc = find(docs, "Service", "fc-acs")
    check(svc and svc["spec"]["type"] == "ClusterIP" and svc["spec"]["ports"][0]["port"] == 8080,
          "Service fc-acs ClusterIP 8080")
    sb = find(docs, "Service", "fc-acs-southbound")
    check(sb["spec"]["type"] == "NodePort", "southbound defaults to NodePort")
    check(sb["spec"]["ports"][0]["nodePort"] == 30547 and sb["spec"]["ports"][0]["port"] == 7547,
          "southbound NodePort 30547 on port 7547")
    check(sb["spec"]["externalTrafficPolicy"] == "Local", "NodePort keeps externalTrafficPolicy Local")

    info = find(docs, "ConfigMap", "t-release-info")
    images = json.loads(info["data"]["release.json"])["images"]
    check(images.get("fc-acs/fc-acs") == "docker.io/accelleran/fc-acs:6.0.0", "release-info lists the fc-acs image")


def test_load_balancer():
    docs = render("acs.enabled=true", "acs.southbound.loadBalancerIP=192.0.2.10")
    sb = find(docs, "Service", "fc-acs-southbound")
    check(sb["spec"]["type"] == "LoadBalancer", "southbound is a LoadBalancer when loadBalancerIP is set")
    check(sb["spec"].get("loadBalancerIP") == "192.0.2.10", "loadBalancerIP set")
    check(sb["metadata"].get("annotations", {}).get("lbipam.cilium.io/ips") == "192.0.2.10", "Cilium LB-IPAM annotation set")
    check(sb["spec"]["externalTrafficPolicy"] == "Cluster", "LoadBalancer uses externalTrafficPolicy Cluster")
    check("nodePort" not in sb["spec"]["ports"][0], "no fixed nodePort on the LoadBalancer")


def test_network_policy():
    docs = render("acs.enabled=true", "networkPolicy.enabled=true")
    api_np = find(docs, "NetworkPolicy", "nms-api")
    peers = api_np["spec"]["ingress"][0]["from"]
    check({"podSelector": {"matchLabels": {"app": "fc-acs"}}} in peers, "nms-api NetworkPolicy admits fc-acs")
    acs_np = find(docs, "NetworkPolicy", "fc-acs")
    check(acs_np is not None, "fc-acs NetworkPolicy rendered")
    if acs_np:
        rules = acs_np["spec"]["ingress"]
        north = next(r for r in rules if r["ports"][0]["port"] == 8080)
        labels = sorted(p["podSelector"]["matchLabels"]["app"] for p in north["from"])
        check(labels == ["nms-api", "nms-worker"], f"8080 from nms-api and nms-worker only (got {labels})")
        south = next(r for r in rules if r["ports"][0]["port"] == 7547)
        check("from" not in south, "7547 from anywhere")
    off = render("acs.enabled=true")
    check(not [d for d in off if d["kind"] == "NetworkPolicy"], "no NetworkPolicy while networkPolicy.enabled is false")


test_disabled()
test_enabled()
test_load_balancer()
test_network_policy()
if failures:
    sys.exit(f"{len(failures)} check(s) failed")
print("all checks passed")
