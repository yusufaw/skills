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

1. Default is **today** (local date from `date` / system). Use `date "+%B %-d, %Y"` format for the heading (e.g. `September 3, 2026`). If the user does not mention any date, generate for today immediately — no confirmation needed.
2. If the user asks for a specific date or range (e.g. `/daily-report 2026-09-02`, `/daily-report yesterday`, `/daily-report 2026-09-01 to 2026-09-03`), parse those dates and generate one section per date in descending order (newest first). For each requested date, filter evidence to that day (`git log --since="YYYY-MM-DD 00:00" --until="YYYY-MM-DD 23:59"`).

## Step 1 — Review what was done (conversation-first)

Primary source is the **conversation**: what the user asked for, what you built/edited, decisions made, and what was completed.

Supporting evidence (do not treat as sole truth — conversation wins when they differ):
- `git log` above for commits touching each date (including `git log --since/--until` for specific dates).
- `git status --short` and `git diff HEAD --stat` for uncommitted work that counts for today.
- Any Notion requirement page(s) linked in this session (from `/init-epic` or user-provided URLs) — extract `Trello Title` and `Trello URL` from each page's properties (same extraction as `skills/gitlab-mr/SKILL.md` Step 1: MCP search, Notion API, or ask user). Each Context group pairs with its Notion page title and Trello URL. If a task maps to multiple Notion pages, group under the primary one.

**Grouping by Context (required):**
- Group all work by Notion page / Trello card. Each distinct requirement = one `Context: <Notion Page Title>` group.
- Under each Context, list 1-5 bullets for the concrete work done for that requirement that day.
- Order Context groups by most significant / most commits first, or chronologically if equal.
- For each date, target 1-4 Context groups and 2-9 total bullets.

**Bullet format per line:**
- `Context: <Notion Page Title>` — exactly this prefix, then the Notion page title. In chat, append the Trello URL after title if you want traceability, but title alone is sufficient. In Notion, annotate the title segment with `link: {url: "<Notion Page URL>"}` when available.
- `- <short doing summary> <Trello URL>` — summary under 15 words, imperative style (`Fix`, `Add`, `Verify`, `Apply`), then single space, then raw Trello URL `https://trello.com/c/...`. If no Trello URL is known, use summary alone and warn internally. Do not hallucinate Trello URLs.

**Noise filtering — EXCLUDE these from the report (do not create bullets for them):**
- Tooling/infra noise: `hot reload`, `flutter hot reload`, `hot restart`, `flutter run`, `pod install`, `npm install`, dev server restarts.
- Process noise: `open MR`, `create MR`, `push branch`, `rebase`, `merge main into branch`, `resolve conflicts` — unless the MR itself is the deliverable the user cares about (then summarize as `Verify ...` or `Open follow-up MR` under the relevant Context, not as a standalone bullet).
- Pure formatting/lint commits with no functional change (`format`, `lint fix`, `prettier`) — fold into the related Context bullet if needed, don't list separately.
- WIP / checkpoint commits (`wip`, `tmp`, `fix typo` without context) — consolidate into a meaningful summary for the Context.
- When in doubt, drop the noise. Prefer fewer, meaningful bullets over exhaustive commit-by-commit listing.

If there is nothing meaningful to report for a date after filtering, state `No activity recorded` under that date instead of leaving it empty.

## Step 2 — Display in chat (always before Notion write)

Render the report in the chat using the exact format below so the user can review/copy. Use `September 3, 2026` style headings (full month name, day, year). Separate dates with `---` on its own line.

```
September 3, 2026
Context: Split Button for Upload Attachments is Missing in Multiple Modules
- Fix iPad attachment button width across Site Diary screens https://trello.com/c/p47rWwhV
- Apply shared iPad sizing across attachment modules https://trello.com/c/p47rWwhV
- Verify iPad attachment flows and open follow-up MR https://trello.com/c/p47rWwhV
Context: Add "Print" Button to Generated PDF Viewers Across Core Modules
- Fix Permit PDF landscape relayout from the print dialog https://trello.com/c/ODV5SCi2
- Paginate large custom-field tables in landscape https://trello.com/c/ODV5SCi2
- Add landscape PDF regression coverage https://trello.com/c/ODV5SCi2
- Verify Permit landscape printing on Nokia without PDF fallback https://trello.com/c/ODV5SCi2
Context: Add Delay Register to Mobile App (Site Diary)
- Fix singular/plural wording for delay hours https://trello.com/c/7Ib0vf0v
- Show Delay Register count in section titles https://trello.com/c/7Ib0vf0v
- Reduce the top gap above the Add Delay button https://trello.com/c/7Ib0vf0v

---

September 2, 2026
Context: Site diary and pdf via mobile - allow user to PDF
- Add Delay Register section to exported Site Diary PDFs https://trello.com/c/3Yu1Rmfp
- Align Activities by Trade values in exported Site Diary PDFs https://trello.com/c/3Yu1Rmfp
- Verify Site Diary PDF output on iPad and Nokia https://trello.com/c/3Yu1Rmfp
```

- Newest date first, `---` between dates (no trailing `---` after last date).
- Keep `Context: ` lines exactly as `Context: ` + Notion title (no dash prefix, no bullet).
- Keep task lines exactly as `- ` + summary + ` ` + Trello URL.

Ask for confirmation before writing to Notion: "Push this to the Notion Daily Report page?" unless the user already said to sync.

## Step 3 — Resolve Notion pages

You need:

1. **Requirement / context pages** (one per Context group): For each Context, prefer the page ID/URL from this session (used by `/init-epic` or `/gitlab-mr`), or from `mcp__notion__search` matching branch name / recent commits / Trello URL. If not discoverable, use the Notion title as plain text (no link) and warn. Collect all distinct Notion pages for the date — do not limit to a single page.

2. **Daily Report page** (the destination):
   - Try in order: (a) MCP search for database/page titled `Daily Report`, `Daily Reports`, `Standup`, or similar; (b) page URL provided by user in this session or env `NOTION_DAILY_REPORT_PAGE_ID`; (c) ask user: "Please paste the Notion Daily Report page URL."
   - If MCP is unavailable, warn and keep the report as chat-only output (do not fail the display step).
   - Never invent a page ID.

## Step 4 — Put into Notion Daily Report page

1. **Read the Daily Report page blocks** via `mcp__notion__get_block_children` / `mcp__notion__list_blocks` to see existing date headings and avoid duplicating a date.

2. **For each target date in the report:**
   - Locate `Heading 1` or `Heading 2` with the exact date string (e.g. `September 3, 2026`). If it exists, append/update content under it. If not, create it:
     - Create `heading_2` block with `rich_text: [{text: {content: "September 3, 2026"}}]`.
     - Then append **a single `paragraph` block** containing the entire list for that date — use manual line breaks and literal `Context: ` / `- ` prefixes, NOT `bulleted_list_item` blocks, NOT multiple paragraphs. Build the paragraph's `rich_text` so each line is either `Context: <Notion Title>` or `- <summary> <Trello URL>` joined by `\n`. Example content for one date: `Context: Split Button for Upload Attachments is Missing in Multiple Modules\n- Fix iPad attachment button width across Site Diary screens https://trello.com/c/p47rWwhV\n- Apply shared iPad sizing across attachment modules https://trello.com/c/p47rWwhV\nContext: Add "Print" Button to Generated PDF Viewers Across Core Modules\n- Fix Permit PDF landscape relayout from the print dialog https://trello.com/c/ODV5SCi2\n- Paginate large custom-field tables in landscape https://trello.com/c/ODV5SCi2`. For clickable links: annotate only the Notion title segment in `Context: ` lines with `link: {url: "<Notion Page URL>"}` and only the URL segment in bullet lines with `link: {url: "<Trello URL>"}`; keep prefixes (`Context: `, `- `) and summaries as plain text.
     - Do NOT use `bulleted_list_item` blocks anywhere for daily reports. Do NOT split Context groups into separate paragraphs — keep exactly one paragraph per date.
     - Order: newest date section at the top of the page. Achieve this by `append` for new dates then note to user that manual reorder may be needed if the API only appends — or use `mcp__notion__append_block_children` with `after` positioning if supported; otherwise append at bottom and warn "New date added at bottom — move to top if your page is newest-first."
   - If a date heading already exists, locate its single list `paragraph` immediately after the heading. **Append only new lines that are not duplicates** (match by Trello URL or summary, and for Context lines by Notion title) by updating that paragraph block via `mcp__notion__update_block` to extend its `rich_text` with `\nContext: <new title>` or `\n- <new summary> <URL>`. Do not create `bulleted_list_item` blocks or additional paragraphs for the same date — keep exactly one list paragraph per date; if no list paragraph exists yet, create one. Do not overwrite existing lines. When adding a new Context group to an existing date, append the `Context: ` line followed by its bullets in order.
   - For the `---` between dates in chat, do NOT create a `divider` block in Notion unless the page already uses dividers between date sections — if it does, insert `divider` between headings for consistency; otherwise headings alone are sufficient.

3. **Verify:** Re-fetch the Daily Report page blocks and confirm each target date heading appears with its single `paragraph` containing the expected `Context: ` and `- ` line count and that the Notion page link(s) appear in the Context lines. Share the Daily Report page URL in the report.

## Step 5 — Report back

- Show the chat report (Step 2) again as confirmation.
- Confirm: "Written to Notion Daily Report: <page URL> — <dates> updated" or "Chat-only (no Notion page configured — paste Daily Report URL to sync)."
- If requirement page link(s) were added, confirm: "Linked to requirement(s): <Notion Requirement Page URL(s)>."
- Tell the user: Re-run with `/daily-report 2026-09-02` or `/daily-report yesterday` or a range to review other dates.

## Error handling

- No meaningful activity after filtering for the date → report `No activity recorded` for that date, still create heading in Notion if requested (or skip if user says not to).
- Notion MCP not connected / auth fails → keep chat report, instruct to connect/share pages, do not fabricate.
- Requirement page not found → generate report with Context title as plain text (no link) and note it.
- Trello URL missing → bullet without URL, warn "No Trello URL found for <summary> — add from Notion."
