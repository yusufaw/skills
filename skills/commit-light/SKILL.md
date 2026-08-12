---
name: commit-light
description: Commit the currently staged files with a bare single-line commit message — no body/description and no Co-Authored-By trailer. Use when the user asks for a light, minimal, or bare commit of what's staged, or types the command.
disable-model-invocation: true
allowed-tools: Bash(git diff *) Bash(git status *) Bash(git log *) Bash(git commit *)
---

## Staged diff

!`git diff --staged`

## Staged files

!`git status --short`

## Recent commit messages (for style)

!`git log -n 5 --pretty=format:%s`

## Instructions

1. Review the staged diff above. If nothing is staged, say so and stop — don't
   stage anything or invent a message. Unstaged and untracked changes are not
   part of this commit; leave them alone.
2. Check for staged files that likely contain secrets (`.env`, credentials,
   keys, etc.). If any are present, warn the user and ask before committing.
3. Draft a commit message covering only the staged changes:
   - Conventional Commits format: `type(scope): summary`
     - types: feat, fix, refactor, chore, docs, test, style, perf
     - scope is optional, use only when it adds clarity
   - Summary line only: imperative mood, no period, under 50 characters
   - Never add a body, bullet points, or any other description — one line,
     nothing else
   - Never add a `Co-Authored-By` trailer or any other trailer
   - Base the message only on what's actually in the diff, don't guess at
     unstated intent
   - Match the style of the recent commit messages above where sensible
4. Create the commit with the drafted single-line message, e.g.:
   ```
   git commit -m "<message>"
   ```
   Never pass `-a`/`--all` or stage additional files.
5. Run `git status` after committing to confirm success, and mention if
   unstaged or untracked changes remain.

Never amend an existing commit, never force-push, and never push to a
remote — this skill only commits locally. Do not skip hooks (`--no-verify`)
unless the user explicitly asks. If a pre-commit hook fails, fix the
underlying issue, re-stage the fix, and create a new commit rather than
bypassing it.
