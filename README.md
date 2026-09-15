# skills

Personal collection of skills for [Codex](https://developers.openai.com/codex/)
and [Claude Code](https://claude.com/product/claude-code).

Each skill is a self-contained folder under `skills/` with a `SKILL.md` that tells
the agent when to use it and what to do. This repo is meant to be grown incrementally —
add a skill whenever you notice yourself giving the agent the same instructions twice.

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
   - Fill in the instructions the agent should follow once the skill loads.
3. Validate:
   ```
   python3 scripts/validate_skills.py
   ```

## Using this collection with Codex

### Install for all your projects (recommended)

Run these commands in your terminal from the root of this repository. They link
each skill into `~/.agents/skills`, making it available to Codex sessions running
under your user account across projects on this computer.

```sh
skill_source="$(pwd)/skills"
skill_destination="$HOME/.agents/skills"
mkdir -p "$skill_destination"

for skill in "$skill_source"/*; do
  [ -f "$skill/SKILL.md" ] || continue
  skill_name="${skill##*/}"
  [ "$skill_name" = "_template" ] && continue
  target="$skill_destination/$skill_name"
  if [ -e "$target" ] || [ -L "$target" ]; then
    printf 'Skipping existing skill: %s\n' "$target"
    continue
  fi
  ln -s "$skill" "$target"
done
```

The command skips `_template` and preserves existing destinations. Symlinks keep
edits to installed skills in sync with this checkout. Keep the repository at the
same location; moving or deleting it breaks the links. Run the loop again after
adding new skill folders.

### Install for one project only

Use the same commands above, but replace the `skill_destination` line with:

```sh
skill_destination="/absolute/path/to/your/project/.agents/skills"
```

Replace the example path with the project where you want to use the skills.
Choose either user-level or project-level installation to avoid duplicate entries.

### Use and verify

In Codex CLI, run `/skills` or type `$` to select an installed skill. For example:

```text
$commit-message
```

Codex detects skill changes automatically. If skills do not appear, restart Codex
and check that the links resolve to a folder containing `SKILL.md`:

```sh
ls -l ~/.agents/skills
cat ~/.agents/skills/commit-message/SKILL.md
```

For a project-only installation, check that project's `.agents/skills` instead.
Some skills require additional tools or connected services; see their `SKILL.md`
for requirements.

See the [official Codex skills documentation](https://learn.chatgpt.com/docs/build-skills#where-codex-loads-local-skills)
for discovery locations and supported behavior.

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
