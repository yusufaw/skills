---
name: commit-all
description: Stage every working tree change (git add -A) and commit it, generating the commit message the same way /commit-message-all does. Use when the user asks to add all changes and commit, commit everything, or types the command.
disable-model-invocation: true
allowed-tools: Bash(git diff *) Bash(git status *) Bash(git log *) Bash(git add *) Bash(git commit *)
---

## Full diff (staged + unstaged)

!`git diff HEAD`

## All changed files

!`git status --short`

## Recent commit messages (for style)

!`git log -n 5 --pretty=format:%s`

## Instructions

1. Review the diff and file list above. If the working tree is clean (no
   changes at all, tracked or untracked), say so and stop — don't stage or
   commit anything.
2. Check for files that likely contain secrets (`.env`, credentials, keys,
   etc.). If any are present among the changes, warn the user and ask before
   including them.
3. Draft a commit message covering every change shown above — both staged
   and unstaged, and untracked files by name (their contents won't be in the
   diff since they aren't tracked yet). Follow the same rules as
   `/commit-message-all`:
   - Conventional Commits format: `type(scope): summary`
     - types: feat, fix, refactor, chore, docs, test, style, perf
     - scope is optional, use only when it adds clarity
   - Summary line: imperative mood, no period, under 50 characters
   - If the diff spans multiple unrelated concerns, add a short concise body
     (bullet points) after a blank line — keep it to 2-3 short bullets max,
     no lengthy paragraphs
   - Base the message only on what's actually changed, don't guess at
     unstated intent
   - Match the style of the recent commit messages above where sensible
   - Never add `Co-Authored-By`, `Claude-Session`, or any other trailer/metadata
4. Run `git add -A` to stage everything, then create the commit with the
   drafted message via a HEREDOC, e.g.:
   ```
   git commit -m "$(cat <<'EOF'
   <message>
   EOF
   )"
   ```
5. Run `git status` after committing to confirm success.

Never amend an existing commit, never force-push, and never push to a
remote — this skill only stages and commits locally. Do not skip hooks
(`--no-verify`) unless the user explicitly asks. If a pre-commit hook fails,
fix the underlying issue, re-stage, and create a new commit rather than
bypassing it.
