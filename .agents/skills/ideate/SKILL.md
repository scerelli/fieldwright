---
name: ideate
description: Use when adding a single new item to the backlog — a brand-new product idea (IDEA.md), an epic, a story/task/bug, or a sub-task — at any point in the pipeline.
---

# /ideate — single-item ideation

The **recursive single-item entry point**, meant to be called often. Resolves
a target, runs a short interview, creates exactly **one** item.

Wants a bulk split? Hand off to `/decompose`. **Never loop `/ideate` to
simulate it.**

**REQUIRED SUB-SKILLS:** `gated-doc-interview` for every interview below,
`gh-sub-issues` for all creation and queries.

## Target resolution — in order

| Condition | Creates |
|---|---|
| no `docs/shipwright/PRODUCT.md` | **IDEA.md** (level 1) |
| PRODUCT.md exists, no target arg | **Epic** |
| target is an `epic` | **Story/Task/Bug** |
| target is a `story`/`task`/`bug` | **Sub-task** |
| target is a `sub-task` | **refuse** — nothing lives below Sub-task |

Resolve the type with `../gh-sub-issues/scripts/issue.sh type <n>`. Missing
or unexpected type → fail loud, never guess.

## Level 1 — new product idea

`docs/shipwright/IDEA.md` is a **Lean Canvas**: an assumption-driven sketch,
not a validated plan. "Unknown — assumption to test" is legitimate for any
box; validation is `/validate`'s job.

**Step 0 — ask before anything else.** No project exists yet, so there is
nothing to read. **Do not inspect the repo, and do not propose an idea on the
user's behalf.** Ask exactly one question — *"What's the rough idea?"* — and
wait. That answer is the seed; every later question interrogates *it*.

Then run `gated-doc-interview` over these areas **in dependency order** —
later boxes lean on earlier ones:

1. **Customer Segments** — who concretely (not "everyone").
2. **Problem** — their top 1–3.
3. **Existing Alternatives** — how they cope today.
4. **Unique Value Proposition** — the one differentiating message.
5. **Solution** — top 1–3 features against the top problems.
6. **Unfair Advantage** — "none yet" is fine.
7. **Channels** — how this reaches the segment.
8. **Revenue Streams** — "n/a" is fine.
9. **Key Metrics** — what would show it's working.

The order is a dependency order, not a preference — see `reference.md`.

Ask **Success shape** and **Constraints** (platform, timeline, solo vs. team)
in round 1 — both independent of the canvas.

On confirmation, write `docs/shipwright/IDEA.md` and suggest — don't run —
`/validate`. If it already exists, use revision mode.

### Output — keep every box to short phrases; a canvas is sticky notes

```markdown
# Idea: <name>

| Problem | Solution | Unique Value Proposition | Unfair Advantage | Customer Segments |
|---|---|---|---|---|
| <top 1-3 problems> | <top 1-3 features> | <the one differentiating message> | <what can't be copied — or "none yet"> | <target segment> |
| **Existing alternatives:** <how they cope today> | **Key Metrics:** <numbers that show this works> | | **Channels:** <how this reaches them> | **Early adopters:** <first specific subset> |

| Cost Structure | Revenue Streams |
|---|---|
| <rough fixed/variable costs> | <how this earns — or "not applicable"> |

## Notes
- **Success shape:** <narrow utility or broad product>
- **Out of scope (early):** <what this idea explicitly is not>
- **Constraints:** <platform, timeline, solo vs. team>
```

## Levels 2–4 — the shared procedure

1. **Show siblings as context** (plus `PRODUCT.md`'s scope sections at the
   top tier).
2. **Interview** for that level's template fields.
3. **Coherence check** (all tiers above Sub-task) — see below.
4. **Confirm, then create** as a sub-issue of the target, typed — plus a
   **`--milestone`** for a Story/Task/Bug, matching its `PRODUCT.md` roadmap
   phase. Epics and Sub-tasks get no milestone; see `CONVENTIONS.md`.

Use `decompose`'s templates **byte-identical** — Step 3 for Epic, Step 4 for
Story/Task/Bug, Step 5 for Sub-task.

**Level 3 — classify first** per `CONVENTIONS.md`'s Classifying an item, and
follow its **Voice follows type** rule: Given/When/Then is `Story`'s alone.

**Level 4 — two fields are mandatory**: explicit falsifiable **acceptance
criteria**, one claim each and worded so their proof type is obvious
(`CONVENTIONS.md`), and the **expected files/modules** list. A `Spike` Sub-task
also needs `decompose`'s Question and Timebox fields — `/spike` refuses without
them. `/plan` refuses a
Sub-task without both, so a Sub-task lacking either is not creatable — keep
interviewing. Then run the file-overlap check against every sibling: on
overlap, record a native blocked-by link (default) or ask a quick yes/no if
it looks coincidental. A dependency that would close a cycle is refused, with
the cycle explained.

## Coherence check (levels 2–3)

Check the draft against the parent's stated scope and its siblings for
duplication or overlap. **Never call this "validation"** — that term is
reserved for product-level `/validate`.

Surface every conflict *inside* the confirmation prompt with a recommended
option: *"overlaps epic #4 — proceed / merge / revise? 💡 Recommended: merge
— both describe the same capability from different angles."* The human
decides. Never block silently, never resolve an overlap yourself.

## Labels and milestones must exist first

No `preflight` runs here, and `gh issue create` fails outright on a label or
milestone it doesn't know:

```bash
../gh-sub-issues/scripts/issue.sh ensure-labels
# Story/Task/Bug only. Pass the date too — ensure-milestone is create-only,
# so a milestone first created without one can never be given a date later,
# and /recommend orders phases by due date.
../gh-sub-issues/scripts/issue.sh ensure-milestone "<milestone-name>" --due <target-date>
```

No Milestones section in `PRODUCT.md` → say so and create without one; never
invent a phase name.

## The gate: confirm-before-create

Levels 2–4 gate on an explicit confirmation of the full draft — title, body,
parent, type, dependencies, and any coherence conflicts —
immediately before creation. **Nothing is created before that yes.** Amend →
re-confirm.

## Skipping the interview

Substance passed inline (`/ideate 12 "real-time notifications"`) → draft from
it directly, confirm, create. Level 4 still requires criteria and a files
list; interview only for what's missing.

## Common mistakes

- Inspecting the repo to infer a Level 1 idea before asking → Level 1 is
  pre-project; the idea comes from the user's words first.
- Looping `/ideate` to bulk-split → hand off to `/decompose`.
- Creating anything before the confirmation gate.
- Calling the coherence check "validation" → reserved term.
- Creating a Sub-task without falsifiable criteria or a files list → `/plan`
  will refuse it later; catch it here.
- Ignoring file overlap between sibling Sub-tasks → ordering becomes implicit
  and racy.
- Writing IDEA.md as flat prose → the nine boxes carry dependencies that
  prose loses and `/validate` then has to re-derive.
- Forcing confident answers on Unfair Advantage or Revenue Streams → "none
  yet" is honest this early; don't stall chasing certainty.
