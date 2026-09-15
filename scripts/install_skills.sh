#!/bin/sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
skill_source="$repo_root/skills"
skill_destination=${1:-"$HOME/.agents/skills"}

mkdir -p "$skill_destination"

for skill in "$skill_source"/*; do
  [ -f "$skill/SKILL.md" ] || continue

  skill_name=${skill##*/}
  [ "$skill_name" = "_template" ] && continue

  target="$skill_destination/$skill_name"
  if [ -e "$target" ] || [ -L "$target" ]; then
    printf 'Skipping existing skill: %s\n' "$target"
    continue
  fi

  ln -s "$skill" "$target"
  printf 'Installed skill: %s\n' "$skill_name"
done
