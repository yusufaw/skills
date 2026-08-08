---
name: git-push
description: Push the current branch to its remote. Use when the user asks to push, push the branch, push to origin, or types the command.
disable-model-invocation: true
allowed-tools: Bash(git status *) Bash(git branch *) Bash(git push *)
---

## Current branch

!`git branch --show-current`

## Status (includes ahead/behind vs. upstream, if any)

!`git status --short --branch`

## Instructions

1. Read the branch header line from the status output above (e.g.
   `## main...origin/main [ahead 2]`). If there's no `[ahead N]` (or the line
   has no `...remote` at all and there's nothing to push), say so and stop.
2. If the header shows no upstream (no `...origin/<branch>` part), push with
   `git push -u origin <current-branch>` to set it up. Otherwise just run
   `git push`.
3. If the current branch is `main` or `master`, pause and confirm with the
   user before pushing.
4. Report the result. If the push is rejected (e.g. remote has diverged),
   explain why and let the user decide how to reconcile — don't force-push.

Never use `--force` or `--force-with-lease` unless the user explicitly asks
for it in this request, and warn them of the consequences (overwriting
remote history) before doing so.
