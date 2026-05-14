from __future__ import annotations

import argparse
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from scripts.script_catalog import script_entrypoints


@dataclass(frozen=True)
class DocumentationEntry:
    path: str
    kind: str
    owner: str
    generator: str
    check: str
    sources: tuple[str, ...]
    purpose: str


DOCUMENTATION: tuple[DocumentationEntry, ...] = (
    DocumentationEntry(
        path="README.md",
        kind="manual",
        owner="tutorial",
        generator="-",
        check="review",
        sources=("rtl/", "tb/", "scripts/", "formal/", "equiv/", "programs/"),
        purpose="Primary tutorial entry point, setup flow, run commands, and verification feature tour.",
    ),
    DocumentationEntry(
        path="docs/verification-plan.md",
        kind="manual",
        owner="verification",
        generator="-",
        check="review",
        sources=("rtl/", "tb/", "formal/", "scripts/"),
        purpose="Verification intent, executed checks, coverage model, formal scope, and regression map.",
    ),
    DocumentationEntry(
        path="scripts/README.md",
        kind="manual",
        owner="automation",
        generator="-",
        check="scripts/script_catalog.py --check",
        sources=("scripts/",),
        purpose="Cross-platform script layout and maintenance notes for wrapper/implementation symmetry.",
    ),
    DocumentationEntry(
        path="programs/README.md",
        kind="manual",
        owner="assembler",
        generator="-",
        check="review",
        sources=("programs/", "scripts/asm.py"),
        purpose="Assembly corpus authoring notes for tutorial programs.",
    ),
    DocumentationEntry(
        path="docs/isa.md",
        kind="generated",
        owner="isa",
        generator="generate-isa-docs",
        check="scripts/check-python-model.*",
        sources=("tb/cpu_lib.py", "scripts/isa_report.py"),
        purpose="Human-readable ISA table generated from executable reference-model metadata.",
    ),
    DocumentationEntry(
        path="docs/assembler-regressions.md",
        kind="generated",
        owner="assembler",
        generator="generate-asm-corpus-docs",
        check="scripts/check-python-model.*",
        sources=("programs/", "docs/assembler-regressions.json", "scripts/asm_corpus_report.py"),
        purpose="Readable table for assembly corpus bytes, expected final state, and coverage signatures.",
    ),
    DocumentationEntry(
        path="docs/formal-targets.md",
        kind="generated",
        owner="formal",
        generator="generate-formal-catalog",
        check="scripts/check-python-model.*",
        sources=("formal/", "scripts/formal_catalog.py", "scripts/run-formal.*"),
        purpose="SymbiYosys target catalog with mode, file-reference, and wrapper coverage validation.",
    ),
    DocumentationEntry(
        path="docs/mutation-catalog.md",
        kind="generated",
        owner="mutation",
        generator="generate-mutation-catalog",
        check="scripts/check-python-model.*",
        sources=("scripts/run_mutation_campaign.py", "rtl/", "tb/"),
        purpose="Mutation definitions, target snippets, categories, and native bench scopes.",
    ),
    DocumentationEntry(
        path="docs/script-catalog.md",
        kind="generated",
        owner="automation",
        generator="generate-script-catalog",
        check="scripts/check-python-model.*",
        sources=("scripts/", "scripts/script_catalog.py"),
        purpose="Catalog of top-level compatibility wrappers and platform-specific implementations.",
    ),
    DocumentationEntry(
        path="docs/ci-catalog.md",
        kind="generated",
        owner="ci",
        generator="generate-ci-catalog",
        check="scripts/check-python-model.*",
        sources=(".github/workflows/ci.yml", "scripts/ci_catalog.py"),
        purpose="GitHub Actions job, dependency, script-reference, artifact, and toolchain-pin review page.",
    ),
    DocumentationEntry(
        path="docs/tooling-catalog.md",
        kind="generated",
        owner="tooling",
        generator="generate-tooling-catalog",
        check="scripts/check-python-model.*",
        sources=("requirements.txt", "scripts/install-tools.*", "scripts/tooling_catalog.py"),
        purpose="Open-source dependency, installer profile, release source, and environment-variable inventory.",
    ),
    DocumentationEntry(
        path="docs/verification-matrix.md",
        kind="generated",
        owner="verification",
        generator="generate-verification-matrix",
        check="scripts/check-python-model.*",
        sources=("scripts/verification_matrix.py", "tb/", "formal/", "scripts/"),
        purpose="Lane-by-lane coverage of native SV, cocotb, pyuvm, formal, assertions, artifacts, and mutations.",
    ),
    DocumentationEntry(
        path="docs/artifact-catalog.md",
        kind="generated",
        owner="ci",
        generator="generate-artifact-catalog",
        check="scripts/check-python-model.*",
        sources=("scripts/artifact_catalog.py", ".github/workflows/ci.yml", "scripts/verification_matrix.py"),
        purpose="Generated output, formal workdir, CI upload, and show-helper alignment table.",
    ),
    DocumentationEntry(
        path="docs/requirements-traceability.md",
        kind="generated",
        owner="verification",
        generator="generate-requirements-traceability",
        check="scripts/check-python-model.*",
        sources=("scripts/requirements_traceability.py", "scripts/verification_matrix.py", "scripts/artifact_catalog.py"),
        purpose="Requirements-to-evidence traceability across lanes, formal targets, mutation benches, and artifacts.",
    ),
    DocumentationEntry(
        path="docs/coverage-goals.md",
        kind="generated",
        owner="coverage",
        generator="generate-coverage-goals",
        check="scripts/check-python-model.*",
        sources=("scripts/coverage_goals.py", "tb/*_tb.sv", "tb/coverage_utils.py"),
        purpose="Functional coverage goals, thresholds, source testbenches, artifacts, and show-helper mappings.",
    ),
    DocumentationEntry(
        path="docs/reference-regression.md",
        kind="generated",
        owner="verification",
        generator="generate-reference-regression",
        check="scripts/check-python-model.*",
        sources=("scripts/reference_regression_catalog.py", "tb/cpu_lib.py", "tb/coverage_utils.py"),
        purpose="Deterministic directed and seeded-random Python reference regression cases with coverage closure.",
    ),
    DocumentationEntry(
        path="docs/register-map.md",
        kind="generated",
        owner="wrappers",
        generator="generate-register-map",
        check="scripts/check-python-model.*",
        sources=("scripts/register_map.py", "rtl/simple_cpu_mmio.sv", "tb/mmio_bus.py"),
        purpose="Shared wrapper address map with RTL/Python constant alignment checks.",
    ),
    DocumentationEntry(
        path="docs/protocol-conformance.md",
        kind="generated",
        owner="wrappers",
        generator="generate-protocol-catalog",
        check="scripts/check-python-model.*",
        sources=("scripts/protocol_catalog.py", "tb/protocol_conformance.py", "tb/test_simple_cpu*.py"),
        purpose="Shared protocol conformance scenarios, expected final states, and adapter test coverage.",
    ),
    DocumentationEntry(
        path="docs/adapter-contract.md",
        kind="generated",
        owner="wrappers",
        generator="generate-adapter-contract",
        check="scripts/check-python-model.*",
        sources=("scripts/adapter_contract.py", "tb/*_bus.py", "tb/protocol_conformance.py"),
        purpose="Python bus-adapter method contract for shared conformance, directed cocotb, and pyuvm tests.",
    ),
    DocumentationEntry(
        path="docs/documentation-index.md",
        kind="generated",
        owner="docs",
        generator="generate-documentation-index",
        check="scripts/check-python-model.*",
        sources=("scripts/documentation_index.py", "README.md", "docs/verification-plan.md"),
        purpose="Single index of tutorial docs, generated catalogs, source-of-truth files, and freshness checks.",
    ),
    DocumentationEntry(
        path="docs/coverage-history.md",
        kind="exported",
        owner="coverage",
        generator="record-coverage-history",
        check="scripts/check-coverage-delta.*",
        sources=("docs/coverage-history.json", "sim_build/*coverage*.json"),
        purpose="Rendered coverage trend history generated from recorded coverage snapshots.",
    ),
    DocumentationEntry(
        path="docs/status/status.md",
        kind="exported",
        owner="status",
        generator="export-status",
        check="CI summary",
        sources=("docs/status/status.json", "sim_build/", "formal/"),
        purpose="Repo-tracked verification status snapshot used by README badges.",
    ),
    DocumentationEntry(
        path="docs/assembler-regressions.json",
        kind="data",
        owner="assembler",
        generator="generate-asm-corpus-docs",
        check="scripts/check-python-model.*",
        sources=("programs/", "scripts/asm.py", "tb/cpu_lib.py"),
        purpose="Machine-readable expected bytes, final states, and coverage signatures for assembly programs.",
    ),
    DocumentationEntry(
        path="docs/coverage-baseline.json",
        kind="data",
        owner="coverage",
        generator="update-coverage-baseline",
        check="scripts/check-coverage-delta.*",
        sources=("sim_build/coverage.json",),
        purpose="Tracked minimum acceptable coverage baseline for regression delta checks.",
    ),
    DocumentationEntry(
        path="docs/coverage-history.json",
        kind="data",
        owner="coverage",
        generator="record-coverage-history",
        check="review",
        sources=("sim_build/*coverage*.json",),
        purpose="Machine-readable coverage trend history rendered into `docs/coverage-history.md`.",
    ),
    DocumentationEntry(
        path="docs/status/status.json",
        kind="data",
        owner="status",
        generator="export-status",
        check="CI summary",
        sources=("sim_build/", "formal/"),
        purpose="Machine-readable verification status snapshot used to generate status Markdown and badges.",
    ),
)


def rel(path: Path) -> str:
    return path.relative_to(PROJECT_ROOT).as_posix()


def _git_ls_files(pattern: str) -> tuple[str, ...]:
    try:
        result = subprocess.run(
            ["git", "ls-files", pattern],
            cwd=PROJECT_ROOT,
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except (OSError, subprocess.CalledProcessError):
        return tuple(sorted(rel(path) for path in PROJECT_ROOT.glob(pattern)))
    return tuple(line.strip().replace("\\", "/") for line in result.stdout.splitlines() if line.strip())


def tracked_markdown_docs() -> tuple[str, ...]:
    return _git_ls_files("*.md")


def validate_documentation_index() -> list[str]:
    failures: list[str] = []
    entries = DOCUMENTATION
    paths = [entry.path for entry in entries]
    path_set = set(paths)

    if len(paths) != len(path_set):
        failures.append("documentation index contains duplicate paths")

    for entry in entries:
        if entry.path != "docs/documentation-index.md" and not (PROJECT_ROOT / entry.path).exists():
            failures.append(f"{entry.path}: path does not exist")
        if not entry.sources:
            failures.append(f"{entry.path}: must list at least one source")

    tracked_markdown = set(tracked_markdown_docs())
    indexed_markdown = {entry.path for entry in entries if entry.path.endswith(".md")}
    for missing in sorted(tracked_markdown - indexed_markdown):
        failures.append(f"tracked Markdown document missing from index: {missing}")

    generator_names = {entry.name for entry in script_entrypoints()}
    for entry in entries:
        if entry.generator != "-" and entry.generator not in generator_names:
            failures.append(f"{entry.path}: generator `{entry.generator}` is not in the script catalog")

    for entry in entries:
        if entry.kind != "generated":
            continue
        path = PROJECT_ROOT / entry.path
        if path.exists():
            first_line = path.read_text(encoding="utf-8").splitlines()[0]
            if not first_line.startswith("<!-- Generated by scripts/"):
                failures.append(f"{entry.path}: generated docs must start with the generated-file marker")

    readme_text = (PROJECT_ROOT / "README.md").read_text(encoding="utf-8")
    plan_text = (PROJECT_ROOT / "docs" / "verification-plan.md").read_text(encoding="utf-8")
    if "docs/documentation-index.md" not in readme_text:
        failures.append("README.md must link to docs/documentation-index.md")
    if "docs/documentation-index.md" not in plan_text:
        failures.append("docs/verification-plan.md must link to docs/documentation-index.md")

    return failures


def _list_items(values: tuple[str, ...]) -> str:
    return "<br>".join(f"`{value}`" for value in values)


def _kind_count(kind: str) -> int:
    return sum(1 for entry in DOCUMENTATION if entry.kind == kind)


def render_markdown() -> str:
    failures = validate_documentation_index()
    if failures:
        joined = "\n".join(f"- {failure}" for failure in failures)
        raise ValueError(f"documentation index is invalid:\n{joined}")

    lines = [
        "<!-- Generated by scripts/documentation_index.py. Do not edit by hand. -->",
        "",
        "# Documentation Index",
        "",
        "This page is generated from `scripts/documentation_index.py` and checked by the Python-model CI lane.",
        "",
        "## Summary",
        "",
        f"- Indexed paths: {len(DOCUMENTATION)}",
        f"- Manual pages: {_kind_count('manual')}",
        f"- Generated checkable pages: {_kind_count('generated')}",
        f"- Exported report pages: {_kind_count('exported')}",
        f"- Machine-readable data docs: {_kind_count('data')}",
        "",
        "## Suggested Review Path",
        "",
        "1. `README.md`: start here for setup and tutorial flow.",
        "2. `docs/verification-plan.md`: review the verification strategy and current check map.",
        "3. `docs/requirements-traceability.md`: confirm claims are tied to executable evidence.",
        "4. `docs/verification-matrix.md`: inspect lane coverage across simulators, formal, assertions, and artifacts.",
        "5. `docs/artifact-catalog.md`: confirm generated outputs are reviewable locally and in CI.",
        "6. `docs/script-catalog.md`: confirm cross-platform wrappers and implementations stay symmetric.",
        "",
        "## Inventory",
        "",
        "| Path | Kind | Owner | Generator | Freshness check | Sources | Purpose |",
        "|---|---|---|---|---|---|---|",
    ]

    for entry in DOCUMENTATION:
        lines.append(
            "| `{path}` | `{kind}` | `{owner}` | `{generator}` | `{check}` | {sources} | {purpose} |".format(
                path=entry.path,
                kind=entry.kind,
                owner=entry.owner,
                generator=entry.generator,
                check=entry.check,
                sources=_list_items(entry.sources),
                purpose=entry.purpose,
            )
        )

    lines.extend(
        [
            "",
            "Regenerate this page after intentional documentation-map edits with:",
            "",
            "```powershell",
            ".\\scripts\\generate-documentation-index.ps1",
            "```",
            "",
            "```bash",
            "bash scripts/generate-documentation-index.sh",
            "```",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate and check the tutorial documentation index.")
    parser.add_argument("--output", type=Path, default=Path("docs/documentation-index.md"))
    parser.add_argument("--check", action="store_true", help="Fail if the generated output is stale.")
    args = parser.parse_args()

    output_path = (PROJECT_ROOT / args.output).resolve()
    expected = render_markdown()

    if args.check:
        if not output_path.exists():
            print(f"Documentation index is missing: {output_path}", file=sys.stderr)
            raise SystemExit(1)
        actual = output_path.read_text(encoding="utf-8")
        if actual != expected:
            print(
                f"Documentation index is stale: {output_path}. "
                "Regenerate with scripts/generate-documentation-index.*",
                file=sys.stderr,
            )
            raise SystemExit(1)
        print(f"Documentation index is up to date: {args.output}")
        return

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(expected, encoding="utf-8")
    print(f"Wrote {args.output}")


if __name__ == "__main__":
    main()
