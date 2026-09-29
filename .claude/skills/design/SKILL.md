---
name: design
description: Use when turning PRODUCT.md into DESIGN.md — the human-gated visual and copy direction that unblocks UI-touching sub-tasks at /plan.
---

# /design — DESIGN.md

## Overview

`/design` turns an approved `docs/shipwright/PRODUCT.md` into `docs/shipwright/DESIGN.md`: the visual tone,
color, typography, layout, and tone-of-voice decisions that every UI-touching
sub-task is built against. This is a **human gate** — `docs/shipwright/DESIGN.md` is finalized
only after the user confirms the interview summary.

**REQUIRED SUB-SKILL:** Use `gated-doc-interview` for the interview protocol
(frontier rounds, not one question at a time; every question carries a
recommended answer plus freeform allowed; explicit-yes summary
confirmation as the gate; revision mode if the doc exists).

If a UI-reference research tool (e.g. Mobbin) is available, `/design` uses
it when proposing design directions from scratch; otherwise it falls back
to general design knowledge and web search.

## Prerequisites — fail loud

- `docs/shipwright/PRODUCT.md` must exist. If it does not, refuse and point to `/validate`.
- If `docs/shipwright/UX.md` exists (and is not a deferred placeholder), its
  interaction rules are **constraints, not suggestions**: every color,
  type, and spacing choice must satisfy each `UX-` rule on contrast, size, or
  legibility. Name those rules in the summary next to the values that meet
  them; a direction that cannot meet one is not offered.
- If `docs/shipwright/DESIGN.md` already exists, run in revision mode (per
  `gated-doc-interview`).

`/design` may run any time after `/validate` — in parallel with `/discover`,
`/architect`, or early `/decompose` calls. It does not wait on
`docs/shipwright/TECH_STACK.md` or `docs/shipwright/ARCHITECTURE.md`, but `/plan` refuses UI-touching sub-tasks
until `docs/shipwright/DESIGN.md` exists.

## Interview question areas

Adapt to context; skip what `docs/shipwright/PRODUCT.md` or the upstream docs already answer.

- Platform target — web app, mobile app, or both. Skip and read from
  `docs/shipwright/TECH_STACK.md` if it already exists and pins platform
  targets (its `## Platforms` section); otherwise ask directly. The answer
  is local to `docs/shipwright/DESIGN.md` and is not written back to
  `docs/shipwright/TECH_STACK.md`.
- Inspiration source — ask whether the user has a design idea, screenshots,
  a Mobbin/other reference link, or an existing brand/design system to
  match.
  - If yes: treat it as the anchor. Ask brief follow-ups deriving tone,
    color, typography, and voice from it (e.g. confirm a read like "minimal,
    dark-based, editorial") instead of asking the generic tone/color/type
    questions below from a blank slate. This subsumes the "existing brand or
    design assets" question — it is asked here, first, as a gate.
  - If no: ask permission to research — "Want me to research current UI
    patterns for a [category] [platform] app and propose a few design
    directions?"
    - If a UI-reference research tool (e.g. Mobbin) is available, use it,
      scoped to the product category (from `docs/shipwright/PRODUCT.md`)
      and the chosen platform. Otherwise fall back to general design
      knowledge and/or a web search for reference apps, and say so plainly
      (see the "Assets & references" provenance note in the template
      below) rather than presenting it as equivalent to tool-grounded
      research.
    - Propose 3–4 distinct, named directions (e.g. "Editorial minimal",
      "Bold playful", "Dense data-tool"), each a short paragraph covering
      mood, color direction, typography feel, and 1–2 named reference
      apps/screens it resembles.
    - The user picks one, or answers freeform.
    - A picked direction pre-fills tone, color, typography, and voice —
      proceed straight to the summary-confirmation gate rather than
      re-asking the bullets below individually; the summary must still
      show each filled-in value explicitly so the user can amend any one
      of them before confirming.
- Visual tone — offer concrete directions: minimal/utilitarian, playful/bold,
  editorial/content-first, dense/data-heavy — plus freeform. Skip if already
  answered via the inspiration-source branch above.
- Color direction — light or dark as the default scheme, and any brand color
  to anchor the palette. Skip if already answered via the inspiration-source
  branch above.
- Typography — offer to recommend a pairing suited to the chosen tone, or
  accept the user's own. Skip if already answered via the inspiration-source
  branch above.
- Tone of voice for copy — e.g. terse and direct, warm and encouraging,
  dry/technical — for buttons, empty states, errors. Skip if already
  answered via the inspiration-source branch above.

## Output: DESIGN.md

Write to `docs/shipwright/DESIGN.md`:

```markdown
# Design: <name>

## Platform
<web / mobile / both — plus, if both, note where component conventions diverge>

## Visual tone
<direction + 1–2 sentences of rationale>

## Color
<tokens — background, surface, text, accent — for light and dark scheme>

## Typography
<typeface pairing + scale (display / heading / body / caption)>

## Spacing & layout primitives
<spacing scale, container widths, radius, elevation>

## Component conventions
<how recurring patterns look and behave — buttons, forms, lists, modals.
For "both" platforms: one shared identity — add a web-vs-mobile note only
where conventions genuinely diverge (e.g. modals vs. native sheets, hover
vs. touch targets), not full parallel sections>

## Tone of voice
<copy style with 2–3 concrete examples (CTA, empty state, error)>

## UX constraints met
<each UX- rule this doc satisfies, and the token that satisfies it>

## Assets & references
<if user-supplied: links/paths to logos, screenshots, prior work this must
match. If agent-proposed: the chosen direction's name, the reference
apps/screens it drew from, and a one-line provenance note, e.g. "researched
via Mobbin", "researched via web search", or "researched via general design
knowledge — no UI-reference tool available on this agent">
```

Keep it under two pages. `docs/shipwright/DESIGN.md` is a living document: `/plan` and
`/review` cite it as ground truth for UI sub-tasks, and a contradiction found
during implementation is a design-flaw signal — revise via `/design` again,
never silently around it.

## After the gate

Once the user confirms and `docs/shipwright/DESIGN.md` is written, state its downstream role:
UI-touching sub-tasks are blocked at `/plan` without it. Then suggest — do not
run — the natural next step given which pipeline docs already exist:

- No `docs/shipwright/TECH_STACK.md` → `/discover`.
- `docs/shipwright/TECH_STACK.md` but no `docs/shipwright/ARCHITECTURE.md` → `/architect`.
- Both exist → `/decompose` (or `/build` if the backlog is already tracked
  as issues).
