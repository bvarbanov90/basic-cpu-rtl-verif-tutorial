from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]


@dataclass(frozen=True)
class FormalTarget:
    name: str
    path: Path
    kind: str
    mode: str
    depth: int
    engine: str
    top: str
    files: tuple[str, ...]


def md_join(values: tuple[str, ...]) -> str:
    return "<br>".join(f"`{value}`" for value in values)


def section_lines(text: str, section: str) -> list[str]:
    in_section = False
    lines: list[str] = []
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            if in_section:
                break
            in_section = line == f"[{section}]"
            continue
        if in_section:
            lines.append(line)
    return lines


def option_value(lines: list[str], key: str) -> str | None:
    prefix = f"{key} "
    for line in lines:
        if line.startswith(prefix):
            return line[len(prefix) :].strip()
    return None


def parse_sby(path: Path) -> FormalTarget:
    text = path.read_text(encoding="utf-8")
    options = section_lines(text, "options")
    engines = section_lines(text, "engines")
    script = section_lines(text, "script")
    files = tuple(section_lines(text, "files"))

    mode = option_value(options, "mode") or ""
    depth_text = option_value(options, "depth") or ""
    engine = engines[0] if engines else ""
    top = ""
    for line in script:
        match = re.fullmatch(r"prep\s+-top\s+([A-Za-z0-9_]+)", line)
        if match:
            top = match.group(1)
            break

    if path.stem.endswith("_cover"):
        kind = "cover"
    elif "fault" in path.stem:
        kind = "fault-prove"
    else:
        kind = "prove"

    depth = int(depth_text) if depth_text.isdigit() else -1
    return FormalTarget(
        name=path.stem,
        path=path,
        kind=kind,
        mode=mode,
        depth=depth,
        engine=engine,
        top=top,
        files=files,
    )


def formal_targets() -> tuple[FormalTarget, ...]:
    return tuple(parse_sby(path) for path in sorted((PROJECT_ROOT / "formal").glob("*.sby")))


def bash_run_formal_targets() -> set[str]:
    text = (PROJECT_ROOT / "scripts" / "linux" / "run-formal.sh").read_text(encoding="utf-8")
    return set(re.findall(r"run_sby\s+(formal/[A-Za-z0-9_]+\.sby)\s+", text))


def powershell_run_formal_targets() -> set[str]:
    text = (PROJECT_ROOT / "scripts" / "windows" / "run-formal.ps1").read_text(encoding="utf-8")
    return set(re.findall(r'Source\s*=\s*"([^"]+\.sby)"', text))


def validate_formal_targets() -> list[str]:
    failures: list[str] = []
    targets = formal_targets()
    if not targets:
        return ["formal catalog: no root-level .sby targets found"]

    names = [target.name for target in targets]
    if len(names) != len(set(names)):
        failures.append("formal catalog: duplicate target names found")

    expected = {f"formal/{target.path.name}" for target in targets}
    bash_targets = bash_run_formal_targets()
    ps_targets = powershell_run_formal_targets()

    for missing in sorted(expected - bash_targets):
        failures.append(f"scripts/linux/run-formal.sh does not list {missing}")
    for extra in sorted(bash_targets - expected):
        failures.append(f"scripts/linux/run-formal.sh lists unknown target {extra}")
    for missing in sorted(expected - ps_targets):
        failures.append(f"scripts/windows/run-formal.ps1 does not list {missing}")
    for extra in sorted(ps_targets - expected):
        failures.append(f"scripts/windows/run-formal.ps1 lists unknown target {extra}")

    for target in targets:
        prefix = f"{target.name}:"
        if target.mode not in {"bmc", "cover"}:
            failures.append(f"{prefix} expected mode bmc or cover, got '{target.mode}'")
        if target.kind == "cover" and target.mode != "cover":
            failures.append(f"{prefix} cover target must use mode cover")
        if target.kind != "cover" and target.mode != "bmc":
            failures.append(f"{prefix} prove target must use mode bmc")
        if target.depth <= 0:
            failures.append(f"{prefix} expected positive depth")
        if not target.engine.startswith("smtbmc "):
            failures.append(f"{prefix} expected smtbmc engine, got '{target.engine}'")
        if not target.top:
            failures.append(f"{prefix} missing prep -top line")
        if not target.files:
            failures.append(f"{prefix} missing [files] entries")

        for source in target.files:
            source_path = PROJECT_ROOT / source
            if not source_path.exists():
                failures.append(f"{prefix} missing file entry {source}")

    return failures


def render_markdown() -> str:
    failures = validate_formal_targets()
    if failures:
        joined = "\n".join(f"- {failure}" for failure in failures)
        raise ValueError(f"formal target catalog is invalid:\n{joined}")

    targets = formal_targets()
    kind_counts = {
        kind: sum(1 for target in targets if target.kind == kind)
        for kind in ("prove", "fault-prove", "cover")
    }

    lines = [
        "<!-- Generated by scripts/formal_catalog.py. Do not edit by hand. -->",
        "",
        "# Formal Target Catalog",
        "",
        "This page is generated from root-level `formal/*.sby` targets and checked by the Python-model CI lane.",
        "",
        "## Summary",
        "",
        f"- Total targets: {len(targets)}",
        "- Kinds: " + ", ".join(f"`{kind}`={count}" for kind, count in kind_counts.items()),
        f"- Max proof/cover depth: {max(target.depth for target in targets)}",
        "",
        "## Targets",
        "",
        "| Target | Kind | Mode | Depth | Engine | Top | Files |",
        "|---|---|---|---|---|---|---|",
    ]

    for target in targets:
        lines.append(
            "| `{name}` | `{kind}` | `{mode}` | {depth} | `{engine}` | `{top}` | {files} |".format(
                name=f"formal/{target.path.name}",
                kind=target.kind,
                mode=target.mode,
                depth=target.depth,
                engine=target.engine,
                top=target.top,
                files=md_join(target.files),
            )
        )

    lines.extend(
        [
            "",
            "Regenerate this page after intentional formal-target edits with:",
            "",
            "```powershell",
            ".\\scripts\\generate-formal-catalog.ps1",
            "```",
            "",
            "```bash",
            "bash scripts/generate-formal-catalog.sh",
            "```",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate and check the formal target catalog.")
    parser.add_argument("--output", type=Path, default=Path("docs/formal-targets.md"))
    parser.add_argument("--check", action="store_true", help="Fail if the generated output is stale.")
    args = parser.parse_args()

    output_path = (PROJECT_ROOT / args.output).resolve()
    expected = render_markdown()

    if args.check:
        if not output_path.exists():
            print(f"Formal target catalog is missing: {output_path}", file=sys.stderr)
            raise SystemExit(1)
        actual = output_path.read_text(encoding="utf-8")
        if actual != expected:
            print(
                f"Formal target catalog is stale: {output_path}. "
                "Regenerate with scripts/generate-formal-catalog.*",
                file=sys.stderr,
            )
            raise SystemExit(1)
        print(f"Formal target catalog is up to date: {args.output}")
        return

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(expected, encoding="utf-8")
    print(f"Wrote {args.output}")


if __name__ == "__main__":
    main()
