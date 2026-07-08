#!/usr/bin/env python3
"""Vendor external Agent Skills listed in external-skills.json."""

from __future__ import annotations

import json
import shutil
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "external-skills.json"
README = ROOT / "README.md"
START_MARKER = "<!-- skills:index:start -->"
END_MARKER = "<!-- skills:index:end -->"


def run(command: list[str], cwd: Path | None = None) -> str:
    result = subprocess.run(
        command,
        cwd=cwd,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return result.stdout.strip()


def load_manifest() -> list[dict[str, str]]:
    with MANIFEST.open(encoding="utf-8") as file:
        entries = json.load(file)

    if not isinstance(entries, list):
        raise ValueError(f"{MANIFEST} must contain a JSON array")

    required_fields = {"name", "repo", "ref", "sourcePath", "targetPath"}
    for index, entry in enumerate(entries):
        if not isinstance(entry, dict):
            raise ValueError(f"Entry {index} must be an object")
        missing = required_fields.difference(entry)
        if missing:
            missing_fields = ", ".join(sorted(missing))
            raise ValueError(f"Entry {index} is missing: {missing_fields}")

    return entries


def assert_inside_repo(path: Path) -> None:
    resolved = path.resolve()
    if ROOT.resolve() not in (resolved, *resolved.parents):
        raise ValueError(f"Refusing to write outside repository: {path}")


def clone_repo(repo: str, ref: str, checkout: Path) -> None:
    try:
        run(["git", "clone", "--depth", "1", "--branch", ref, repo, str(checkout)])
    except subprocess.CalledProcessError:
        run(["git", "clone", "--depth", "1", repo, str(checkout)])
        run(["git", "fetch", "--depth", "1", "origin", ref], cwd=checkout)
        run(["git", "checkout", "--detach", "FETCH_HEAD"], cwd=checkout)


def sync_entry(entry: dict[str, str], temp_root: Path) -> None:
    checkout = temp_root / entry["name"]
    clone_repo(entry["repo"], entry["ref"], checkout)

    source = checkout / entry["sourcePath"]
    if not (source / "SKILL.md").is_file():
        raise FileNotFoundError(f"{source} does not contain SKILL.md")

    target = ROOT / entry["targetPath"]
    assert_inside_repo(target)

    if target.exists():
        shutil.rmtree(target)
    shutil.copytree(source, target, ignore=shutil.ignore_patterns(".git", "__pycache__"))

    commit = run(["git", "rev-parse", "HEAD"], cwd=checkout)
    source_metadata = {
        "name": entry["name"],
        "repo": entry["repo"],
        "ref": entry["ref"],
        "sourcePath": entry["sourcePath"],
        "targetPath": entry["targetPath"],
        "commit": commit,
    }
    with (target / ".source.json").open("w", encoding="utf-8") as file:
        json.dump(source_metadata, file, indent=2)
        file.write("\n")


def parse_frontmatter(skill_file: Path) -> dict[str, str]:
    lines = skill_file.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0] != "---":
        return {}

    metadata: dict[str, str] = {}
    for line in lines[1:]:
        if line == "---":
            break
        if ":" not in line or line.startswith(" "):
            continue
        key, value = line.split(":", 1)
        metadata[key.strip()] = value.strip().strip('"')
    return metadata


def discover_skills() -> list[tuple[str, str, Path]]:
    skills: list[tuple[str, str, Path]] = []
    for skill_file in ROOT.rglob("SKILL.md"):
        if ".git" in skill_file.parts:
            continue
        metadata = parse_frontmatter(skill_file)
        name = metadata.get("name") or skill_file.parent.name
        description = metadata.get("description", "")
        skills.append((name, description, skill_file.parent.relative_to(ROOT)))
    return sorted(skills, key=lambda skill: skill[0])


def render_skill_index() -> str:
    skills = discover_skills()
    lines = [
        START_MARKER,
        f"## Included skills ({len(skills)})",
        "",
    ]
    for name, description, path in skills:
        suffix = f" - {description}" if description else ""
        lines.append(f"- [`{name}`](./{path}/SKILL.md){suffix}")
    lines.extend(["", END_MARKER])
    return "\n".join(lines)


def update_readme() -> None:
    if not README.exists():
        return

    content = README.read_text(encoding="utf-8")
    replacement = render_skill_index()
    if START_MARKER in content and END_MARKER in content:
        before, marker_and_rest = content.split(START_MARKER, 1)
        _old_block, after = marker_and_rest.split(END_MARKER, 1)
        content = f"{before}{replacement}{after}"
    else:
        heading, rest = content.split("\n", 1)
        content = f"{heading}\n\n{replacement}\n\n{rest.lstrip()}"
    README.write_text(content, encoding="utf-8")


def main() -> None:
    entries = load_manifest()
    with tempfile.TemporaryDirectory(prefix="skills-sync-") as temp_dir:
        temp_root = Path(temp_dir)
        for entry in entries:
            sync_entry(entry, temp_root)
    update_readme()


if __name__ == "__main__":
    main()
