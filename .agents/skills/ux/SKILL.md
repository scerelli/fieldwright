---
name: ux
description: Use when turning PRODUCT.md and DOMAIN.md into UX.md, the human-gated context of use, critical-task budgets, numbered falsifiable interaction rules, and system states that UI sub-tasks are built and reviewed against.
---

# /ux: UX.md

`/design` decides how the product looks. `/ux` decides how it has to work
for a real person in a real place: gloves on, sun on the screen, one hand
holding a clipboard, no signal, a cheap phone at 15% battery. Those
constraints are the product for field software, and a visual spec cannot
carry them. **Human gate.**

`UX.md` is written as **rules that can fail**, numbered so criteria cite
them: "touch targets are ≥ 48 dp (UX-003)" can be proven; "easy to use in
the field" cannot.

**REQUIRED SUB-SKILL:** `gated-doc-interview`.

## Prerequisites: fail loud

`PRODUCT.md` must exist (→ `/validate`); `DOMAIN.md` should (→ `/model`),
because critical tasks and states are named in the glossary's words. If
`TECH_STACK.md` exists, read its Platforms: rules use that platform's units
(dp/pt) and conventions. If `UX.md` exists, revision mode.

## Find facts first

Platform guidance (minimum touch targets, contrast ratios, accessibility
baselines) is looked up, not asked: web-search the current Material / Human
Interface / WCAG numbers and put them in the recommendation with their
source.

## Interview areas

- **Context of use**: where and when the product is used: light, weather,
  temperature, noise, motion, gloves, one or two hands, eyes on the screen or
  on the subject, session length, interruptions. **Connectivity** and
  **devices** (the low end of the range users actually carry, not the
  developer's phone) belong here too.
- **Users**: skill with the domain and with phones; who is trained and who
  is not; languages.
- **Critical tasks**: the 3–6 tasks that decide whether the product is
  usable, each with a frequency and a **budget**: taps, seconds, or screens,
  and whether it must work one-handed or without looking. Recommend budgets
  from the paper or tool the product replaces: it must not be slower than
  paper.
- **Interaction rules**: the falsifiable rules every screen obeys: target
  size, text size, contrast, input methods (pick over type; typed search by
  abbreviation), confirmation and undo for destructive actions, what must
  never need a network. Each gets its proof hint: `test` (measurable in a
  widget or integration test), `render` (visible), `inspect` (a token value).
- **System states**: offline, syncing, sync failed, conflict, empty, error,
  missing sensor or permission, low battery, storage full. For each: what the
  user sees and what they can still do. The default recommendation is that
  sync and save state are **always visible** and that no state loses data.
- **Data safety**: autosave cadence, crash and kill recovery, what happens
  to a half-entered record, when data is "safe".
- **Accessibility & localization**: baseline level, dynamic type, languages,
  units, date and coordinate formats.

## Numbering

Rules are `UX-001`, `UX-002`, … in creation order, **never reused or
renumbered**; a dropped rule stays, marked `(retired)`.

## Output: write to `docs/shipwright/UX.md`

```markdown
# UX: <name>

## Context of use
<environment, connectivity, device range, session shape>

## Users
<who, what they know, what they don't>

## Critical tasks
| Task | Frequency | Budget | Rules |
|---|---|---|---|
| <task, in glossary terms> | <per session / day> | <≤ n taps, ≤ n s, one-handed> | UX-00n |

## Interaction rules
| ID | Rule (falsifiable) | Why | Proof hint |
|---|---|---|---|
| UX-001 | <rule with a number or a named behavior> | <the context that demands it> | test / render / inspect |

## System states
| State | Trigger | The user sees | The user can still | Rules |
|---|---|---|---|---|

## Data safety
<autosave, recovery, when data is safe>

## Accessibility & localization
<baseline, languages, units, formats>

## Open questions
```

**Cap at three pages.** `/plan` and `/review` read it for every UI sub-task.

## After the gate

Write, commit `docs(ux): <what changed>`, push. Where `DESIGN.md` exists,
name every `UX-` rule it must now satisfy (contrast, size, legibility) and
suggest a `/design` revision if any token breaks one; never edit `DESIGN.md`
from here. In revision mode, search open issues citing changed or retired
IDs, as `/model` does.

Suggest, do not run, `/design` if `DESIGN.md` is missing or deferred,
otherwise `/decompose docs/shipwright/PRODUCT.md`.

## Common mistakes

- Rules without a number or a named behavior ("large buttons") → not
  falsifiable, so no criterion can cite them.
- Designing for the developer's phone and office → the context of use is the
  whole point of this document.
- Leaving system states for later → offline and sync states designed late
  are designed as error messages.
- Visual decisions (palette, type pairing) → `/design`. Here: only what the
  visual layer must satisfy.
