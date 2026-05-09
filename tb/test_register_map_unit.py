from __future__ import annotations

from pathlib import Path

from scripts.register_map import (
    EXPECTED_CONSTANTS,
    PROTOCOLS,
    REGISTERS,
    parse_python_address_constants,
    parse_sv_address_constants,
    render_markdown,
    validate_register_map,
)

PROJECT_ROOT = Path(__file__).resolve().parents[1]


def test_register_map_is_valid() -> None:
    assert validate_register_map() == []


def test_rtl_and_python_address_constants_match() -> None:
    assert parse_sv_address_constants() == EXPECTED_CONSTANTS
    assert parse_python_address_constants() == EXPECTED_CONSTANTS


def test_register_map_covers_expected_regions_and_protocols() -> None:
    register_names = {entry.name for entry in REGISTERS}
    protocol_names = {view.name for view in PROTOCOLS}

    assert {"SHADOW_IMEM", "STATUS", "ACC", "PC", "DMEM", "CONTROL", "UNMAPPED"} <= register_names
    assert {"MMIO", "MMIO wait", "APB", "Wishbone", "AXI-Lite"} <= protocol_names


def test_register_map_matches_tracked_doc() -> None:
    expected = render_markdown()
    actual = (PROJECT_ROOT / "docs" / "register-map.md").read_text(encoding="utf-8")
    assert actual == expected
