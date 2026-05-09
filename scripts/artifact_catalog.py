from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from scripts.ci_catalog import parse_workflow
from scripts.verification_matrix import LANES

SHOW_HELPERS = {
    "sim_build/coverage.json": "show-coverage",
    "sim_build/pyuvm_coverage.json": "show-pyuvm-coverage",
    "sim_build/mmio_coverage.json": "show-mmio-coverage",
    "sim_build/mmio_wait_coverage.json": "show-mmio-wait-coverage",
    "sim_build/apb_coverage.json": "show-apb-coverage",
    "sim_build/apb_fault_coverage.json": "show-apb-fault-coverage",
    "sim_build/wishbone_coverage.json": "show-wishbone-coverage",
    "sim_build/wishbone_fault_coverage.json": "show-wishbone-fault-coverage",
    "sim_build/axi_lite_coverage.json": "show-axi-lite-coverage",
    "sim_build/axi_lite_fault_coverage.json": "show-axi-lite-fault-coverage",
    "sim_build/verilator_coverage/summary.json": "show-verilator-coverage",
    "sim_build/mutations": "show-mutations",
    "docs/coverage-history.json": "show-coverage-trend",
}

EXTRA_ARTIFACTS = (
    ("Mutation campaign workdir", "sim_build/mutations", "mutations", "Representative broken-RTL campaign results."),
    ("pyuvm coverage report", "sim_build/pyuvm_coverage.json", "pyuvm", "Core pyuvm subscriber coverage report."),
    ("Status export", "docs/status/status.json", "status", "Repo-tracked verification status export."),
    ("Coverage history", "docs/coverage-history.json", "status", "Repo-tracked coverage trend history."),
)


@dataclass(frozen=True)
class ArtifactEntry:
    name: str
    path: str
    category: str
    producer: str
    ci_artifact: str | None
    show_helper: str | None
    note: str


def workflow_upload_map() -> dict[str, str]:
    uploads: dict[str, str] = {}
    workflow = parse_workflow()
    for job in workflow.jobs:
        for step in job.steps:
            if not step.artifact_name:
                continue
            for path in step.artifact_paths:
                uploads[path] = step.artifact_name
    return uploads


def _ci_artifact_for(path: str, uploads: dict[str, str]) -> str | None:
    best_match: tuple[int, str] | None = None
    for upload_path, artifact_name in uploads.items():
        if path == upload_path or path.startswith(f"{upload_path.rstrip('/')}/"):
            score = len(upload_path)
            if best_match is None or score > best_match[0]:
                best_match = (score, artifact_name)
    return best_match[1] if best_match else None


def _category_for(path: str) -> str:
    if path.endswith(".xml"):
        return "results"
    if "coverage" in path and (path.endswith(".json") or path.endswith(".csv") or "/coverage" in path):
        return "coverage"
    if path.startswith("formal/"):
        return "formal"
    if "mutations" in path:
        return "mutations"
    if path.startswith("docs/"):
        return "status"
    return "artifact"


def _show_helper_for(path: str) -> str | None:
    if path in SHOW_HELPERS:
        return SHOW_HELPERS[path]
    if path.startswith("formal/"):
        return "show-formal-status"
    if path.endswith(".csv"):
        json_peer = path[:-4] + ".json"
        return SHOW_HELPERS.get(json_peer)
    return None


def artifact_entries() -> tuple[ArtifactEntry, ...]:
    uploads = workflow_upload_map()
    entries: list[ArtifactEntry] = []

    for lane in LANES:
        for path in lane.artifacts:
            entries.append(
                ArtifactEntry(
                    name=f"{lane.key} {Path(path).name}",
                    path=path,
                    category=_category_for(path),
                    producer=lane.key,
                    ci_artifact=_ci_artifact_for(path, uploads),
                    show_helper=_show_helper_for(path),
                    note=lane.title,
                )
            )
        for target in lane.formal_targets:
            workdir = target[:-4] if target.endswith(".sby") else target
            entries.append(
                ArtifactEntry(
                    name=f"{lane.key} {Path(workdir).name}",
                    path=workdir,
                    category="formal",
                    producer=lane.key,
                    ci_artifact=_ci_artifact_for(workdir, uploads),
                    show_helper=_show_helper_for(workdir),
                    note=f"{lane.title} formal workdir",
                )
            )

    for name, path, producer, note in EXTRA_ARTIFACTS:
        entries.append(
            ArtifactEntry(
                name=name,
                path=path,
                category=_category_for(path),
                producer=producer,
                ci_artifact=_ci_artifact_for(path, uploads),
                show_helper=_show_helper_for(path),
                note=note,
            )
        )

    unique: dict[str, ArtifactEntry] = {}
    for entry in entries:
        unique[entry.path] = entry
    return tuple(sorted(unique.values(), key=lambda entry: (entry.category, entry.path)))


def validate_artifact_catalog() -> list[str]:
    failures: list[str] = []
    entries = artifact_entries()

    if not entries:
        failures.append("artifact catalog has no entries")

    paths = [entry.path for entry in entries]
    if len(paths) != len(set(paths)):
        failures.append("artifact catalog contains duplicate paths")

    for entry in entries:
        if entry.path.startswith("sim_build/") and not entry.ci_artifact:
            failures.append(f"{entry.path}: simulation artifact is not covered by a CI upload path")
        if entry.path.startswith("formal/") and not entry.ci_artifact:
            failures.append(f"{entry.path}: formal artifact is not covered by a CI upload path")
        if entry.show_helper:
            for suffix in (".ps1", ".sh"):
                if suffix == ".ps1":
                    rel = f"scripts/{entry.show_helper}.ps1"
                else:
                    rel = f"scripts/{entry.show_helper}.sh"
                if not (PROJECT_ROOT / rel).exists():
                    failures.append(f"{entry.path}: missing show helper wrapper `{rel}`")

    coverage_json = [entry for entry in entries if entry.category == "coverage" and entry.path.endswith(".json")]
    for entry in coverage_json:
        if not entry.show_helper:
            failures.append(f"{entry.path}: coverage JSON artifact should have a show helper")

    return failures


def _md(value: str | None, default: str = "-") -> str:
    return f"`{value}`" if value else default


def render_markdown() -> str:
    failures = validate_artifact_catalog()
    if failures:
        joined = "\n".join(f"- {failure}" for failure in failures)
        raise ValueError(f"artifact catalog is invalid:\n{joined}")

    entries = artifact_entries()
    categories = sorted({entry.category for entry in entries})

    lines = [
        "<!-- Generated by scripts/artifact_catalog.py. Do not edit by hand. -->",
        "",
        "# Artifact Catalog",
        "",
        "This page is generated from `scripts/verification_matrix.py` and `.github/workflows/ci.yml`.",
        "",
        "## Summary",
        "",
        f"- Artifacts tracked: {len(entries)}",
        "- Categories: " + ", ".join(f"`{category}`" for category in categories),
        "- CI upload coverage is checked for generated `sim_build/` and `formal/` outputs.",
        "",
        "## Artifacts",
        "",
        "| Artifact | Category | Producer | CI upload | Show helper | Note |",
        "|---|---|---|---|---|---|",
    ]

    for entry in entries:
        lines.append(
            "| {path} | `{category}` | `{producer}` | {ci_artifact} | {show_helper} | {note} |".format(
                path=_md(entry.path),
                category=entry.category,
                producer=entry.producer,
                ci_artifact=_md(entry.ci_artifact),
                show_helper=_md(entry.show_helper),
                note=entry.note,
            )
        )

    lines.extend(
        [
            "",
            "Regenerate this page after intentional artifact or CI upload edits with:",
            "",
            "```powershell",
            ".\\scripts\\generate-artifact-catalog.ps1",
            "```",
            "",
            "```bash",
            "bash scripts/generate-artifact-catalog.sh",
            "```",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate and check the verification artifact catalog.")
    parser.add_argument("--output", type=Path, default=Path("docs/artifact-catalog.md"))
    parser.add_argument("--check", action="store_true", help="Fail if the generated output is stale.")
    args = parser.parse_args()

    output_path = (PROJECT_ROOT / args.output).resolve()
    expected = render_markdown()

    if args.check:
        if not output_path.exists():
            print(f"Artifact catalog is missing: {output_path}", file=sys.stderr)
            raise SystemExit(1)
        actual = output_path.read_text(encoding="utf-8")
        if actual != expected:
            print(
                f"Artifact catalog is stale: {output_path}. "
                "Regenerate with scripts/generate-artifact-catalog.*",
                file=sys.stderr,
            )
            raise SystemExit(1)
        print(f"Artifact catalog is up to date: {args.output}")
        return

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(expected, encoding="utf-8")
    print(f"Wrote {args.output}")


if __name__ == "__main__":
    main()
