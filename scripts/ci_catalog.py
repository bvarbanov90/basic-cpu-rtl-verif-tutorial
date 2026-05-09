from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
WORKFLOW_PATH = PROJECT_ROOT / ".github" / "workflows" / "ci.yml"

REQUIRED_JOBS = (
    "python-model",
    "native-sim",
    "lint",
    "formal",
    "cocotb-verilator",
    "equivalence",
    "pyuvm",
    "mutations",
    "summary",
)


@dataclass(frozen=True)
class StepInfo:
    name: str
    uses: str | None
    run_commands: tuple[str, ...]
    scripts: tuple[str, ...]
    artifact_name: str | None
    artifact_paths: tuple[str, ...]


@dataclass(frozen=True)
class JobInfo:
    name: str
    runs_on: str | None
    needs: tuple[str, ...]
    if_expr: str | None
    timeout_minutes: str | None
    steps: tuple[StepInfo, ...]

    @property
    def artifact_names(self) -> tuple[str, ...]:
        return tuple(step.artifact_name for step in self.steps if step.artifact_name)

    @property
    def scripts(self) -> tuple[str, ...]:
        seen: list[str] = []
        for step in self.steps:
            for script in step.scripts:
                if script not in seen:
                    seen.append(script)
        return tuple(seen)


@dataclass(frozen=True)
class WorkflowInfo:
    name: str
    workflow_path: str
    oss_cad_suite_release_tag: str | None
    concurrency_group: str | None
    cancel_in_progress: str | None
    jobs: tuple[JobInfo, ...]


def rel(path: Path) -> str:
    return path.relative_to(PROJECT_ROOT).as_posix()


def workflow_text() -> str:
    return WORKFLOW_PATH.read_text(encoding="utf-8")


def _extract_job_blocks(lines: list[str]) -> dict[str, list[str]]:
    jobs_start = next((idx for idx, line in enumerate(lines) if line.strip() == "jobs:"), None)
    if jobs_start is None:
        return {}

    blocks: dict[str, list[str]] = {}
    current_name: str | None = None
    current_block: list[str] = []

    for line in lines[jobs_start + 1 :]:
        match = re.match(r"^  ([A-Za-z0-9_-]+):\s*$", line)
        if match:
            if current_name is not None:
                blocks[current_name] = current_block
            current_name = match.group(1)
            current_block = []
            continue
        if current_name is not None:
            current_block.append(line)

    if current_name is not None:
        blocks[current_name] = current_block

    return blocks


def _field(block: list[str], key: str) -> str | None:
    match = re.search(rf"^    {re.escape(key)}:[ \t]*(.+?)[ \t]*$", "\n".join(block), re.M)
    return match.group(1).strip().strip('"') if match else None


def _list_field(block: list[str], key: str) -> tuple[str, ...]:
    one_line = _field(block, key)
    if one_line:
        return (one_line,)

    values: list[str] = []
    in_field = False
    for line in block:
        if re.match(rf"^    {re.escape(key)}:\s*$", line):
            in_field = True
            continue
        if in_field:
            item = re.match(r"^      -\s+(.+?)\s*$", line)
            if item:
                values.append(item.group(1).strip())
                continue
            if line.startswith("    ") and not line.startswith("      "):
                break
    return tuple(values)


def _extract_step_blocks(job_block: list[str]) -> list[list[str]]:
    step_blocks: list[list[str]] = []
    current: list[str] | None = None

    for line in job_block:
        if re.match(r"^      - name:\s+", line):
            if current is not None:
                step_blocks.append(current)
            current = [line]
            continue
        if current is not None:
            current.append(line)

    if current is not None:
        step_blocks.append(current)

    return step_blocks


def _extract_multiline_after(block: list[str], key: str, indent: int) -> tuple[str, ...]:
    values: list[str] = []
    key_prefix = " " * indent + f"{key}: |"
    for idx, line in enumerate(block):
        if line != key_prefix:
            continue
        for body_line in block[idx + 1 :]:
            if body_line.startswith(" " * (indent + 2)):
                value = body_line[indent + 2 :].rstrip()
                if value:
                    values.append(value)
                continue
            break
        break
    return tuple(values)


def _extract_single_line_after(block: list[str], key: str, indent: int) -> tuple[str, ...]:
    prefix = " " * indent + f"{key}: "
    for line in block:
        if line.startswith(prefix) and line.strip() != f"{key}: |":
            return (line[len(prefix) :].strip(),)
    return ()


def _extract_script_refs(text: str) -> tuple[str, ...]:
    matches = re.findall(r"(scripts/[A-Za-z0-9_.\-/]+(?:\.sh|\.ps1|\.py))", text)
    seen: list[str] = []
    for match in matches:
        if match not in seen:
            seen.append(match)
    return tuple(seen)


def _parse_step(block: list[str]) -> StepInfo:
    text = "\n".join(block)
    name_match = re.search(r"^      - name:\s*(.+?)\s*$", text, re.M)
    uses_match = re.search(r"^        uses:\s*(.+?)\s*$", text, re.M)
    artifact_name_match = re.search(r"^          name:\s*(.+?)\s*$", text, re.M)

    run_commands = _extract_single_line_after(block, "run", indent=8) or _extract_multiline_after(
        block, "run", indent=8
    )
    artifact_paths = _extract_multiline_after(block, "path", indent=10)

    return StepInfo(
        name=name_match.group(1).strip() if name_match else "<unnamed>",
        uses=uses_match.group(1).strip() if uses_match else None,
        run_commands=run_commands,
        scripts=_extract_script_refs(text),
        artifact_name=artifact_name_match.group(1).strip() if artifact_name_match else None,
        artifact_paths=artifact_paths,
    )


def parse_workflow() -> WorkflowInfo:
    text = workflow_text()
    lines = text.splitlines()
    name_match = re.search(r"^name:\s*(.+?)\s*$", text, re.M)
    release_match = re.search(r"^[ \t]+OSS_CAD_SUITE_RELEASE_TAG:[ \t]*\"?([^\"\n]+)\"?[ \t]*$", text, re.M)
    concurrency_group_match = re.search(r"^  group:\s*(.+?)\s*$", text, re.M)
    cancel_match = re.search(r"^  cancel-in-progress:\s*(.+?)\s*$", text, re.M)

    jobs = []
    for name, block in _extract_job_blocks(lines).items():
        jobs.append(
            JobInfo(
                name=name,
                runs_on=_field(block, "runs-on"),
                needs=_list_field(block, "needs"),
                if_expr=_field(block, "if"),
                timeout_minutes=_field(block, "timeout-minutes"),
                steps=tuple(_parse_step(step_block) for step_block in _extract_step_blocks(block)),
            )
        )

    return WorkflowInfo(
        name=name_match.group(1).strip() if name_match else "<unnamed>",
        workflow_path=rel(WORKFLOW_PATH),
        oss_cad_suite_release_tag=release_match.group(1).strip() if release_match else None,
        concurrency_group=concurrency_group_match.group(1).strip() if concurrency_group_match else None,
        cancel_in_progress=cancel_match.group(1).strip() if cancel_match else None,
        jobs=tuple(jobs),
    )


def validate_workflow() -> list[str]:
    workflow = parse_workflow()
    failures: list[str] = []
    job_names = [job.name for job in workflow.jobs]

    for required in REQUIRED_JOBS:
        if required not in job_names:
            failures.append(f"CI workflow missing required job `{required}`")

    extra_jobs = sorted(set(job_names) - set(REQUIRED_JOBS))
    for extra in extra_jobs:
        failures.append(f"CI workflow has undocumented job `{extra}`")

    for job in workflow.jobs:
        if job.runs_on != "ubuntu-latest":
            failures.append(f"{job.name}: expected runs-on ubuntu-latest, found {job.runs_on!r}")
        if not job.steps:
            failures.append(f"{job.name}: has no named steps")
        for script in job.scripts:
            if not (PROJECT_ROOT / script).exists():
                failures.append(f"{job.name}: referenced script does not exist: {script}")
        for step in job.steps:
            if step.uses == "actions/upload-artifact@v4":
                if not step.artifact_name:
                    failures.append(f"{job.name}: upload-artifact step missing artifact name")
                if not step.artifact_paths:
                    failures.append(f"{job.name}: upload-artifact step missing artifact paths")

    summary = next((job for job in workflow.jobs if job.name == "summary"), None)
    if summary:
        expected_needs = tuple(job for job in REQUIRED_JOBS if job != "summary")
        if summary.needs != expected_needs:
            failures.append(
                "summary: needs list must match required non-summary jobs in catalog order "
                f"({summary.needs!r} != {expected_needs!r})"
            )
        if summary.if_expr != "always()":
            failures.append("summary: expected `if: always()`")

    if not workflow.oss_cad_suite_release_tag:
        failures.append("CI workflow must pin OSS_CAD_SUITE_RELEASE_TAG")
    if not workflow.concurrency_group:
        failures.append("CI workflow must define concurrency group")
    elif "${{ github.workflow }}" not in workflow.concurrency_group or "${{ github.ref }}" not in workflow.concurrency_group:
        failures.append("CI concurrency group must include github.workflow and github.ref")
    if workflow.cancel_in_progress != "true":
        failures.append("CI workflow must cancel superseded in-progress runs")

    return failures


def _markdown_list(values: tuple[str, ...], default: str = "-") -> str:
    if not values:
        return default
    return "<br>".join(f"`{value}`" for value in values)


def render_markdown() -> str:
    failures = validate_workflow()
    if failures:
        joined = "\n".join(f"- {failure}" for failure in failures)
        raise ValueError(f"CI catalog is invalid:\n{joined}")

    workflow = parse_workflow()
    artifact_count = sum(len(job.artifact_names) for job in workflow.jobs)

    lines = [
        "<!-- Generated by scripts/ci_catalog.py. Do not edit by hand. -->",
        "",
        "# CI Catalog",
        "",
        "This page is generated from `.github/workflows/ci.yml` and checked by the Python-model CI lane.",
        "",
        "## Summary",
        "",
        f"- Workflow: `{workflow.name}`",
        f"- Workflow file: `{workflow.workflow_path}`",
        "- Trigger scope: pushes and pull requests targeting `main`",
        f"- Pinned OSS CAD Suite release: `{workflow.oss_cad_suite_release_tag}`",
        f"- Concurrency group: `{workflow.concurrency_group}`",
        f"- Cancel superseded in-progress runs: `{workflow.cancel_in_progress}`",
        f"- Jobs: {len(workflow.jobs)}",
        f"- Artifact uploads: {artifact_count}",
        "",
        "## Job Matrix",
        "",
        "| Job | Runner | Needs | Timeout | Script entrypoints | Artifacts |",
        "|---|---|---|---|---|---|",
    ]

    for job in workflow.jobs:
        timeout = f"`{job.timeout_minutes} min`" if job.timeout_minutes else "default"
        lines.append(
            "| `{name}` | `{runner}` | {needs} | {timeout} | {scripts} | {artifacts} |".format(
                name=job.name,
                runner=job.runs_on or "-",
                needs=_markdown_list(job.needs),
                timeout=timeout,
                scripts=_markdown_list(job.scripts),
                artifacts=_markdown_list(job.artifact_names),
            )
        )

    lines.extend(["", "## Steps", ""])
    for job in workflow.jobs:
        lines.extend([f"### `{job.name}`", ""])
        for idx, step in enumerate(job.steps, start=1):
            detail = step.uses or "; ".join(step.run_commands) or "metadata-only"
            lines.append(f"{idx}. {step.name}: `{detail}`")
        lines.append("")

    lines.extend(
        [
            "Regenerate this page after intentional workflow edits with:",
            "",
            "```powershell",
            ".\\scripts\\generate-ci-catalog.ps1",
            "```",
            "",
            "```bash",
            "bash scripts/generate-ci-catalog.sh",
            "```",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate and check the GitHub Actions CI catalog.")
    parser.add_argument("--output", type=Path, default=Path("docs/ci-catalog.md"))
    parser.add_argument("--check", action="store_true", help="Fail if the generated output is stale.")
    args = parser.parse_args()

    output_path = (PROJECT_ROOT / args.output).resolve()
    expected = render_markdown()

    if args.check:
        if not output_path.exists():
            print(f"CI catalog is missing: {output_path}", file=sys.stderr)
            raise SystemExit(1)
        actual = output_path.read_text(encoding="utf-8")
        if actual != expected:
            print(
                f"CI catalog is stale: {output_path}. Regenerate with scripts/generate-ci-catalog.*",
                file=sys.stderr,
            )
            raise SystemExit(1)
        print(f"CI catalog is up to date: {args.output}")
        return

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(expected, encoding="utf-8")
    print(f"Wrote {args.output}")


if __name__ == "__main__":
    main()
