# User Memory

User-scoped memory lives in `~/.claude/memory/`. It captures cross-project meta-learning — NOT project-specific facts (those belong in project memory and CLAUDE.md).

## Categories

| Category | Directory | Purpose |
|---|---|---|
| Mistakes | `mistakes/` | Errors to avoid repeating |
| Patterns | `patterns/` | Approaches that work well |
| Skill Gaps | `skill-gaps/` | Areas to proactively compensate for |
| Prompt Quality | `prompt-quality/` | What makes user prompts effective |
| Design Outcomes | `design-outcomes/` | Post-hoc evaluation of design decisions |

## When to Read

- **Session start**: MEMORY.md index is injected automatically
- **Before design phase**: read relevant `mistakes/` and `design-outcomes/`
- **Before implementation**: read relevant `patterns/`
- **When prompt is ambiguous**: check `skill-gaps/` to proactively fill in gaps
- **When memory is relevant**: briefly mention it — "Note: I've seen this pattern before — [references memory]. Adjusting approach accordingly."

## When to Auto-Capture (During Work)

- Catch yourself making an avoidable error → write to `mistakes/`
- Notice a recurring successful approach (2+ occurrences) → write to `patterns/`
- Had to ask 3+ clarifying questions on same topic → candidate for `skill-gaps/`
- Keep auto-captures lightweight — 2-3 sentences per field, don't interrupt workflow
- Always update MEMORY.md index when adding/removing a file

## When to Write via /retro

- All 5 categories are fair game
- Review session holistically — designs, implementation, review feedback
- Present proposed memory changes to user for approval before writing
- Surface feedback: prompt quality observations, skill gap insights, pattern confirmations
- Review existing memories for staleness during /retro

## Post-Completion Reflection

After completing `finishing-a-development-branch` skill, suggest running `/retro` to the user.

## Writing Rules

- Check for duplicates before creating — update existing memory if same topic
- Use descriptive filenames: `verb-noun.md` (e.g., `missed-error-handling.md`)
- Never store project-specific details — those belong in project memory
- Memories must be actionable, not just observations
- Keep MEMORY.md index under 100 lines

## Maintenance

- During `/retro`, review existing memories for staleness
- Archive/delete skill-gaps when growth signal is met
- Update/remove patterns when counter-evidence found
- If a mistake keeps recurring despite the memory, escalate the prevention strategy

## Templates

### Mistake (`mistakes/<name>.md`)

```
---
category: mistake
severity: low | medium | high
date: YYYY-MM-DD
tags: []
---

## What happened
<concrete description>

## Root cause
<why it happened>

## Prevention
<what to do differently>
```

### Pattern (`patterns/<name>.md`)

```
---
category: pattern
confidence: low | medium | high
date: YYYY-MM-DD
tags: []
---

## Pattern
<what works well>

## Evidence
<when/where observed, how many times>

## When to apply
<conditions where relevant>
```

### Skill Gap (`skill-gaps/<name>.md`)

```
---
category: skill-gap
date: YYYY-MM-DD
tags: []
---

## Observation
<what the user tends to miss>

## How Claude should compensate
<proactive actions>

## Growth signal
<what indicates this gap is closing>
```

### Prompt Quality (`prompt-quality/<name>.md`)

```
---
category: prompt-quality
effectiveness: poor | fair | good | excellent
date: YYYY-MM-DD
tags: []
---

## Prompt pattern
<what the user said/structured>

## Outcome
<what happened>

## Insight
<why it worked or didn't>
```

### Design Outcome (`design-outcomes/<name>.md`)

```
---
category: design-outcome
result: success | partial | failure
date: YYYY-MM-DD
tags: []
project: <which project>
---

## Decision
<what approach was chosen>

## Context
<why, what alternatives existed>

## Outcome
<what actually happened>

## Lesson
<what to carry forward>
```
