from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from scripts.ci_catalog import parse_workflow

REQUIREMENTS_PATH = PROJECT_ROOT / "requirements.txt"
WINDOWS_INSTALLER = PROJECT_ROOT / "scripts" / "windows" / "install-tools.ps1"
LINUX_INSTALLER = PROJECT_ROOT / "scripts" / "linux" / "install-tools-ubuntu.sh"
LINUX_OSS_CAD_SUITE = PROJECT_ROOT / "scripts" / "linux" / "oss-cad-suite.sh"

REQUIRED_PYTHON_PACKAGES = ("cocotb", "pyuvm", "pytest", "click")
REQUIRED_LINUX_FULL_PACKAGES = (
    "iverilog",
    "verilator",
    "gtkwave",
    "yosys",
    "cvc5",
    "z3",
    "make",
    "python3",
    "python3-venv",
)
REQUIRED_LINUX_MUTATION_PACKAGES = ("iverilog", "python3")
REQUIRED_WINDOWS_ENV = ("OSS_CAD_SUITE_ROOT", "VERIBLE_ROOT", "SVLINT_ROOT")


@dataclass(frozen=True)
class PythonRequirement:
    name: str
    constraint: str
    marker: str
    raw: str


@dataclass(frozen=True)
class InstallerCatalog:
    windows_wrapper: str
    linux_wrapper: str
    windows_impl: str
    linux_impl: str
    linux_full_packages: tuple[str, ...]
    linux_mutation_packages: tuple[str, ...]
    github_repos: tuple[str, ...]
    windows_env_vars: tuple[str, ...]
    linux_oss_cad_suite_env: tuple[str, ...]


def rel(path: Path) -> str:
    return path.relative_to(PROJECT_ROOT).as_posix()


def parse_requirements() -> tuple[PythonRequirement, ...]:
    requirements: list[PythonRequirement] = []
    for line in REQUIREMENTS_PATH.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue

        requirement_text, _, marker = stripped.partition(";")
        match = re.match(r"^(?P<name>[A-Za-z0-9_.-]+)(?P<constraint>.*)$", requirement_text.strip())
        if not match:
            raise ValueError(f"Could not parse requirement line: {line}")
        requirements.append(
            PythonRequirement(
                name=match.group("name"),
                constraint=match.group("constraint").strip() or "-",
                marker=marker.strip() or "-",
                raw=stripped,
            )
        )
    return tuple(requirements)


def _packages_from_block(block: str) -> tuple[str, ...]:
    packages: list[str] = []
    for line in block.splitlines():
        item = line.strip().rstrip("\\").strip()
        if item and not item.startswith("#"):
            packages.append(item)
    return tuple(packages)


def parse_linux_packages() -> tuple[tuple[str, ...], tuple[str, ...]]:
    text = LINUX_INSTALLER.read_text(encoding="utf-8")
    match = re.search(
        r'if \[\[ "\$\{PROFILE\}" == "mutations" \]\]; then\s+apt_install \\\s+(?P<mutations>.*?)'
        r"\s+else\s+apt_install \\\s+(?P<full>.*?)\s+fi",
        text,
        re.S,
    )
    if not match:
        raise ValueError("Could not parse Linux installer apt profiles.")

    mutations = _packages_from_block(match.group("mutations"))
    full = _packages_from_block(match.group("full"))
    return full, mutations


def parse_github_repos() -> tuple[str, ...]:
    text = "\n".join(
        [
            WINDOWS_INSTALLER.read_text(encoding="utf-8"),
            LINUX_INSTALLER.read_text(encoding="utf-8"),
            LINUX_OSS_CAD_SUITE.read_text(encoding="utf-8"),
        ]
    )
    repos = set(re.findall(r"https://api\.github\.com/repos/([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)", text))
    repos.update(re.findall(r"-Repo\s+\"([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)\"", text))
    repos.update(re.findall(r'OSS_CAD_SUITE_REPO="\$\{OSS_CAD_SUITE_REPO:-([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)\}"', text))
    repos.update(re.findall(r'^\s+"([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)"\s+\\?$', text, re.M))
    return tuple(sorted(repos))


def parse_env_vars() -> tuple[str, ...]:
    text = WINDOWS_INSTALLER.read_text(encoding="utf-8")
    env_vars = sorted({name for name in REQUIRED_WINDOWS_ENV if name in text})
    return tuple(env_vars)


def parse_oss_cad_suite_env() -> tuple[str, ...]:
    text = LINUX_OSS_CAD_SUITE.read_text(encoding="utf-8")
    names = sorted(set(re.findall(r"\bOSS_CAD_SUITE_[A-Z_]+\b", text)))
    return tuple(names)


def installer_catalog() -> InstallerCatalog:
    full, mutations = parse_linux_packages()
    return InstallerCatalog(
        windows_wrapper="scripts/install-tools.ps1",
        linux_wrapper="scripts/install-tools-ubuntu.sh",
        windows_impl=rel(WINDOWS_INSTALLER),
        linux_impl=rel(LINUX_INSTALLER),
        linux_full_packages=full,
        linux_mutation_packages=mutations,
        github_repos=parse_github_repos(),
        windows_env_vars=parse_env_vars(),
        linux_oss_cad_suite_env=parse_oss_cad_suite_env(),
    )


def validate_tooling_catalog() -> list[str]:
    failures: list[str] = []
    requirements = parse_requirements()
    requirement_names = {requirement.name for requirement in requirements}
    catalog = installer_catalog()

    for package in REQUIRED_PYTHON_PACKAGES:
        if package not in requirement_names:
            failures.append(f"requirements.txt missing Python package `{package}`")

    for requirement in requirements:
        if requirement.name in {"cocotb", "pyuvm", "pytest"} and 'python_version < "3.14"' not in requirement.marker:
            failures.append(f"{requirement.name}: expected Python < 3.14 marker")

    for path in (
        catalog.windows_wrapper,
        catalog.linux_wrapper,
        catalog.windows_impl,
        catalog.linux_impl,
        rel(LINUX_OSS_CAD_SUITE),
    ):
        if not (PROJECT_ROOT / path).exists():
            failures.append(f"missing tooling file `{path}`")

    for package in REQUIRED_LINUX_FULL_PACKAGES:
        if package not in catalog.linux_full_packages:
            failures.append(f"Linux full installer profile missing `{package}`")

    for package in REQUIRED_LINUX_MUTATION_PACKAGES:
        if package not in catalog.linux_mutation_packages:
            failures.append(f"Linux mutations installer profile missing `{package}`")

    for repo in ("YosysHQ/oss-cad-suite-build", "chipsalliance/verible", "dalance/svlint"):
        if repo not in catalog.github_repos:
            failures.append(f"tool installers do not reference GitHub release repo `{repo}`")

    for name in REQUIRED_WINDOWS_ENV:
        if name not in catalog.windows_env_vars:
            failures.append(f"Windows installer does not set `{name}`")

    workflow = parse_workflow()
    if not workflow.oss_cad_suite_release_tag:
        failures.append("CI workflow must pin OSS_CAD_SUITE_RELEASE_TAG")

    return failures


def _markdown_list(values: tuple[str, ...]) -> str:
    return ", ".join(f"`{value}`" for value in values) if values else "-"


def render_markdown() -> str:
    failures = validate_tooling_catalog()
    if failures:
        joined = "\n".join(f"- {failure}" for failure in failures)
        raise ValueError(f"tooling catalog is invalid:\n{joined}")

    requirements = parse_requirements()
    catalog = installer_catalog()
    workflow = parse_workflow()

    lines = [
        "<!-- Generated by scripts/tooling_catalog.py. Do not edit by hand. -->",
        "",
        "# Tooling Catalog",
        "",
        "This page is generated from `requirements.txt`, installer scripts, and `.github/workflows/ci.yml`.",
        "",
        "## Summary",
        "",
        f"- Python requirements: {len(requirements)}",
        f"- Linux full apt packages: {len(catalog.linux_full_packages)}",
        f"- Linux mutation-profile apt packages: {len(catalog.linux_mutation_packages)}",
        f"- GitHub release sources: {len(catalog.github_repos)}",
        f"- CI OSS CAD Suite pin: `{workflow.oss_cad_suite_release_tag}`",
        "",
        "## Python Packages",
        "",
        "| Package | Constraint | Marker | Source line |",
        "|---|---|---|---|",
    ]

    for requirement in requirements:
        lines.append(
            f"| `{requirement.name}` | `{requirement.constraint}` | `{requirement.marker}` | `{requirement.raw}` |"
        )

    lines.extend(
        [
            "",
            "## Installer Entrypoints",
            "",
            "| Platform | Compatibility wrapper | Implementation | Notes |",
            "|---|---|---|---|",
            (
                f"| Windows | `{catalog.windows_wrapper}` | `{catalog.windows_impl}` | "
                f"Installs OSS CAD Suite, Verible, and svlint under `$HOME/tools`; sets {_markdown_list(catalog.windows_env_vars)}. |"
            ),
            (
                f"| Ubuntu/WSL | `{catalog.linux_wrapper}` | `{catalog.linux_impl}` | "
                "Supports `--profile full` and `--profile mutations`. |"
            ),
            "",
            "## Linux Apt Profiles",
            "",
            "| Profile | Packages |",
            "|---|---|",
            f"| `full` | {_markdown_list(catalog.linux_full_packages)} |",
            f"| `mutations` | {_markdown_list(catalog.linux_mutation_packages)} |",
            "",
            "## GitHub Release Sources",
            "",
            "| Repository | Used for |",
            "|---|---|",
            "| `YosysHQ/oss-cad-suite-build` | OSS CAD Suite daily builds for Windows and Linux fallback flows |",
            "| `chipsalliance/verible` | Verible lint/format binaries |",
            "| `dalance/svlint` | svlint binary releases |",
            "",
            "## OSS CAD Suite Environment",
            "",
            f"- Linux helper: `{rel(LINUX_OSS_CAD_SUITE)}`",
            f"- Linux helper environment variables: {_markdown_list(catalog.linux_oss_cad_suite_env)}",
            f"- CI release pin: `{workflow.oss_cad_suite_release_tag}`",
            "",
            "Regenerate this page after intentional dependency or installer edits with:",
            "",
            "```powershell",
            ".\\scripts\\generate-tooling-catalog.ps1",
            "```",
            "",
            "```bash",
            "bash scripts/generate-tooling-catalog.sh",
            "```",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate and check the open-source tooling catalog.")
    parser.add_argument("--output", type=Path, default=Path("docs/tooling-catalog.md"))
    parser.add_argument("--check", action="store_true", help="Fail if the generated output is stale.")
    args = parser.parse_args()

    output_path = (PROJECT_ROOT / args.output).resolve()
    expected = render_markdown()

    if args.check:
        if not output_path.exists():
            print(f"Tooling catalog is missing: {output_path}", file=sys.stderr)
            raise SystemExit(1)
        actual = output_path.read_text(encoding="utf-8")
        if actual != expected:
            print(
                f"Tooling catalog is stale: {output_path}. "
                "Regenerate with scripts/generate-tooling-catalog.*",
                file=sys.stderr,
            )
            raise SystemExit(1)
        print(f"Tooling catalog is up to date: {args.output}")
        return

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(expected, encoding="utf-8")
    print(f"Wrote {args.output}")


if __name__ == "__main__":
    main()
