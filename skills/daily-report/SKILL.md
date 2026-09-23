---
name: daily-report
description: Generate a daily report from committed code changes and sync to Notion Daily Report page linked to the requirement page. Use when the user asks for daily report, standup, what I did today, or types /daily-report.
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

You automatically review committed code changes for the target date, display it, and put it into the Notion Daily Report page linked to the current requirement Notion page.

## Target dates

1. Default is **today** (local date from `date` / system). Use `date "+%B %-d, %Y"` format for the heading (e.g. `September 3, 2026`). If the user does not mention any date, generate for today immediately — no confirmation needed.
2. If the user asks for a specific date or range (e.g. `/daily-report 2026-09-02`, `/daily-report yesterday`, `/daily-report 2026-09-01 to 2026-09-03`), parse those dates and generate one section per date in descending order (newest first). For each requested date, filter evidence to that day (`git log --since="YYYY-MM-DD 00:00" --until="YYYY-MM-DD 23:59"`).

## Step 1 — Review what was done (committed code only)

**Primary source is committed code** — `git log --since/--until` for the target date and `git diff <commit> --stat` / commit messages. Only work that produced a committed code change counts.

Conversation context and `git status`/`git diff HEAD` are **supporting evidence only** to map commits to Notion Context and to understand what changed. Do NOT create bullets for activities that have no corresponding committed code change.

Supporting evidence:
- `git log` above for commits touching each date (including `git log --since/--until` for specific dates). Inspect `git log --stat` / `git show --stat` if the summary is unclear.
- Any Notion requirement page(s) linked in this session (from `/init-epic` or user-provided URLs) — extract `Trello Title` and `Trello URL` from each page's properties (same extraction as `skills/gitlab-mr/SKILL.md` Step 1: MCP search, Notion API, or ask user). Each Context group pairs with its Notion page title and Trello URL. If a task maps to multiple Notion pages, group under the primary one.

**What counts:**
- Any committed change to codebase files (feat/fix/refactor/update/remove/migrate/implement) — including app code, scripts, and config that ships with the codebase.

**What does NOT count (never create a bullet for these):**
- Process / non-code activities without a code diff: `verify`, `test`, `QA`, `manual check`, `push branch`, `open MR`, `create MR`, `rebase`, `merge main into branch`, `resolve conflicts`, `review`, `deploy`.
- If the only evidence for an activity is the conversation mentioning verification/testing/pushing but no commit backs it, drop it entirely. Do not rewrite it as `Verify ...`.

**Grouping by Context (required):**
- Group all work by Notion page / Trello card. Each distinct requirement = one `Context: <Notion Page Title>` group.
- Under each Context, list 1-5 bullets for the **committed code changes** for that requirement that day.
- Order Context groups by most significant / most commits first, or chronologically if equal.
- For each date, target 1-4 Context groups and 2-9 total bullets.

**Bullet format — one-line, self-contained (required):**
- `Context: <Notion Page Title>` — exactly this prefix, then the Notion page title. In chat, append the Trello URL after title if you want traceability, but title alone is sufficient. In Notion, annotate the title segment with `link: {url: "<Notion Page URL>"}` when available.
- `- <self-contained code-change summary> <Trello URL>` — exactly one line per committed change:
  - Start with a code-change verb: `Add`, `Fix`, `Update`, `Refactor`, `Remove`, `Migrate`, `Implement` (never `Verify`, `Test`, `Push`, `Create MR`, `Check`).
  - Must be understandable **without opening the Notion page**. Include WHAT changed + WHERE (module/feature/file) in the same line. Do NOT rely on the `Context:` title to carry meaning — repeat the feature/module name in the bullet if needed.
  - Under 20 words, imperative style, concrete and specific (bad: `Fix width`; good: `Fix iPad attachment button width in Site Diary to prevent overflow on small screens`).
  - Then single space, then raw Trello URL `https://trello.com/c/...`. If no Trello URL is known, use summary alone and warn internally. Do not hallucinate Trello URLs.
  - One commit may map to one bullet; squash trivial fixup commits (`fix typo`, `wip`, `lint`) into the meaningful bullet they support — do not list them separately.

**Noise filtering — EXCLUDE these from the report (do not create bullets for them):**
- Tooling/infra noise: `hot reload`, `flutter hot reload`, `hot restart`, `flutter run`, `pod install`, `npm install`, dev server restarts.
- All process bullets: `Verify ...`, `Test ...`, `QA ...`, `Push branch`, `Open MR`, `Create MR`, `Rebase`, `Merge main` — even when they appear under a relevant Context in examples elsewhere, they must be omitted here.
- Pure formatting/lint commits with no functional change (`format`, `lint fix`, `prettier`) — fold into the related code-change bullet if needed, don't list separately.
- WIP / checkpoint commits (`wip`, `tmp`, `fix typo` without context) — consolidate into the meaningful code-change summary for the Context.
- Uncommitted / unstaged changes with no commit — do not report unless the user explicitly asks to include staged work; default is committed code only.
- When in doubt, drop the noise. Prefer fewer, meaningful code-change bullets over exhaustive commit-by-commit listing.

If there is nothing meaningful to report for a date after filtering, state `No activity recorded` under that date instead of leaving it empty.

## Step 2 — Display in chat (always before Notion write)

Render the report in the chat using the exact format below so the user can review/copy. Use `September 3, 2026` style headings (full month name, day, year). Separate dates with `---` on its own line.

```
September 3, 2026
Context: Split Button for Upload Attachments is Missing in Multiple Modules
- Fix iPad attachment button width in Site Diary to prevent overflow on small screens https://trello.com/c/p47rWwhV
- Update shared attachment component sizing for iPad across all modules https://trello.com/c/p47rWwhV
Context: Add "Print" Button to Generated PDF Viewers Across Core Modules
- Fix Permit PDF landscape relayout triggered from print dialog https://trello.com/c/ODV5SCi2
- Paginate large custom-field tables in Permit PDF landscape export https://trello.com/c/ODV5SCi2
- Add landscape PDF regression coverage for Permit custom-field tables https://trello.com/c/ODV5SCi2
Context: Add Delay Register to Mobile App (Site Diary)
- Update Delay Register hours label to handle singular/plural correctly https://trello.com/c/7Ib0vf0v
- Add Delay Register count to Site Diary section header https://trello.com/c/7Ib0vf0v
- Fix top spacing above Add Delay button in Site Diary https://trello.com/c/7Ib0vf0v

---

September 2, 2026
Context: Site diary and pdf via mobile - allow user to PDF
- Add Delay Register section to exported Site Diary PDFs https://trello.com/c/3Yu1Rmfp
- Fix Activities-by-Trade alignment in exported Site Diary PDFs https://trello.com/c/3Yu1Rmfp
```

- Newest date first, `---` between dates (no trailing `---` after last date).
- Keep `Context: ` lines exactly as `Context: ` + Notion title (no dash prefix, no bullet).
- Keep task lines exactly as `- ` + summary + ` ` + Trello URL.
- Every `- ` line must be a committed code change, self-contained in one line, and must not start with Verify/Test/Push/MR.

Ask for confirmation before writing to Notion: "Push this to the Notion Daily Report page?" unless the user already said to sync.

## Step 3 — Resolve Notion pages

You need:

1. **Requirement / context pages** (one per Context group): For each Context, prefer the page ID/URL from this session (used by `/init-epic` or `/gitlab-mr`), or from `mcp__notion__search` matching branch name / recent commits / Trello URL. If not discoverable, use the Notion title as plain text (no link) and warn. Collect all distinct Notion pages for the date — do not limit to a single page.

2. **Daily Report page** (the destination):
   - Try in order: (a) MCP search for database/page titled `Daily Report`, `Daily Reports`, `Standup`, or similar; (b) page URL provided by user in this session or env `NOTION_DAILY_REPORT_PAGE_ID`; (c) ask user: "Please paste the Notion Daily Report page URL."
   - If MCP is unavailable, warn and keep the report as chat-only output (do not fail the display step).
   - Never invent a page ID.

## Step 4 — Put into Notion Daily Report page

> **Critical Notion formatting rule — must be followed for every write:**
> Daily report entries must use **exactly**:
> 1. One date heading block (`heading_2`).
> 2. One paragraph block immediately after it.
> 3. The paragraph must contain **all** `Context:` and `- ` lines.
>
> Never insert the report using Markdown where each `- ` starts on a new raw newline, because Notion converts those lines into `bulleted_list_item` blocks.
> When using Markdown content insertion, keep the report as **one paragraph** by joining lines with `<br>`:
> `Context: [Requirement](URL)<br>- First task https://trello.com/c/...<br>- Second task https://trello.com/c/...`
> Do not use `bulleted_list_item`, `numbered_list_item`, or standalone Markdown list lines anywhere for daily reports.

1. **Read the Daily Report page blocks** via `mcp__notion__get_block_children` / `mcp__notion__list_blocks` to see existing date headings and avoid duplicating a date.

2. **For each target date in the report:**
   - Locate `Heading 1` or `Heading 2` with the exact date string (e.g. `September 3, 2026`). If it exists, append/update content under it. If not, create it:
     - Create `heading_2` block with `rich_text: [{text: {content: "September 3, 2026"}}]`.
     - Then append **a single `paragraph` block** containing the entire list for that date — use literal `Context: ` / `- ` prefixes, NOT `bulleted_list_item` blocks, NOT multiple paragraphs, NOT standalone Markdown list lines. Build the paragraph's `rich_text` so each line is either `Context: <Notion Title>` or `- <summary> <Trello URL>` joined by `<br>` inside one paragraph. Example paragraph content for one date: `Context: Split Button for Upload Attachments is Missing in Multiple Modules<br>- Fix iPad attachment button width in Site Diary to prevent overflow on small screens https://trello.com/c/p47rWwhV<br>- Update shared attachment component sizing for iPad across all modules https://trello.com/c/p47rWwhV<br>Context: Add "Print" Button to Generated PDF Viewers Across Core Modules<br>- Fix Permit PDF landscape relayout triggered from print dialog https://trello.com/c/ODV5SCi2<br>- Paginate large custom-field tables in Permit PDF landscape export https://trello.com/c/ODV5SCi2`. When inserting via Markdown, use the same `<br>` joining: `Context: [Split Button...](<Notion URL>)<br>- Fix iPad attachment button width ... https://trello.com/c/p47rWwhV<br>- Apply shared ...`. For clickable links via API: annotate only the Notion title segment in `Context: ` lines with `link: {url: "<Notion Page URL>"}` and only the URL segment in bullet lines with `link: {url: "<Trello URL>"}`; keep prefixes (`Context: `, `- `) and summaries as plain text.
     - Do NOT use `bulleted_list_item` or `numbered_list_item` blocks anywhere for daily reports. Do NOT split Context groups into separate paragraphs — keep exactly one paragraph per date.
     - Order: newest date section at the top of the page. Achieve this by `append` for new dates then note to user that manual reorder may be needed if the API only appends — or use `mcp__notion__append_block_children` with `after` positioning if supported; otherwise append at bottom and warn "New date added at bottom — move to top if your page is newest-first."
   - If a date heading already exists, locate its single list `paragraph` immediately after the heading. **Append only new lines that are not duplicates** (match by Trello URL or summary, and for Context lines by Notion title) by updating that paragraph block via `mcp__notion__update_block` to extend its `rich_text` with `<br>Context: <new title>` or `<br>- <new summary> <URL>` inside the same paragraph. Do not create `bulleted_list_item` blocks or additional paragraphs for the same date — keep exactly one list paragraph per date; if no list paragraph exists yet, create one. Do not overwrite existing lines. When adding a new Context group to an existing date, append the `Context: ` line followed by its bullets in order.
   - For the `---` between dates in chat, do NOT create a `divider` block in Notion unless the page already uses dividers between date sections — if it does, insert `divider` between headings for consistency; otherwise headings alone are sufficient.

3. **Verify (required after every write):** Re-fetch the Daily Report page blocks via `mcp__notion__get_block_children` and confirm for each target date:
   - The date heading is followed by **exactly one `paragraph` block** containing all `Context:` and `- ` lines joined by `<br>` (rendered as line breaks inside the single paragraph).
   - There are **zero `bulleted_list_item` / `numbered_list_item` blocks** inside that date section (between this heading and the next heading).
   - The Notion page link(s) appear in the Context lines.
   If any `bulleted_list_item` / `numbered_list_item` blocks are detected in the date section, **immediately replace the date section**: delete the stray bullet/numbered blocks and update/recreate the single paragraph using `<br>` separators so the entire report lives inside one paragraph, then **re-fetch and verify again** until the section contains one paragraph and no bulleted-list blocks. Share the Daily Report page URL in the report only after verification passes.

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
