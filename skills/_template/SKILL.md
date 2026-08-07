---
name: _template
description: One-line summary of when Claude should reach for this skill and what it does. Be specific about trigger phrases/situations — this is what gets matched against, so write it for that purpose, not as marketing copy.
---

# _template

Replace this file's content when you copy the folder for a new skill. Rename the
folder to your skill's kebab-case name and update `name:` above to match it exactly
— the validator checks that they agree.

## When to use this

Describe the concrete situations that should trigger this skill. Prefer specific
trigger phrases or scenarios over vague descriptions.

## Instructions

Step-by-step guidance for what Claude should do once this skill is loaded. Keep it
procedural and concrete — this is the part that actually changes Claude's behavior.

## Supporting files (optional)

If this skill needs reference material, helper scripts, or templates, put them in
subfolders next to this file, e.g.:

```
skills/your-skill-name/
  SKILL.md
  references/some-reference.md
  scripts/helper.py
```

Keep SKILL.md itself focused — offload long reference material to files under
`references/` and point to them by path rather than inlining everything here.
