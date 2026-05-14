from __future__ import annotations

from pathlib import Path

from scripts.adapter_contract import (
    ADAPTERS,
    COMMON_REQUIREMENTS,
    WRAPPER_REQUIREMENTS,
    adapter_methods,
    render_markdown,
    validate_adapter_contract,
)

PROJECT_ROOT = Path(__file__).resolve().parents[1]


def test_adapter_contract_is_valid() -> None:
    assert validate_adapter_contract() == []


def test_adapter_contract_covers_expected_bfms() -> None:
    assert {"direct-core", "mmio", "apb", "wishbone", "axi-lite"} <= {spec.name for spec in ADAPTERS}


def test_all_adapters_expose_shared_conformance_methods() -> None:
    methods_by_adapter = adapter_methods()
    required = {method.name for method in COMMON_REQUIREMENTS}

    for spec in ADAPTERS:
        assert required <= set(methods_by_adapter[spec.name])


def test_wrapper_adapters_expose_register_helpers() -> None:
    methods_by_adapter = adapter_methods()
    required = {method.name for method in WRAPPER_REQUIREMENTS}

    for spec in ADAPTERS:
        if spec.wrapper_adapter:
            assert required <= set(methods_by_adapter[spec.name])


def test_adapter_contract_matches_tracked_doc() -> None:
    expected = render_markdown()
    actual = (PROJECT_ROOT / "docs" / "adapter-contract.md").read_text(encoding="utf-8")
    assert actual == expected
