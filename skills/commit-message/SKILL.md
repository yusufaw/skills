---
name: commit-message
description: Generate a commit message from currently staged changes. Use when the user asks to write, generate, or suggest a commit message, or types the command.
disable-model-invocation: true
allowed-tools: Bash(git diff *) Bash(git status *)
---

## Staged diff

!`git diff --staged`

## Staged files

!`git status --short`

## Instructions

Write a commit message for the staged changes shown above.

Rules:
Rules:
- Use Conventional Commits format: `type(scope): summary`
  - types: feat, fix, refactor, chore, docs, test, style, perf
  - scope is optional, use only when it adds clarity (e.g. component or module name)
- Summary line: imperative mood, no period, under 50 characters
- If the diff spans multiple unrelated concerns, add a short body (bullet points) explaining each after a blank line
- If the diff is empty (nothing staged), say so and stop — don't invent a message
- Base the message only on what's actually in the diff, don't guess at unstated intent

Output only the commit message, ready to copy into `git commit -m`.
