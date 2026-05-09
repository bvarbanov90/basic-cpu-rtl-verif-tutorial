from __future__ import annotations

from pathlib import Path

from scripts.verification_matrix import LANES, render_markdown, validate_verification_matrix

PROJECT_ROOT = Path(__file__).resolve().parents[1]


def test_verification_matrix_is_valid() -> None:
    assert validate_verification_matrix() == []


def test_matrix_covers_expected_lane_families() -> None:
    keys = {lane.key for lane in LANES}

    assert {
        "core",
        "mmio",
        "mmio-wait",
        "apb",
        "apb-fault",
        "wishbone",
        "wishbone-fault",
        "axi-lite",
        "axi-lite-fault",
    } <= keys
    assert all(lane.native_script and lane.native_tb for lane in LANES)


def test_full_stack_lanes_have_cocotb_pyuvm_and_cover_formal() -> None:
    full_stack = [lane for lane in LANES if not lane.key.endswith("-fault")]

    assert len(full_stack) >= 6
    for lane in full_stack:
        assert lane.cocotb_script and lane.cocotb_test, lane.key
        assert lane.pyuvm_script and lane.pyuvm_test, lane.key
        assert any(target.endswith("_cover.sby") for target in lane.formal_targets)


def test_verification_matrix_matches_tracked_doc() -> None:
    expected = render_markdown()
    actual = (PROJECT_ROOT / "docs" / "verification-matrix.md").read_text(encoding="utf-8")
    assert actual == expected
