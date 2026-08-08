---
name: git-push
description: Push the current branch to its remote. Use when the user asks to push, push the branch, push to origin, or types the command.
disable-model-invocation: true
allowed-tools: Bash(git status *) Bash(git branch *) Bash(git rev-parse *) Bash(git log *) Bash(git push *)
---

## Current branch

!`git branch --show-current`

## Status

!`git status --short --branch`

## Commits not yet on the remote

!`git log @{u}.. --oneline 2>/dev/null || echo "no upstream configured for this branch"`

## Instructions

1. Confirm there's something to push. If the branch has no commits ahead of
   its upstream (or the working tree is clean and already in sync), say so
   and stop.
2. If the current branch has no upstream configured (see the section above),
   push with `git push -u origin <current-branch>` to set it up. Otherwise
   just run `git push`.
3. If the current branch is `main` or `master`, pause and confirm with the
   user before pushing.
4. Report the result. If the push is rejected (e.g. remote has diverged),
   explain why and let the user decide how to reconcile — don't force-push.

Never use `--force` or `--force-with-lease` unless the user explicitly asks
for it in this request, and warn them of the consequences (overwriting
remote history) before doing so.
