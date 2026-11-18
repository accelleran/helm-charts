"""Offline Mode-2 / full-AA chart contracts for firecell-core (no cluster)."""
from __future__ import annotations

import subprocess
from pathlib import Path

import pytest

CHART = Path(__file__).resolve().parents[2]  # charts/firecell-core
EX = CHART / "examples"


def _helm(*extra: str) -> str:
    cmd = ["helm", "template", "fc", str(CHART), "-n", "firecell-core", *extra]
    return subprocess.check_output(cmd, text=True, stderr=subprocess.STDOUT)


def test_default_amf_is_deployment_not_sts():
    out = _helm()
    assert "kind: StatefulSet\nmetadata:\n  name: oai-amf" not in out.replace("\r", "")
    assert "kind: Deployment" in out
    assert "name: oai-amf" in out
    assert "__AMF_POINTER__" not in out


def test_mode2_renders_sts_and_ordinal_vips():
    out = _helm("-f", str(EX / "values-fc-ha-mode2.yaml"))
    assert "kind: StatefulSet" in out
    assert "name: oai-amf" in out
    assert "name: oai-amf-0" in out
    assert "name: oai-amf-1" in out
    assert "192.168.30.205" in out
    assert "__AMF_POINTER__" in out
    # Shared SBI service must not publish NGAP when Mode-2 VIPs exist
    # (ordinal services own 38412).
    assert "name: oai-amf-headless" in out


def test_full_aa_fail_closed_without_smf_scale():
    with pytest.raises(subprocess.CalledProcessError) as ei:
        _helm(
            "-f",
            str(EX / "values-fc-ha-mode2.yaml"),
            "--set",
            "ha.fullActiveActive=true",
        )
    assert "T-FULL-1" in (ei.value.output or ei.value.stderr or "")
