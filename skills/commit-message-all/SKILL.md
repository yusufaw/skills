---
name: commit-message-all
description: Generate a commit message from all working tree changes (staged and unstaged), not just what's staged. Use when the user asks to write, generate, or suggest a commit message covering all changes, or types the command.
disable-model-invocation: true
allowed-tools: Bash(git diff *) Bash(git status *)
---

## Full diff (staged + unstaged)

!`git diff HEAD`

## All changed files

!`git status --short`

## Instructions

Write a commit message covering every change shown above — both staged and
unstaged. Untracked files appear in the file list (`??`) but their contents
aren't in the diff since they aren't tracked yet; mention them by name if
relevant.

Rules:
- Use Conventional Commits format: `type(scope): summary`
  - types: feat, fix, refactor, chore, docs, test, style, perf
  - scope is optional, use only when it adds clarity (e.g. component or module name)
- Summary line: imperative mood, no period, under 50 characters
- If the diff spans multiple unrelated concerns, add a short body (bullet points) explaining each after a blank line
- If there are no changes at all (clean working tree, nothing untracked), say so and stop — don't invent a message
- Base the message only on what's actually changed, don't guess at unstated intent

Output only the commit message, ready to copy into `git commit -m`. Remind the
user this covers unstaged changes too, so they should `git add -A` (or the
relevant files) before committing if they want everything shown here included.
