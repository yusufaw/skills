---
name: screenshot-captions
description: Write a concise stakeholder preview sentence to accompany screenshots, using the overall work context from the chat. Use when the user asks for screenshot captions or sentences to introduce a preview of their work. Does not require screenshots, capture them, or generate images.
---

# Screenshot captions

Generate a ready-to-post stakeholder message introducing the feature or changes discussed in this conversation. The message will accompany screenshots the user chooses; it should describe the overall work rather than the latest screenshot or commit.

## Use the work context

- Read the relevant conversation to identify the feature or fix, the user-visible result, and the latest decisions. Use the full relevant work context, not just the last action. Exclude abandoned approaches and unrelated work; do not present planned behavior as already available.
- Screenshots are optional. Do not request, capture, or inspect the latest screenshot as a prerequisite, and do not generate a caption for each image by default. The message should work as an introduction to a group of screenshots.
- Do not inspect Git history or anchor the message to the latest commit. The chat context is sufficient when it explains the work.
- If the feature or intended preview is unclear from the conversation, ask for a brief description of what the stakeholder should see. Do not require an image.

## Write the message

- Default to one sentence, as concise as possible, ready to paste into a stakeholder update. Follow the requested language and tone; otherwise use the language of the user's request and a plain, friendly professional tone.
- Lead with a natural preview introduction such as "Here is a preview of..." followed by the feature or update. Stop there when it communicates the point. Add only the shortest detail needed to identify the change; omit extra explanation, benefits, and repeated context unless requested.
- Describe the overall feature in familiar product terms. Keep file names, classes, APIs, frameworks, commit references, and internal implementation details out of the message.
- Do not refer to "the last screenshot," image numbers, or a specific image's details unless the user explicitly requests image-specific captions. Mention devices, themes, or orientations only when they help explain the work being previewed and are supported by the context.
- Avoid generic praise and unsupported claims such as "works perfectly," "fully fixed," or "fully tested." Do not imply the preview is deployed, approved, or complete unless the context establishes that status.
- Provide one finished message by default. Generate alternatives or separate captions only when requested.

## Output

Return only the ready-to-post message, without a heading, explanation, image labels, or quotation marks.

Example when the context supports an attachment menu update:

```text
Here is a preview of the updated attachment menu for iPhone and iPad.
```

Return the message in chat. Publishing it, writing it to Notion, creating files, or capturing screenshots requires an explicit request.
