---
name: daily-report
description: Generate a daily report from conversation context and sync to Notion Daily Report page linked to the requirement page. Use when the user asks for daily report, standup, what I did today, or types /daily-report.
disable-model-invocation: true
allowed-tools: Bash(git log *) Bash(git status *) Bash(git diff *) Bash(date *) Bash(git branch *)
---

## Current branch

!`git branch --show-current`

## Recent commits (for daily context)

!`git log -n 20 --pretty=format:'%h %ad %s' --date=short | head -30`

## Today's commits

!`git log --since="00:00" --until="23:59" --pretty=format:'%h %ad %s' --date=short | head -30`

## Working tree (uncommitted work counts for today)

!`git status --short`

## Uncommitted diff summary

!`git diff HEAD --stat | head -30`

# daily-report — Generate Daily Report and sync to Notion

You automatically review what the user has done so far in the conversation context, display it, and put it into the Notion Daily Report page linked to the current requirement Notion page.

## Target dates

1. Default is **today** (local date from `date` / system). Use `date "+%B %-d, %Y"` format for the heading (e.g. `September 3, 2026`).
2. If the user asks for a specific date or range (e.g. `/daily-report 2026-09-02`, `/daily-report yesterday`, `/daily-report 2026-09-01 to 2026-09-03`), parse those dates and generate one section per date in descending order (newest first). For each requested date, filter evidence to that day (`git log --since="YYYY-MM-DD 00:00" --until="YYYY-MM-DD 23:59"`).
3. If no date is specified, ask to confirm: "Generate report for today (September 3, 2026)?" unless the conversation clearly implies another date — then generate for the implied date and state which date you used.

## Step 1 — Review what was done (conversation-first)

Primary source is the **conversation**: what the user asked for, what you built/edited, decisions made, and what was completed.

Supporting evidence (do not treat as sole truth — conversation wins when they differ):
- `git log` above for commits touching each date (including `git log --since/--until` for specific dates).
- `git status --short` and `git diff HEAD --stat` for uncommitted work that counts for today.
- Any Notion requirement page linked in this session (from `/init-epic` or user-provided URL) — extract `Trello Title` and `Trello URL` from its properties (same extraction as `skills/gitlab-mr/SKILL.md` Step 1: MCP search, Notion API, or ask user). Each report bullet should pair the work summary with its Trello URL when available.

For each date, build **2-6 bullets** (one bullet per distinct task/commit):
- Format per bullet: `- <short doing summary> <Trello URL>` — summary under 15 words, imperative/gerund consistent (e.g. `Implement`, `Fix`, `Scale`), then single space, then raw Trello URL `https://trello.com/c/...`. If no Trello URL is known for a task, use the summary alone and note `<!-- no Trello URL — add when available -->` internally but do not publish the comment.
- Do not hallucinate Trello URLs. If Notion has no Trello link, leave URL blank and warn.
- Keep the same style as `feat(gitlab-mr)` commit messages where sensible — concise, no filler.

If there is nothing to report for a date (no conversation work, no commits, no diff), state `No activity recorded` under that date instead of leaving it empty.

## Step 2 — Display in chat (always before Notion write)

Render the report in the chat using the exact format below so the user can review/copy. Use `September 3, 2026` style headings (full month name, day, year). Separate dates with `---` on its own line.

```
September 3, 2026
- Scale Site Diary calendar for iPad https://trello.com/c/PkDXzMNa
- Fix calendar scroll offset on iPad landscape https://trello.com/c/AbC123

---

September 2, 2026
- Bootstrap epic from Notion and create branch https://trello.com/c/XyZ789
- Add git-stage context-aware staging skill https://trello.com/c/QwE456
```

- Newest date first, `---` between dates (no trailing `---` after last date).
- Keep bullets exactly as `- ` + summary + ` ` + URL.

Ask for confirmation before writing to Notion: "Push this to the Notion Daily Report page?" unless the user already said to sync.

## Step 3 — Resolve Notion pages

You need two Notion pages:

1. **Requirement / context page** (the epic/initiative you are working on): Prefer the page ID/URL from this session (used by `/init-epic` or `/gitlab-mr`), or from `mcp__notion__search` matching branch name / recent commits. If not discoverable, ask: "Paste the Notion link for the current requirement page to link in the report (or say skip)."

2. **Daily Report page** (the destination): 
   - Try in order: (a) MCP search for database/page titled `Daily Report`, `Daily Reports`, `Standup`, or similar; (b) page URL provided by user in this session or env `NOTION_DAILY_REPORT_PAGE_ID`; (c) ask user: "Please paste the Notion Daily Report page URL."
   - If MCP is unavailable, warn and keep the report as chat-only output (do not fail the display step).
   - Never invent a page ID.

## Step 4 — Put into Notion Daily Report page

1. **Read the Daily Report page blocks** via `mcp__notion__get_block_children` / `mcp__notion__list_blocks` to see existing date headings and avoid duplicating a date.

2. **For each target date in the report:**
   - Locate `Heading 1` or `Heading 2` with the exact date string (e.g. `September 3, 2026`). If it exists, append/update bullets under it. If not, create it:
     - Create `heading_2` block with `rich_text: [{text: {content: "September 3, 2026"}}]`.
     - Immediately after the heading, add a small link paragraph if a requirement page was resolved: paragraph with `rich_text` containing `Context: ` + requirement page title linked via `text: {content: "<Requirement Title>", link: {url: "<Notion Requirement Page URL>"}}`. If no requirement page, skip this link paragraph.
     - Then append each bullet as a `bulleted_list_item` block with `rich_text`:
       - `text: {content: "<summary> "}` + `text: {content: "<Trello URL>", link: {url: "<Trello URL>"}}` if you want clickable, OR plain text summary + URL if link unfurl is not supported. Prefer plain text `- <summary> <URL>` to match chat format; use link annotation for the URL part when available.
     - Order: newest date section at the top of the page. Achieve this by `append` for new dates then note to user that manual reorder may be needed if the API only appends — or use `mcp__notion__append_block_children` with `after` positioning if supported; otherwise append at bottom and warn "New date added at bottom — move to top if your page is newest-first."
   - If a date heading already exists with prior bullets, **append only the new bullets that are not duplicates** (match by Trello URL or summary). Do not overwrite existing bullets. Separate appended batch with no extra divider — the `---` divider is chat-only; in Notion use headings as separators.
   - For the `---` between dates in chat, do NOT create a `divider` block in Notion unless the page already uses dividers between date sections — if it does, insert `divider` between headings for consistency; otherwise headings alone are sufficient.

3. **Verify:** Re-fetch the Daily Report page blocks and confirm each target date heading appears with the expected bullet count and that the requirement page link (if any) appears under the heading. Share the Daily Report page URL in the report.

## Step 5 — Report back

- Show the chat report (Step 2) again as confirmation.
- Confirm: "Written to Notion Daily Report: <page URL> — <dates> updated" or "Chat-only (no Notion page configured — paste Daily Report URL to sync)."
- If a requirement page link was added, confirm: "Linked to requirement: <Notion Requirement Page URL>."
- Tell the user: Re-run with `/daily-report 2026-09-02` or `/daily-report yesterday` or a range to review other dates.

## Error handling

- No conversation work and no commits for the date → report `No activity recorded` for that date, still create heading in Notion if requested (or skip if user says not to).
- Notion MCP not connected / auth fails → keep chat report, instruct to connect/share pages, do not fabricate.
- Requirement page not found → generate report without the context link and note it.
- Trello URL missing → bullet without URL, warn "No Trello URL found for <summary> — add from Notion."
