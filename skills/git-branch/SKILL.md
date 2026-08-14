---
name: git-branch
description: Name a new git branch after whatever this conversation has been working on, then switch to it. Use when the user asks to create a branch, start a branch for this work, branch off, or types the command.
disable-model-invocation: true
allowed-tools: Bash(git branch *) Bash(git status *) Bash(git log *) Bash(git diff *) Bash(git switch *) Bash(git rev-parse *)
---

## Current branch

!`git branch --show-current`

## Working tree

!`git status --short --branch`

## Existing branches (for naming style and collisions)

!`git branch --all --sort=-committerdate --format='%(refname:short)' | head -n 25`

## Recent commit subjects (for naming style)

!`git log -n 5 --pretty=format:%s`

## Uncommitted changes

!`git diff --stat HEAD`

## Instructions

1. Work out what this branch is for. The conversation is the primary source:
   what the user asked for, what they have been iterating on, what is about to
   be built. Use the uncommitted changes above as supporting evidence, not as
   the answer — a branch created before any code is written still needs a good
   name.
2. If the conversation gives you nothing to go on and the working tree is
   clean, ask the user what the branch is for and stop. Do not invent a name.
3. Draft the branch name:
   - Look at the existing branches above and follow whatever pattern is
     already in use in this repo. Only if there is no clear pattern, default to
     `type/short-summary`, with type one of `feat`, `fix`, `refactor`, `chore`,
     `docs`, `test`, `perf`.
   - Lowercase kebab-case, three to five words in the summary. Drop filler
     words like "the", "a", "and", "for".
   - Name the work, not the mechanics: `feat/trello-card-skill`, not
     `feat/add-new-file` or `feat/update-skill-md`.
   - No spaces, no uppercase, no trailing slash or dot, nothing git rejects.
4. Check the drafted name against the existing branch list. If it is already
   taken, distinguish it with another meaningful word rather than a number
   suffix.
5. Decide where to branch from and say so in your reply:
   - Default to the current HEAD, so uncommitted work carries over.
   - If the current branch is not the default branch and its commits are
     unrelated to this work, point that out and confirm with the user before
     creating the branch on top of it.
6. Create and switch in one step:
   ```
   git switch -c <branch-name>
   ```
   If `git switch` is unavailable, fall back to `git checkout -b <branch-name>`.
7. Run `git status --short --branch` afterwards to confirm the switch, and
   report the new branch name and what it was branched from.

Never commit, stash, discard, or reset anything — this skill only creates a
branch and switches to it, carrying any uncommitted work along untouched. If
the switch fails because of a conflict with local changes, report the error and
let the user decide; do not force the switch or move their work aside.
