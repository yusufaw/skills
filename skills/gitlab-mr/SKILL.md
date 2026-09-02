---
name: gitlab-mr
description: Create a GitLab merge request with glab, auto-filling Trello Title and Trello URL from Notion and generating a meaningful MR title. Use when the user asks to create an MR, open a merge request on GitLab, or says /gitlab-mr, /create-mr.
---

## Current branch

!`git branch --show-current`

## Remote and target branch

!`git remote -v | head -20`
!`git status --short --branch`
!`base=$(git merge-base HEAD origin/development 2>/dev/null || git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD origin/master 2>/dev/null); if [ -n "$base" ]; then echo "Base: $base"; git log --oneline "$base"..HEAD | head -20; else echo "(no base found)"; git log -n 10 --oneline | head -20; fi`

## Changes in this MR

!`base=$(git merge-base HEAD origin/development 2>/dev/null || git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD origin/master 2>/dev/null); if [ -n "$base" ]; then git diff --stat "$base"...HEAD | head -50; else git diff --stat HEAD | head -50; fi`

## glab auth status

!`glab auth status 2>&1 | head -20; echo "---"; glab --version 2>&1 | head -5`

# GitLab MR — Create Merge Request with Trello from Notion via glab

You create a GitLab Merge Request using `glab` with a meaningful title and a description that always contains Trello metadata sourced from Notion.

## Pre-flight checks

1. Verify `glab` is installed: `glab --version`. If missing, tell the user to install it (`brew install glab` or https://gitlab.com/gitlab-org/cli) and stop.
2. Verify `glab` is authenticated: `glab auth status`. If not authenticated, run `glab auth login` or tell the user to authenticate and stop.
3. Verify current directory is a git repo with a GitLab remote (`git remote -v` should contain `gitlab.com` or self-hosted GitLab). If `origin` is GitHub or missing, warn and ask for the correct remote.
4. Get current branch: `git branch --show-current`. If on `main`/`master`/`development`, warn and confirm — MR source should be a feature branch. Do not create an MR from a protected branch without explicit confirmation.
5. Determine target branch: prefer `origin/development` if it exists, else `origin/main`, else `origin/master`. Check with `git branch -r | grep -E 'origin/(development|main|master)'`. Allow user to override via explicit instruction.
6. Check if local branch is pushed: `git status --short --branch` — look for `ahead` or `no upstream`. If not pushed or no upstream, push first: `git push -u origin <branch>`. Confirm before pushing if needed.

## Step 1 — Get Trello Title and Trello URL from Notion

This is required. The MR description MUST contain both fields sourced from Notion. Do not invent them.

Try in order:

1. **MCP / Notion integration (preferred if available):** If a Notion MCP server or `notion` tool is available, search Notion for a page matching the current branch name, recent commit messages, or any task ID in the branch (e.g. `feat/PROJ-123-...`). Look for properties/fields named `Trello Title`, `Trello URL`, `Trello Link`, `Card Title`, `Card URL` or similar. Extract their values.
2. **Notion API via `curl` (if `NOTION_TOKEN`/`NOTION_API_KEY` env is set):** Query `https://api.notion.com/v1/search` or `v1/databases/{id}/query` with `Authorization: Bearer $NOTION_TOKEN` and `Notion-Version: 2022-06-28`. Parse the response for a page whose title or property matches the branch/task. Extract `Trello Title` and `Trello URL`.
3. **Ask the user:** If no MCP/API is configured or no match is found, ask the user for:
   - The Notion page URL or page ID that contains the task, OR
   - Directly the Trello Title and Trello URL to use (and offer to save the Notion link for next time).

   Prompt example: "I couldn't find the Notion page automatically. Please paste the Notion page URL (or just the Trello Title and Trello URL if you have them handy)."

4. **Fallback scraping (if user provides Notion URL but no API):** Use `curl` or `npx notion` helper to fetch the page content if possible, otherwise ask the user to copy the two values from the Notion page.

Validation:
- `Trello Title` should be a non-empty human-readable title (e.g. "Fix checkout race condition" — copy exactly as it appears in Notion/Trello).
- `Trello URL` must be a valid `https://trello.com/c/...` or `https://trello.com/b/...` URL. If it is missing or malformed, ask the user to correct it.
- Never hallucinate a Trello URL. If Notion has no Trello link, leave the line empty and add a note `<!-- TODO: add Trello URL from Notion -->` and warn the user.

Keep the raw values for the description template in Step 3.

## Step 2 — Draft a meaningful MR title

Generate the MR title from the actual changes, not just the branch name.

- Inspect `git log --oneline <base>..HEAD` and `git diff --stat <base>...HEAD` (already shown above) plus `git diff <base>...HEAD --stat` details if needed.
- Title rules:
  - Imperative / concise, under 72 chars, no trailing period.
  - **If the MR contains multiple distinct change contexts, pick only the single biggest/most impactful change for the title — do NOT use `,` to join them.** Move secondary contexts to the description (`#### Summary`/`#### Changes`). Example: an MR that both scales the calendar and adds landscape scroll should not combine them — title uses the primary one only.
  - **Use ` and ` only when the same logical change affects multiple modules/screens** (similar change, parallel scope). In that narrow case ` and ` is allowed. Examples where ` and ` is OK: `Fix header and footer alignment on mobile` (same fix, multiple areas), `Update login and profile screens for dark mode` (same adaptation, multiple screens). If the two parts are distinct features/fixes, do not use ` and ` — pick one.
  - Never use ` & `, ` plus `, or ` with ` to join distinct changes; `&` follows the same rule as ` and ` (only for similar parallel scope).
  - Prefer Conventional Commits style where it helps (`feat:`, `fix:`, `chore:`), but follow the repo's existing MR title style if you can infer it from `glab mr list` or `git log --merges`.
  - Include Trello card code if the Trello Title contains one (e.g. `[PROJ-123] Add retry for payment webhook`), otherwise just the functional summary.
  - Do not include raw branch name unless it adds clarity. Do not include `WIP` unless the MR is explicitly a draft.
  - If Trello Title is very descriptive, you may reuse it verbatim as the MR title — but if it lists multiple distinct contexts with ` and ` or `,`, reduce it to the biggest one; keep ` and ` only if it matches the similar-change-across-screens rule. Mention that you sourced it from Notion.
  - Before running `glab mr create`, self-check the title: if it contains `,` joining two features, or ` and ` joining distinct features, rewrite to the single biggest change.

Examples:
- `fix: prevent double charge on checkout retry [CH-42]`
- `feat(payment): add webhook retry with exponential backoff`
- Distinct contexts — Bad: `Scale Site Diary calendar for iPad and add landscape month scroll` → Good: `Scale Site Diary calendar for iPad` (mention landscape month scroll in `#### Changes`)
- Distinct contexts — Bad: `Fix login, add logout` / `Fix login and add logout` → Good: `Fix login flow` (mention logout in description)
- Similar change across screens — OK: `Fix header and footer alignment on mobile`
- Similar change across screens — OK: `Apply dark mode to login and profile screens`

Ask the user to confirm/edit the title if it is ambiguous or if multiple unrelated commits are on the branch.

## Step 3 — Build the MR description (required: Summary, Changes, Testing, Screenshots, Tickets)

The description MUST contain these sections in order, all concise and short. The Trello metadata lives **under `#### Tickets`** as a bullet (title + URL on one line).

Required template:

```markdown
#### Summary

<1-2 short sentences — what changed and why>

#### Changes

- <concise bullet, one line>
- <concise bullet, one line>

#### Testing

- <concise bullet — how verified>
- <manual/QA note if any>

#### Screenshots

<!-- Manually add images/videos here — leave empty if none yet -->

#### Tickets

- <Trello Title from Notion — exact card title> <Trello URL from Notion — full https://trello.com/... URL>
```

Concrete example (using current values and keeping every section minimal):

```markdown
#### Summary

Scales Site Diary calendar for iPad, fixes month view layout.

#### Changes

- Adjust calendar grid scaling for iPad sizes
- Enable landscape month scroll

#### Testing

- Verified on iPad simulator (portrait + landscape)
- Checked month scroll, no regression on iPhone

#### Screenshots

<!-- Add screenshots manually -->

#### Tickets

- Site Diary Calendar View Scaling for iPad https://trello.com/c/PkDXzMNa
```

Rules:
- Always include headings in order: `#### Summary`, `#### Changes`, `#### Testing`, `#### Screenshots`, `#### Tickets`. First four are required content; `#### Screenshots` is always present but you fill it manually — leave placeholder if empty. `#### Tickets` is required and must be last.
- Keep everything **concise and short** — brevity is required, not optional:
  - `Summary`: 1-2 sentences max, under 30 words. No filler, no background the reviewer already knows. **If this MR is a fix for a previous merged MR (post-merge / post-QA fix), you MUST mention the previous MR in the Summary.** Add a short reference at the end of Summary, e.g. `Follow-up to !123 https://gitlab.com/group/project/-/merge_requests/123 — fixes ...` or `Fix for !123 — addresses QA feedback on ...`. Get the previous MR ID/URL from `glab mr list --merged`, `git log --grep`, or ask the user for the old MR link if not discoverable. Keep it on the same line or a second short sentence.
  - `Changes`: 2-4 bullets max, one line each, under 10 words per bullet. Describe the behavior/area, not file paths.
  - `Testing`: 1-3 bullets max, one line each. State device, command, or QA check.
  - `Screenshots`: manually filled — add images/videos or leave `<!-- Add screenshots manually -->`. Do not auto-generate screenshots; the skill creates the heading with placeholder for you to fill in GitLab. Keep it empty if nothing to show.
  - `Tickets`: single bullet, one line, format `- <Trello Title> <Trello URL>` — title then a single space then raw URL (no brackets, no extra text). Preserve title casing. Use plural heading `#### Tickets` exactly.
- Tickets subsection rules:
  - Heading is `#### Tickets` (four hashes, plural, exact spelling).
  - Single bullet line: `- ` + exact Trello Title as it appears in Notion/Trello + ` ` + exact Trello URL (raw `https://trello.com/c/...`). Do not wrap URL in `<>` or `[]()`. Do not split onto two lines or use `#####` headings.
  - Do not put Trello data anywhere else in the description. Do not duplicate.
- Do not add label headings like `#### Trello Title` / `#### Trello URL` or `#####` blocks outside Tickets. Do not invent Trello data.
- Total description should be short enough to read in one glance — aim for under 100 words excluding Tickets URL and Screenshots.
- Save the full description to a temp file (e.g. `/tmp/mr-desc.md`) for the `glab` call — this avoids shell quoting issues with markdown.
- Self-check before `glab mr create`:
  - `grep -c "^#### Summary" /tmp/mr-desc.md` == 1
  - `grep -c "^#### Changes" /tmp/mr-desc.md` == 1
  - `grep -c "^#### Testing" /tmp/mr-desc.md` == 1
  - `grep -c "^#### Screenshots" /tmp/mr-desc.md` == 1
  - `grep -c "^#### Tickets" /tmp/mr-desc.md` == 1
  - Under Tickets, `grep "^- .*https://trello.com" /tmp/mr-desc.md` shows the bullet with title + URL. If it still shows `##### ` or `#### Ticket` on its own line, rewrite to the new `#### Tickets` bullet format.

## Step 4 — Create the MR with glab (always Draft + assignee + remove source branch)

1. Ensure the branch is pushed (see Pre-flight step 6).
2. Resolve assignee: use the authenticated GitLab user by default. This maps to `--assignee @me` in `glab`. Optionally verify the username via `glab api user --jq .username` or from `glab auth status`. If `glab` cannot resolve `@me`, fall back to no assignee and warn the user rather than failing the MR create. If the user explicitly says "no assignee" or "unassign", skip this flag.
3. Create the MR **as draft**, **assigned to you**, and with **delete source branch on merge**. Prefer the file-based description to avoid escaping issues:

   ```bash
   glab mr create \
     --title "<meaningful title>" \
     --description "$(cat /tmp/mr-desc.md)" \
     --target-branch "<target>" \
     --source-branch "$(git branch --show-current)" \
     --draft \
     --assignee "@me" \
     --remove-source-branch \
     --yes
   ```

   Preferred file-based variant (more robust for multiline markdown):

   ```bash
   glab mr create \
     --title "<meaningful title>" \
     --description-file /tmp/mr-desc.md \
     --target-branch "<target>" \
     --draft \
     --assignee "@me" \
     --remove-source-branch \
     --yes
   ```

   Notes:
   - `--draft` (or `-d`) is required by default per team policy — every MR from this skill is a Draft until you mark it ready with `glab mr update <id> --ready`. Only omit `--draft` if the user explicitly says "ready" / "not draft".
   - `--assignee "@me"` assigns to the authenticated `glab` user. Do not hardcode a username; `@me` always resolves to your account.
   - `glab` may also accept `--assignee me` (without `@`) on older versions — if `--assignee "@me"` fails, retry with `--assignee me`.
   - `--remove-source-branch` checks "Delete source branch when merge request is accepted" by default (GitLab `should_remove_source_branch=true`). This is required per team policy — always include it. Only omit or set `--remove-source-branch=false` if the user explicitly says to keep the branch. On older `glab` versions the flag may require an explicit value: use `--remove-source-branch=true`.

   Additional optional flags you may add when the user asks:
   - `--reviewer <user>` / `--reviewer-group <group>`
   - `--label "label1,label2"`
   - `--milestone "Sprint 12"`
   - `--squash-before-merge` if the repo prefers it

4. If `glab mr create` reports "a merge request already exists for this branch", run `glab mr view` or `glab mr list --source-branch <branch>` and share the existing MR URL instead of creating a duplicate. Offer to update it in place so it stays Draft + assigned + remove-branch:

   ```bash
   glab mr update <id> --description "$(cat /tmp/mr-desc.md)" --draft --assignee "@me"
   # ensure remove-source-branch is set (via API if glab update lacks the flag):
   glab api "projects/:id/merge_requests/:iid" --method PUT -f should_remove_source_branch=true 2>/dev/null || glab mr update <id> --remove-source-branch
   # or file-based:
   glab mr update <id> --description-file /tmp/mr-desc.md
   glab mr update <id> --draft  # if needed
   ```

5. On success, `glab` prints the MR URL (e.g. `https://gitlab.com/group/project/-/merge_requests/123`). Capture and report it. Confirm in the report that the MR is `Draft`, `Assignee: @me`, and `Delete source branch when MR is accepted: enabled`.

## Step 5 — Update Notion (if connected) — append to Merge Requests list

If a Notion page is connected to this epic (e.g. from `/init-epic` which created `Claude Code`/`Resume`/`Branch`/`Merge Requests` headings), update it after the MR is successfully created. If no Notion connection is available, skip this step and note it in the report.

1. **Find the Notion page:**
   - Prefer the page ID/URL passed by the user in this session or stored from Step 1. If Step 1 used Notion MCP, reuse that same page ID.
   - If not known, ask the user: "Is this MR linked to a Notion epic page? If so, paste the Notion link and I'll append it to the Merge Requests list." Do not guess.
   - Verify MCP is available (`mcp__notion__get_page` etc.) — if not, warn and skip.

2. **Read the current `Merge Requests` section:**
   - Fetch the page blocks via `mcp__notion__get_block_children` / `mcp__notion__list_blocks` and locate the `Heading 2: Merge Requests` block.
   - Check existing bullets under it (including the initial `TBD — will fill after glab mr create` placeholder).

3. **Append the new MR to the existing list (do not create a new heading):**
   - Use `mcp__notion__append_block_children` with a single `bulleted_list_item` block **under the existing `Merge Requests` heading**. If the heading does not exist, create `Heading 2: Merge Requests` first, then the bullet.
   - **Format (exact, as requested):**
     ```
     - [MR Title] [MR URL]
     ```
     where `[MR Title]` is the MR title you used in `glab mr create --title` (brackets included) and `[MR URL]` is the full GitLab MR URL returned by `glab` (brackets included). Example:
     ```
     - [Scale Site Diary calendar for iPad] [https://gitlab.com/group/project/-/merge_requests/123]
     - [Fix calendar scroll offset on iPad landscape] [https://gitlab.com/group/project/-/merge_requests/124]
     ```
     Keep one MR per bullet, one line each. Do NOT use markdown link syntax `[title](url)` — keep the two separate bracket groups exactly as `- [title] [url]`.
   - If the list currently contains only the `TBD` placeholder bullet, either replace that bullet's text or keep it and append the new MR bullet below it, then remove the `TBD` placeholder on a follow-up update if needed. Prefer replacing `TBD` with the first real MR entry.
   - For subsequent fix MRs after QA, keep appending additional bullets under the same `Merge Requests` heading — do not duplicate the heading.

4. **Verify:** Re-fetch the page blocks to confirm the bullet appears under `Merge Requests` in the format `- [title] [url]`. Share the Notion page URL in the report.

## Step 6 — Report back

- Print the MR title, target branch, and MR URL.
- Confirm the description contains `#### Summary` / `#### Changes` / `#### Testing` / `#### Screenshots` / `#### Tickets` in order, concise and short, and that under `#### Tickets` it has a single bullet `- <Trello Title> <Trello URL>` (title + URL on one line, sourced from Notion). Note that `#### Screenshots` is manually filled — confirm placeholder is present if empty. If this was a fix for a previous merged MR, confirm the old MR reference appears in `#### Summary`.
- Confirm the MR is `Draft`, `Assignee: @me` (your account), and `Delete source branch when MR is accepted: enabled`. If any flag failed, explain why.
- If a Notion page was connected, confirm you appended `- [MR Title] [MR URL]` to its `Merge Requests` list (or created the list); otherwise note that no Notion update was performed.
- Tell the user how to mark ready when done: `glab mr update <id> --ready`.
- Do not push to a different remote or force-push. Do not amend commits.

## Error handling

- `glab: command not found` → installation instructions, stop.
- `Not authenticated` → `glab auth login --hostname gitlab.com` (or self-hosted host), stop.
- `remote not found` or `not a git repository` → verify path, stop.
- Notion lookup fails → fall back to asking the user (Step 1, option 3), never fabricate.
- MR create fails due to validation (e.g. title too long, branch not pushed) → show the exact `glab` stderr and suggest the fix.

## Quick reference — one-liner for manual use

If the user just wants the shell command after you draft the description:

```bash
cat > /tmp/mr-desc.md <<'EOF'
#### Summary

<1-2 sentences, concise>

#### Changes

- <one-line bullet>
- <one-line bullet>

#### Testing

- <how verified>

#### Screenshots

<!-- Add screenshots manually -->

#### Tickets

- <Trello Title from Notion> https://trello.com/c/...
EOF
glab mr create --title "<title>" --description-file /tmp/mr-desc.md --target-branch development --draft --assignee "@me" --remove-source-branch --yes
```
