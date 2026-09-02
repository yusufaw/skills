---
name: init-epic
description: Bootstrap an epic from a Notion link — read the initiative via Notion MCP, assess implementation feasibility, create a branch via /git-branch, and write session/branch/MR info plus concise plan back to Notion. Use when user gives a Notion link to start an epic or says /init-epic.
---

## Current branch

!`git branch --show-current`

## Working tree

!`git status --short --branch`

## Existing branches (for /git-branch naming)

!`git branch --all --sort=-committerdate --format='%(refname:short)' | head -n 20`

## Recent commits (for style)

!`git log -n 5 --pretty=format:%s`

# init-epic — Initialize epic from Notion

You turn a Notion initiative page into a ready-to-work epic: read it, judge feasibility, create a branch, and write session context + plan back to Notion for traceability.

## Step 0 — Get the Notion link

- Expect the user to provide a Notion link (e.g. `https://www.notion.so/...` or `notion.so/...` with page ID). If not provided in this turn, ask: "Please paste the Notion link for this epic."
- Extract the page ID: last 32 hex chars of the URL (with or without dashes). Normalize to UUID format `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` if needed.
- Validate the link is a Notion page/database page, not a random URL. If invalid, ask for correction and stop.

## Step 1 — Read the Notion page via MCP

You MUST use Notion MCP — do not mock or hallucinate the content.

1. Call the Notion MCP read tool (e.g. `mcp__notion__get_page`, `mcp__notion__retrieve_page`, or `mcp__notion__get_page_content` — use whichever is available in this environment) with the page ID / URL.
2. If the page is a database entry, also fetch its properties: title, description, status, and any rich-text fields that contain the initiative description.
3. If the first call returns only metadata, follow with a block-children fetch (e.g. `mcp__notion__get_block_children` / `mcp__notion__list_blocks`) to get the full body text.
4. If MCP is unavailable or returns an error (auth, permissions, page not found), tell the user exactly what failed, suggest checking Notion connection / sharing the page with the integration, and stop — do not proceed without the real content.
5. Consolidate the content into a short in-memory summary: keep original headings, bullet points, and acceptance criteria verbatim where possible; note any linked Figma, Trello, or docs referenced inside.

## Step 2 — Assess the description and feasibility

From the Notion content you just read:

1. **Summarize the intent in 2-3 sentences** — what user/business problem it solves, not how.
2. **Feasibility / possibility to implement (concise):**
   - Can this be built with the current stack/project? Note major touch points (apps, services, data models, permissions) at a high level — no file/function names.
   - Key constraints, dependencies, or unknowns that would block or slow it.
   - Risks if any (e.g. data migration, third-party API, performance).
   - If the description is vague or missing acceptance criteria, list the specific gaps as Open Questions — do not invent requirements.
3. Keep this assessment short (under 150 words). This section will be echoed both in chat and in the Notion impl plan — make it decision-ready, not an essay.
4. If you see that the initiative is too large for one MR/branch, call it out and suggest splitting into phases, but still proceed with a branch for phase 1 / spike unless the user says to stop.

## Step 3 — Create a branch via /git-branch

Delegate branch naming to the `/git-branch` skill logic — do not invent a different flow:

1. Follow `skills/git-branch/SKILL.md` exactly:
   - Derive the work summary from the Notion title + your feasibility summary (not from uncommitted diff).
   - Respect the existing branch naming pattern in this repo (`git branch --all` above); fallback to `type/short-summary` with type `feat`/`fix`/`chore` etc., kebab-case, 3-5 words, no filler words.
   - Check against existing branches to avoid collision; disambiguate with a meaningful word, not a number suffix.
   - Confirm base branch (default to current HEAD; if current branch is unrelated feature branch, confirm before branching).
2. Create and switch:
   ```
   git switch -c <branch-name>
   # fallback: git checkout -b <branch-name>
   ```
3. Verify with `git status --short --branch` and report the new branch name and base.
4. Save the branch name for Step 4 — it must be written to Notion in code format.

If `/git-branch` cannot determine a name (clean tree + vague Notion page), ask the user for a one-line summary and retry — do not hallucinate.

## Step 4 — Write back to Notion (session, branch, MR link, concise plan)

Write directly to the SAME Notion page you read in Step 1 via Notion MCP update/append tools.

### What to write — After format (code blocks, not inline red text)

Append a section to the page (at the top or bottom, without overwriting the original spec). Use the **After** layout shown in the second screenshot: four separate headings, each followed by a Notion `code` block (gray background), except Merge Request which is plain paragraph text. Do NOT use the old Before format (single paragraph with `Session ID: <red inline code>`).

Create these blocks in order via Notion MCP:

1. **Heading 2: `Claude Code`**
   - Followed by a **code block** (`type: code`, language `plain text`) containing two lines, Session Name first, Session ID second:
     ```
     Session Name: epic/meeting-custom-fields-state-leak
     Session ID: bbfb0970-c6ca-48cd-93f1-aabce87d1016
     ```
   - Use the real Session Name and Session ID for this chat (see "How to get Session ID / Name" below). Never invent a UUID.

2. **Heading 2: `Resume`**
   - Followed by a **code block** containing the resume command:
     ```
     claude --resume bbfb0970-c6ca-48cd-93f1-aabce87d1016
     ```

3. **Heading 2: `Branch`**
   - Followed by **two separate code blocks** (so each is easy to copy):
     1. Code block with the branch name created in Step 3:
        ```
        fix/meeting-custom-fields-state-leak
        ```
        or e.g. `feat/site-diary-ipad-scaling`
     2. Code block with the checkout command in a separate block:
        ```
        git checkout "fix/meeting-custom-fields-state-leak"
        ```
        Also copyable — use `git checkout "<branch>"` (or `git switch "<branch>"` on newer Git). Keep the branch name quoted so slashes are safe to copy. This second block is required so the user can one-click copy the checkout command.

4. **Heading 2: `Merge Requests`** (plural)
   - Followed by a **bulleted list** of MRs — each item contains the MR title and URL on one line. This is a list because you will add follow-up fix MRs after QA testing.
   - Initial state (no MR yet): single placeholder bullet:
     ```
     - TBD — will fill after glab mr create
     ```
   - After `/gitlab-mr` creates the first MR, replace/add bullet(s) like:
     ```
     - Scale Site Diary calendar for iPad https://gitlab.com/group/project/-/merge_requests/123
     - Fix calendar scroll offset on iPad landscape https://gitlab.com/group/project/-/merge_requests/124
     ```
   - Format per bullet: `- <MR title> <MR URL>` — title as created in Step 2 / `glab mr create --title`, then a single space, then full GitLab MR URL. If a fix MR is not yet created, keep its `TBD` bullet until the URL is known. Use an em dash `—` for the placeholder.
   - Keep the list as `bulleted_list_item` blocks (not a code block, not a plain paragraph), so each MR is linkable and easy to extend.

Do NOT add extra labels like `Session ID:` as separate inline-code paragraphs — the values must live inside the code blocks as shown. The gray code-block background is the visual cue (second screenshot), not red inline code (first screenshot). Do NOT use singular `Merge Request` — always `Merge Requests`.

### How to get Session ID / Name

- If the environment exposes `CLAUDE_SESSION_ID` / `CLAUDE_SESSION_NAME` or a `session` MCP resource, read it via `Bash(echo $CLAUDE_SESSION_ID)` or the session tool and use the real values.
- If not exposed, check the chat UI header or ask Claude to confirm: run `Bash` to list recent session files (`ls ~/.config/claude/sessions 2>/dev/null | head`) only if permitted; otherwise state: `Session ID: <copy from this chat's session ID>` and ask the user to confirm. Never invent a UUID — use the real one or mark as `TBD - copy from chat header`.
- Session Name is typically the auto-generated title of this conversation; if unavailable, derive from the branch name or Notion title (e.g. `epic/meeting-custom-fields-state-leak`) and note it is provisional. In the code block, keep the order `Session Name:` line first, `Session ID:` second, exactly as in the After screenshot.

### Concise impl plan (same write, optional but keep short)

If you also write the impl plan, place it **after** the four headings above as a separate section. Keep it concise:

- Heading 2 or 3: `Plan` or `Implementation Plan`
- 3-5 bullets max, one line each, under 100 words total.
- Cover: approach, key areas in plain language (no file paths), dependencies, testing idea.
- Use `bulleted_list_item` blocks, not inside a code block.

Example Notion append structure (After format):

```
Heading 2: Claude Code
  Code block:
    Session Name: epic/meeting-custom-fields-state-leak
    Session ID: bbfb0970-c6ca-48cd-93f1-aabce87d1016

Heading 2: Resume
  Code block:
    claude --resume bbfb0970-c6ca-48cd-93f1-aabce87d1016

Heading 2: Branch
  Code block:
    fix/meeting-custom-fields-state-leak
  Code block:
    git checkout "fix/meeting-custom-fields-state-leak"

Heading 2: Merge Requests
  Bulleted list:
    - TBD — will fill after glab mr create
    # after MR created, becomes for example:
    # - Scale Site Diary calendar for iPad https://gitlab.com/group/project/-/merge_requests/123
    # - Fix calendar scroll offset on iPad landscape https://gitlab.com/group/project/-/merge_requests/124

Heading 3: Plan
  - Scale Site Diary calendar grid for iPad, add landscape month scroll
  - Touch area: Site Diary screen, calendar component, layout utils
  - Verify on iPad simulator + iPhone regression
```

### MCP write calls

- Use `mcp__notion__append_block_children` (preferred) — append blocks in the order above so you do not overwrite the spec. Create blocks with types: `heading_2` for each title, `code` for the four code blocks (Claude Code, Resume, Branch name, Branch checkout `git checkout "<branch>"`) with `rich_text: [{text: {content: "..."}}]` and `language: "plain text"`, `bulleted_list_item` for each Merge Requests entry (including the initial `TBD — will fill after glab mr create` placeholder), and `bulleted_list_item` for the plan.
- Do NOT use `paragraph` with `annotations: {code: true}` (red inline code) — that produces the Before format. Use `type: "code"` blocks for the gray background and `bulleted_list_item` for the MR list.
- If the MCP only supports page property updates, write the same content into a `Dev Session` / `Implementation` property as rich text; mention in chat where you wrote it.
- After writing, fetch the page again via `get_page` / `get_block_children` to confirm the four headings appear — `Claude Code`/`Resume` with one code block each, `Branch` with two code blocks (name + `git checkout "<branch>"`), and `Merge Requests` with a bullet list — as in the After screenshot, and share the Notion page URL back to the user. If the page still shows the old inline-red format or singular `Merge Request` or only one Branch code block, delete those Blocks and re-append using `code` blocks + `Merge Requests` bulleted list. To add follow-up QA fix MRs later, append another `bulleted_list_item` under the existing `Merge Requests` heading rather than creating a new heading.

## Step 5 — Report back

- Show the Notion title + URL you read.
- One-line feasibility verdict (feasible / feasible with risks / needs clarification).
- New branch name and base.
- Confirm what you wrote to Notion (Claude Code code block, Resume code block, Branch code block + checkout command code block, and Merge Requests bulleted list with placeholder) and paste the Notion URL.
- Tell the user: `Branch` now has two copyable blocks — the name and `git checkout "<branch>"` — and Merge Requests list starts as `TBD — will fill after glab mr create` — you will update the same `Merge Requests` heading with `- <title> <url>` bullets when each MR is created (initial MR via `/gitlab-mr`, plus additional fix MRs after QA). To add a follow-up MR, append a new bullet under that heading rather than creating a new section.
- Do not push, do not create an MR yet — that is `/gitlab-mr`'s job.

## Error handling

- Notion MCP not connected → instruct to connect/share page, stop.
- Page not found / permission denied → show the exact error, ask to re-share, stop.
- Branch already exists → follow `/git-branch` collision rule, do not overwrite.
- Session ID unavailable → write `TBD` placeholder with instruction, do not hallucinate UUID.
- Always keep Notion writes non-destructive — append, don't replace the spec.
