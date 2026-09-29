---
name: validate
description: Use when producing an approved PRODUCT.md — from IDEA.md under /init --full, or from scratch under /init — the product-level validation gate of the pipeline, before any decomposition into epics.
---

# /validate — PRODUCT.md

Produces the approved PRD every later step treats as ground truth, sharpening
`IDEA.md`'s Lean Canvas sketch where one exists. **Human gate**: written only after the user
confirms the interview summary.

**A PRD describes the whole intended product, not just its first slice.** v1
is the nearest phase of a roadmap. A doc that only answers "what's in v1" and
drops the rest into Out of scope is a scope doc, not a PRD.

**REQUIRED SUB-SKILL:** `gated-doc-interview`.

## Prerequisites — fail loud

If `PRODUCT.md` already exists, run in revision mode.

**A missing `IDEA.md` is not an error** — `/init` skips it unless `--full`,
and a canvas is an input, not a gate. Absent one, cover its ground (problem,
customer segments, UVP, solution sketch) inside this interview instead of
refusing. Only `/init --full` guarantees one exists, because it runs `/ideate` first.

## Interview areas

Read `IDEA.md`'s canvas **first if it exists**. This interview *extends and
sharpens* its Problem, Customer Segments, UVP, and Solution boxes — it never
re-asks what the canvas already settles. With no canvas, those same four are
the opening questions rather than skipped ones.

- **Problem statement & elevator pitch** — the specific pain in concrete
  terms (not "users are frustrated"), who feels it and how often, plus a 2–3
  sentence pitch.
- **Current landscape & alternatives** — how people solve this today and why
  it falls short. **Do light web research rather than guessing**; "no direct
  alternatives found" is a valid answer. Skip only for a purely internal tool
  with no external market.
- **Goals & success metrics** — concretely for v1, then separately for the
  product past v1.
- **Target users & personas** — one primary persona (role, context, the job
  they're doing). A secondary **only if genuinely distinct** in need or
  workflow; never pad with a lookalike.
- **Key user scenarios** — the handful of end-to-end journeys, primary
  persona first, as user stories.
- **Scope & roadmap** — expand the Solution box into the full phased picture:
  **Now (v1/MVP)** · **Next** (deferred, not abandoned) ·
  **Later** (speculative is fine). Cap at three horizons — anything vaguer
  belongs in Open questions. **Every feature raised must land in exactly one
  of Now/Next/Later/Out of scope — never silently dropped.**
  If Now/v1 has UI at all, ask whether it should also carry a foundational
  line — app shell, navigation, and the design tokens `/design` will settle,
  wired into the component registry `/discover` pins — so `/decompose` mints
  one small Epic for it instead of each feature Epic re-deriving the theme.
  Infrastructural rather than user-facing, but name it here anyway:
  `/decompose` infers one when it's missing, and an inferred Epic is a
  fallback, not a plan.
- **Non-functional needs** — performance, security, compliance, scale. Skip
  what's genuinely unknown rather than guessing.
- **Out of scope, permanently** — what this will *never* do, distinct from
  deferred. Sharpen against real candidates raised in the interview, not a
  boilerplate list.
- **Risks & mitigations** — the riskiest assumption (often the canvas's
  least-validated box), plus material market/technical/adoption risks, each
  with a one-line mitigation or "monitor".
- **Dependencies & constraints** — external services, datasets, other teams;
  sharpen the canvas's Constraints note.
- **Milestones** — **name each roadmap phase**, because these become real
  GitHub milestones that `/decompose` assigns items to. Ask for a short name
  per phase (`v1.0 — MVP`, `v1.1`, `Backlog`) and an optional target date;
  "no fixed timeline" is fine and leaves the date empty. Default to one
  milestone per Now/Next/Later horizon unless the user wants finer slices.
- **Rough scope size** — weekend, multi-month, or ongoing?
- **Open questions** — genuinely undecided items, flagged for `/model`, `/discover`,
  `/architect`, or `/design` rather than forced to an answer here.

Where an answer affects feasibility or market fit, do light web research to
sanity-check competitors or technical risks before proposing options. This
product-level research is what distinguishes `/validate` from the lighter
coherence checks `/ideate` runs — **never call those "validation."**

## Output — write to `docs/shipwright/PRODUCT.md`

```markdown
# Product: <name>

## Vision & problem statement
<one paragraph: what it is, who for, why now — grounded in the Problem,
Customer Segments and UVP boxes — plus a 2-3 sentence elevator pitch>

## Current landscape & alternatives
<how people solve this today and why it falls short — "no direct alternatives
found" is valid; omit only for a purely internal tool>

## Goals & success metrics
<measurable objectives for v1, and separately beyond v1>

## Target users & personas
<primary persona: role, context, the job being done. Secondary only if
genuinely distinct>

## User scenarios
- As a <user>, I want <capability>, so that <benefit>.

## Scope & roadmap
### Now — v1 / MVP
<explicit in-scope feature list>
### Next
<deliberately deferred past v1, not abandoned>
### Later
<further-out, lower-confidence direction; speculative is fine>

## Non-functional requirements
<performance, reliability, security, scale, compliance — write "not yet
known" rather than omitting the section>

## Out of scope
<explicit, permanent exclusions — distinct from Next/Later>

## Risks & mitigations
<riskiest assumption + cheapest way to test it, plus other material risks,
each with a one-line mitigation or "monitor">

## Assumptions, dependencies & constraints
<platform/timeline/team constraints; external dependencies>

## Milestones
<one row per roadmap phase — these become GitHub milestones that /decompose
assigns Story/Task/Bug items to; leave Target empty for "no fixed timeline">

| Milestone | Covers | Target |
|---|---|---|
| v1.0 — MVP | Now | <YYYY-MM-DD or —> |
| v1.1 | Next | <YYYY-MM-DD or —> |
| Backlog | Later | — |

## Scope size
<weekend / multi-month / ongoing, with rough effort drivers>

## Open questions
<undecided items to revisit at /model, /discover, /architect, /ux, or /design>

## Appendix
<links to research, competitor pages, or the canvas — omit if none>
```

**Size it to Scope size, capped at three pages.** A weekend project's version
can answer several sections in one line or mark them "N/A at this scope."
`/decompose` re-reads this file for every split, so its length is a live cost,
not a one-time writing cost.

`PRODUCT.md` is living: later commands may append scope notes, and Next/Later
items graduate into Now as they're picked up.

## Common mistakes

- Re-interviewing the whole canvas from scratch → only extend or sharpen.
- Scoping only v1 and calling it the product → everything raised lands
  somewhere explicit.
- Collapsing Next/Later into Out of scope → "not yet" and "never" are
  different answers, and `/decompose` needs the distinction.
- Omitting Non-functional requirements because nothing is known → write "not
  yet known — see `/architect`"; later skills expect the section.
- Treating Out of scope as optional → `/decompose` checks every proposed
  child against it; thin here makes scope creep invisible later.
- Padding personas with a lookalike secondary.

## After the gate

Suggest, do not run, `/model`, unless running inside `/init`, which
continues automatically.
