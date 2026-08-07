# skills

Personal collection of [Claude Code](https://claude.com/product/claude-code) skills.

Each skill is a self-contained folder under `skills/` with a `SKILL.md` that tells
Claude when to use it and what to do. This repo is meant to be grown incrementally —
add a skill whenever you notice yourself giving Claude the same instructions twice.

## Layout

```
skills/
  _template/          starting point for new skills, copy and rename this
  your-skill-name/
    SKILL.md           required: frontmatter (name, description) + instructions
    references/        optional: longer docs the skill points to instead of inlining
    scripts/            optional: helper scripts the skill invokes
scripts/
  validate_skills.py   checks every SKILL.md has valid frontmatter
```

## Adding a new skill

1. Copy the template:
   ```
   cp -r skills/_template skills/your-skill-name
   ```
2. Edit `skills/your-skill-name/SKILL.md`:
   - Set `name:` to match the folder name exactly (kebab-case).
   - Write `description:` as the trigger condition — be specific about when this
     skill should fire, since that's what gets matched against.
   - Fill in the instructions Claude should follow once the skill loads.
3. Validate:
   ```
   python3 scripts/validate_skills.py
   ```

## Using this collection with Claude Code

To make these skills available to Claude Code, symlink (or point Claude Code's
skill discovery config at) the `skills/` folder here, e.g.:

```
ln -s "$(pwd)/skills" ~/.claude/skills
```

Adjust to however your Claude Code setup discovers skills (global vs. per-project).

## Validating

```
python3 scripts/validate_skills.py
```

Checks, for every skill folder (except `_template`):
- `SKILL.md` exists and starts with a `---` frontmatter block
- `name` is present, kebab-case, and matches the folder name
- `description` is present and reasonably concise
