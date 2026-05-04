from __future__ import annotations

from pathlib import Path

from scripts.tooling_catalog import (
    installer_catalog,
    parse_requirements,
    render_markdown,
    validate_tooling_catalog,
)

PROJECT_ROOT = Path(__file__).resolve().parents[1]


def test_tooling_catalog_is_valid() -> None:
    assert validate_tooling_catalog() == []


def test_python_requirements_have_expected_shape() -> None:
    requirements = {requirement.name: requirement for requirement in parse_requirements()}

    assert {"cocotb", "pyuvm", "pytest", "click"} <= set(requirements)
    assert requirements["cocotb"].constraint == "==2.0.1"
    assert requirements["pyuvm"].constraint == ">=4.0,<5.0"
    assert 'python_version < "3.14"' in requirements["pytest"].marker


def test_installers_cover_expected_open_source_tools() -> None:
    catalog = installer_catalog()

    assert {"iverilog", "verilator", "yosys", "cvc5", "z3", "gtkwave"} <= set(
        catalog.linux_full_packages
    )
    assert catalog.linux_mutation_packages == ("iverilog", "python3")
    assert {"YosysHQ/oss-cad-suite-build", "chipsalliance/verible", "dalance/svlint"} <= set(
        catalog.github_repos
    )
    assert {"OSS_CAD_SUITE_ROOT", "VERIBLE_ROOT", "SVLINT_ROOT"} <= set(catalog.windows_env_vars)


def test_tooling_catalog_matches_tracked_doc() -> None:
    expected = render_markdown()
    actual = (PROJECT_ROOT / "docs" / "tooling-catalog.md").read_text(encoding="utf-8")
    assert actual == expected
