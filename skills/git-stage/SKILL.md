---
name: git-stage
description: Stage only files related to the current changes context, skipping unrelated or pre-existing modifications. Use when the user asks to stage related changes, stage for commit, or types /git-stage.
disable-model-invocation: true
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git add *) Bash(git log *) Bash(git ls-files *)
---

## Working tree (staged + unstaged + untracked)

!`git status --short`

## Unstaged diff (vs HEAD)

!`git diff HEAD --stat`

## Staged diff (already staged)

!`git diff --staged --stat`

## Full unstaged patch

!`git diff HEAD`

## Recent commits (for context)

!`git log -n 5 --pretty=format:'%h %s'`

## Instructions

1. Determine the current changes context. Primary source is the conversation: what the user asked for, what was just built/edited, and what the next commit is about. Use the diff and status above as supporting evidence, not as the sole answer.

2. Review `git status --short` and `git diff HEAD` above. Categorize every changed file:
   - `M` / `A` / `??` etc. — note whether it is staged, unstaged, or untracked.
   - For each file, decide if it is **related** to the current context (same feature, same bugfix, same refactor, config/docs/tests directly supporting it) or **unrelated** (different feature, leftover experiment, pre-existing dirty state from before this task).
   - When a file's relation is ambiguous from the diff alone, lean on the conversation topic and file path coherence (e.g. files in the same module touched for this task are related; an unrelated `M` in a distant module from days ago is not).

3. Strict filtering rules — do NOT stage:
   - Any file unrelated to the current context, even if modified.
   - Any modified file that already existed as a dirty change before this task started (pre-existing modifications) unless the conversation explicitly says to include it.
   - Secrets/credentials (`.env`, `*.pem`, `*.key`, `credentials.json`, etc.) — warn and ask before staging.

4. Build an explicit `git add` list containing **only** the related files. Never use `git add -A`, `git add .`, `git add --all`, or `git add -u` — always name the files/paths individually, e.g.:
   ```
   git add -- path/to/file1 path/to/file2 "path with spaces/file3"
   ```
   Quote paths with spaces. For untracked files, `git ls-files --others --exclude-standard` can help confirm they are not ignored, but prefer the explicit list derived in step 2.

5. If no files qualify as related (working tree clean, or all changes are unrelated/pre-existing), say so and stop — do not stage anything. Explain which files were skipped and why.

6. If the selection is ambiguous (e.g. two modules changed and only one matches the conversation), list your proposed `git add` set and ask the user to confirm before running it. Do not guess.

7. Run the explicit `git add -- <files>` for the related set only.

8. Verify with `git status --short` and `git diff --staged --stat` after staging. Report:
   - Which files were staged (related to context, now staged).
   - Which files were intentionally left unstaged/untracked (unrelated or pre-existing) — by name.
   - If any previously staged files were unrelated, leave them as-is and call them out; this skill only adds, it does not unstage unless the user asks.

Never commit, stash, reset, discard, or amend — this skill only stages. Never stage unrelated or pre-existing modifications to piggyback on the current commit.
