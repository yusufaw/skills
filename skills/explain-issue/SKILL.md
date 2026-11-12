---
name: explain-issue
description: Explain the current issue concisely in plain language for stakeholders using a fixed Root cause, Fix, and MR format, including the MR title and URL when available. Use when the user asks for a root cause and fix explanation, a bug resolution summary, or /explain-issue. Drafts text without publishing it.
---

# Explain issue

Write a ready-to-paste explanation of why the current issue happened and how it was addressed. Make it suitable for a stakeholder comment, message, or status update. Write for someone who does not read code or know the conversation history.

## Use the current context

- Read the relevant conversation for the reported symptom, confirmed cause, actual fix, and latest decisions. Use the overall issue context rather than only the latest message or commit. Exclude abandoned theories and unrelated changes.
- Use the chat when it supplies enough evidence. If necessary and available, inspect the relevant code or diff to clarify the explanation; do not infer the cause merely from a commit title or branch name.
- Distinguish confirmed causes from suspected ones. If the cause is unconfirmed, say so briefly rather than presenting a guess as fact. If the issue itself is unclear, ask which issue to summarize.
- Describe an implemented fix as implemented and a proposed fix as proposed. Do not imply testing, approval, deployment, or release unless supported by the context.

## Write the explanation

- Be as concise as possible while explaining both cause and fix. Put a short explanation after each label: why the issue occurred after `**Root Cause:**`, then what changed to address it after `**Fix:**`.
- Name the affected feature and describe the cause in everyday terms. Explain the mechanism rather than just repeating the symptom. For example, use "The screen kept the previous record's values when opening another record" rather than "There was a state management issue."
- Describe the fix through its effect on the product. Avoid file names, classes, functions, APIs, frameworks, and jargon such as race condition or cache invalidation. Translate necessary technical details into language a non-engineer can understand.
- Use the language of the user's request unless another language is requested. Keep the tone clear, factual, and professional. Avoid blame, filler, and claims such as "fully fixed" or "works perfectly."
- Add detail only when needed to understand a distinct cause or fix. Do not add a testing checklist, implementation history, or generic background.

## Include the MR title and URL

- Reuse the relevant MR URL already supplied by the user or returned by a successful tool call in this conversation. A link already read from a task's Notion page or other connected source can also be used when its relationship to this fix is clear.
- Prefer the MR containing the described fix rather than an unrelated or earlier MR. Include multiple MRs only if the fix spans multiple MRs.
- Put `**MR:**` on its own line, followed by the MR title on the next line and its full URL on the following line. For multiple relevant MRs, repeat the title and URL pair beneath the same `**MR:**` label.
- Always keep the `**MR:**` label. If no relevant MR is available, leave it blank with no title, URL, or placeholder beneath it. If only one MR detail is available, include that detail and leave the missing detail blank. Do not invent a title or URL, ask for a link, or create an MR just to finish the explanation. Do not fetch external sources solely to fill missing MR details unless requested.

## Output

Return only the finished explanation, without a preamble, quotation marks, code fence, or extra headings. Use double asterisks to make all three labels bold, including their colons. Separate the Root Cause, Fix, and MR sections with one blank line. Always use this exact order and line structure, replacing the bracketed fields with the supported details:

```text
**Root Cause:** [cause]

**Fix:** [fix]

**MR:**
[title]
[URL]
```

Example when supported by the context:

```text
**Root Cause:** The form kept the previous record's values when another record was opened.

**Fix:** The form now clears those values before loading the selected record.

**MR:**
Clear previous values when opening another record
https://gitlab.com/group/project/-/merge_requests/123
```

Draft the explanation in chat. Publishing it to an external service or creating a file requires an explicit request.
