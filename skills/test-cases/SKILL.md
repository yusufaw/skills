---
name: test-cases
description: Generate manual test cases from the current chat context and an optional Notion requirement description, then write a checkable test list to a Notion page. Use when the user asks for test cases, a QA checklist, or /test-cases. Does not implement or execute automated tests.
---

# Test cases

Turn the feature, fix, or requirement discussed in this conversation into actionable manual test cases. Use the chat as the primary context, optionally supplement it with a Notion description, and write the cases as native Notion checkboxes so the user can track completion.

## Gather context

- Read the relevant conversation: intended behavior, scope, acceptance criteria, bug reproduction steps, decisions, and later corrections. Exclude abandoned approaches and unrelated work.
- Use a Notion requirement page already identified for this work, or one supplied with the request. Read its title, description properties, and body through the available Notion tools. Follow pagination and nested blocks where needed to read the relevant requirements. A source page may differ from the destination page; respect any explicit destination.
- Notion is an optional source. Do not require a Notion description when the chat contains enough context. Do not search unrelated workspace pages for extra requirements.
- Treat the user's latest explicit decisions as authoritative. If the chat and Notion disagree about behavior without a clear resolution, ask about the specific conflict; generate the unaffected cases in the meantime.
- Do not invent product rules or expected results. List unresolved requirements as open questions outside the checklist, and omit cases whose expected outcome depends on those answers.
- If neither source explains what should be tested, ask for the feature or requirement and avoid producing a generic checklist.

## Generate the checklist

Write concrete manual cases in plain language, grouped by feature or flow when useful. Cover the acceptance criteria and the reported bug first. Include relevant validation, failure paths, boundaries, permissions, persistence, and regressions only when supported by the scope. Include platform or device variations when the context makes them relevant; do not add a fixed matrix or a target case count.

Consider these edge cases according to the current project's supported platforms, conventions, and the feature being tested. They are prompts for coverage, not mandatory cases or a matrix to exhaust:

- Light and dark mode: readability, contrast, and themed components.
- Regular phone and iPad layouts: sizing, spacing, navigation, and device-specific controls.
- Portrait and landscape orientation: layout, overflow, and state preservation when rotating.
- Empty state: no records, results, or optional content.
- Error state: useful feedback and recovery for relevant failures.
- No internet connection: offline behavior, connection loss, and retry or recovery where applicable.
- Loading state: progress feedback and prevention of unintended repeated actions.
- Long text content: wrapping, truncation, overflow, and access to the full value.
- Semantics identifiers: required identifiers on affected controls and their correctness and uniqueness where the project's accessibility or UI automation conventions require them.
- Similarities with the web version: consistency of shared behavior, terminology, and outcomes when a corresponding web flow exists. Respect intentional platform differences; do not assume the web version is authoritative or claim parity without evidence.

Select only applicable checks using the chat, available requirements, and known project context. Do not assume support for a theme, device, orientation, offline workflow, or web counterpart. If a comparison needs unavailable evidence, identify the gap rather than inventing the expected behavior.

Each checkbox represents one independently verifiable outcome and includes:

- A short scenario title.
- Preconditions or test data when necessary.
- The actions to perform, in order.
- An observable expected result.

Use this compact format in chat and Markdown-capable Notion tools:

```markdown
## Test Cases

### Attachment upload

- [ ] TC-001 — Upload a supported file. Given an editable record, open Attachments, choose a supported file, and save. Expected: the attachment appears once and remains after reopening the record.
- [ ] TC-002 — Cancel file selection. Open Attachments, open the file picker, and cancel. Expected: the record's attachment list stays unchanged.
```

Adapt the detail to the task; use child paragraphs or numbered steps inside a case when a single line becomes hard to follow. Keep only the parent case checkable. Use stable IDs within this checklist, continuing existing numbering for new cases on reruns. Do not mark cases done based on generated text or earlier implementation claims. This skill generates and reviews cases; executing them requires a separate request.

## Resolve the destination

- Prefer the explicit destination supplied by the user. Otherwise use the single Notion requirement page clearly associated with the current task as both source and destination.
- If no destination is known or several pages are plausible, show the generated checklist in chat and ask for the target Notion page URL. Do not create a page or select an arbitrary destination.
- A request to generate and write/sync test cases, including invoking this skill for its normal workflow, authorizes writing the checklist to the resolved page. Proceed without an additional approval prompt. Respect requests for a draft or chat-only output.

## Write to Notion

1. Discover the connected Notion tools and use the supported read/edit operations. Read the destination and locate existing test case blocks or sections for the current feature, even if their heading differs from `Test Cases`. Read all relevant cases, child steps, notes, IDs, and checked states before editing. Distinguish them from checklists for unrelated work.
2. If there is no relevant section, append a `Test Cases` heading and the checklist without replacing the requirement or unrelated content. On a page covering several features, label this checklist with the current feature so it is distinguishable.
3. Create **native, initially unchecked to-do blocks**, not text that merely contains `[]`. With block APIs, use `type: "to_do"` and `to_do.checked: false`. With Markdown editing tools, use `- [ ]` syntax in the tool's supported format. Never put the checklist inside a code block or flatten it into a paragraph.
4. Review existing cases against the latest resolved chat and requirement context. Compare scenarios, preconditions, actions, and expected results rather than titles alone. Keep valid cases, improve incomplete or unclear cases, rewrite outdated cases, and add missing coverage. This review and revision is part of the normal workflow and needs no extra approval when the target and expected behavior are clear. Resolve ambiguous requirements as described above before making dependent changes.
   - Prefer editing existing blocks in place and retain IDs for the same scenario. Preserve useful notes and evidence. Rewrite the relevant checklist section when necessary for clarity or substantial scope changes, carrying forward valid coverage, IDs, notes, and completion states. Leave unrelated sections untouched.
   - Preserve checked states for unchanged cases and wording-only edits. If preconditions, actions, or expected results change materially, set the revised case to unchecked because the previous completion no longer verifies it. Briefly note that it needs retesting and why, preserving any prior result as historical evidence.
   - Consolidate duplicates without losing distinct coverage or notes. Do not infer completion from a checked duplicate when its scenario or expected result differs. Mark obsolete cases as superseded or out of scope outside the active checklist, retaining their IDs and history rather than silently discarding them.
   - Avoid duplicate sections and cases. If the existing list already matches the current context, leave it unchanged.
5. After writing, read back the affected section. Confirm active cases are native to-dos with the intended content, IDs, and checked states; new and materially revised cases are unchecked; unchanged completed cases remain checked; and notes, history, and unrelated content are retained. Check that the active list has no duplicate scenarios or obsolete cases. If a write times out or returns an uncertain result, read before retrying so a successful write is not duplicated. Make only targeted repairs; if verification still fails after a repair, stop and report what remains unverified.

If Notion is disconnected, inaccessible, or cannot create native checkboxes with the available tools, provide the checklist in chat using `- [ ]` for copying and explain what prevented the sync. Keep useful chat-based cases if the optional source page cannot be read, and disclose the missing source. Never claim a Notion write succeeded without verifying it.

## Report back

Link the destination page and summarize cases added, revised, retained, consolidated, or superseded, including any completed cases reset for retesting and the reason. Mention unresolved questions or sync limitations when applicable. If the review required no changes, say so. For chat-only output, show the complete checkable checklist.
