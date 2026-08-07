#!/usr/bin/env python3
"""Validate every skills/*/SKILL.md has well-formed frontmatter.

Usage: python3 scripts/validate_skills.py
Exits non-zero if any skill fails validation.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = ROOT / "skills"
KEBAB_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
MAX_DESCRIPTION_LEN = 1024


def parse_frontmatter(text: str) -> dict | None:
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---", 4)
    if end == -1:
        return None
    block = text[4:end]
    fields = {}
    for line in block.splitlines():
        if not line.strip() or line.startswith(" ") or line.startswith("\t"):
            continue
        if ":" not in line:
            continue
        key, _, value = line.partition(":")
        fields[key.strip()] = value.strip()
    return fields


def validate_skill(skill_dir: Path) -> list[str]:
    errors = []
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        return [f"missing SKILL.md"]

    text = skill_md.read_text(encoding="utf-8")
    fields = parse_frontmatter(text)
    if fields is None:
        return ["SKILL.md must start with a '---' frontmatter block"]

    name = fields.get("name")
    description = fields.get("description")

    if not name:
        errors.append("frontmatter missing 'name'")
    elif name != skill_dir.name:
        errors.append(f"name '{name}' does not match folder name '{skill_dir.name}'")
    elif not KEBAB_RE.match(name):
        errors.append(f"name '{name}' is not kebab-case (lowercase, digits, hyphens)")

    if not description:
        errors.append("frontmatter missing 'description'")
    elif len(description) > MAX_DESCRIPTION_LEN:
        errors.append(f"description is {len(description)} chars, keep it under {MAX_DESCRIPTION_LEN}")

    return errors


def main() -> int:
    if not SKILLS_DIR.exists():
        print(f"No skills/ directory found at {SKILLS_DIR}")
        return 1

    skill_dirs = sorted(
        d for d in SKILLS_DIR.iterdir()
        if d.is_dir() and not d.name.startswith(".") and d.name != "_template"
    )

    if not skill_dirs:
        print("No skills found yet (skills/ only contains _template or is empty).")
        return 0

    had_errors = False
    for skill_dir in skill_dirs:
        errors = validate_skill(skill_dir)
        if errors:
            had_errors = True
            print(f"FAIL  {skill_dir.name}")
            for err in errors:
                print(f"        - {err}")
        else:
            print(f"OK    {skill_dir.name}")

    return 1 if had_errors else 0


if __name__ == "__main__":
    sys.exit(main())
