---
name: decompose
description: Use when bulk-splitting a validated target (PRODUCT.md, an Epic issue, or a Story/Task/Bug issue) into its full next level of the Epic/Story-Task-Bug/Sub-task hierarchy — initial breakdown or bulk catch-up, never a single addition.
---

# /decompose — bulk split to the next level

Splits one target into its **full** next level in one pass:

| target | produces |
|---|---|
| `PRODUCT.md` | **Epic** issues |
| Epic | Story/Task/Bug issues (classified by content) |
| Story/Task/Bug | Sub-task issues, with criteria and a dependency graph |

**Three tiers, always** — `PRODUCT.md` splits straight into Epics
(`CONVENTIONS.md`). A single new item under an already-decomposed parent →
`/ideate <target>`. **Never bulk-regenerate for one addition.**

**REQUIRED SUB-SKILLS:** `preflight` (`decompose` mode) before resolving the
target, `gh-sub-issues` for all creation and queries.

**Flag:** `--fast` skips preflight's target-doc gate check — explicit human
opt-in, never inferred.

## Step 1 — Resolve the target

- **Path ending `.md`** — refuse if missing or ungated (`/validate` for
  `PRODUCT.md`). Splits into **Epics**.
  **Ask** whether to split to Epics or shallower (straight to Story/Task/Bug,
  skipping the Epic tier) — do not decide it for the user.
  For a skipped Epic tier, landing-tier issues **omit `--parent` entirely**
  (`reference.md`). Type and milestone still apply.
- **Issue number** — read its type label. `epic`/`story`/`task`/`bug` select
  the split; `sub-task` → refuse, nothing exists below it. Any other or
  missing type → refuse, reporting what was found.
- **Anything else** → refuse, naming the accepted forms.

**Never guess the split level from the argument's shape.**

## Step 2 — Check for existing children

Query the target's sub-issues. A `PRODUCT.md` target has no parent issue, so
check the repo's open issues at the tier this split produces — `epic`.

- **None** → full initial breakdown.
- **Some** → never silently regenerate. List them (number, title, state) and
  ask: *bulk catch-up* (only the missing remainder) or *one addition* (stop,
  hand off to `/ideate`).

## Shared rules for every split

**Milestone — Story/Task/Bug tier only.** Assign the milestone matching the
item's `PRODUCT.md` roadmap phase, taking **both name and date from that
Milestones table**, never a literal.
Omit `--due` when Target is empty or a placeholder dash (`—`/`-`); the API
rejects a non-date and aborts the split mid-run.

```bash
../gh-sub-issues/scripts/issue.sh ensure-milestone "<milestone-name>" --due <target-date>
```

Epics and Sub-tasks get **none**.
No Milestones section → say so and create without one; never invent phase
names.

**The confirmation gate.** Show the list, then gate on an **explicit** yes.
"Sounds good" or silence is not a yes — ask *"anything you'd change?"*
Amendments → re-show and re-confirm.

**Scope.** Check every child against `PRODUCT.md`'s Out of scope — drop or
flag, never silently include. Sibling overlaps are a smell; resolve first. An
ambiguous or impossible item is a **design-flaw signal**: pause and flag it.
All three block the list from the gate.

**Ending.** Each run ends with its created-issue list — the undo manifest.

## Step 3 — Epic bodies

Read the target plus `PRODUCT.md`.

Every body below follows `CONVENTIONS.md`'s Never hard-wrap body text — one
line per paragraph, one per bullet, however this file wraps its own prose.

**Epic:**
```
## Objective
<what capability this enables>

## Problem / User Need
<what problem this capability solves>

## Scope
Included:
- <item>

Out of scope:
- <item>

## Success Criteria
- <criterion>
```

## Step 4 — Story / Task / Bug bodies

Read the Epic body, `ARCHITECTURE.md`'s module map, `PRODUCT.md` (+
`DESIGN.md` if it touches UI).

**Classify each child** per `CONVENTIONS.md`'s Classifying an item, then follow
its Voice follows type — the Given/When/Then form below is `Story`'s alone.

Bodies carry goal and boundary content only (`reference.md`).

**Story:**
```
## User Story
As a <role>, I want <goal>, so that <reason>.

## Acceptance Criteria
<per criterion, ONE of these two forms — never both:>
Given <condition> / When <action> / Then <result>   ← only a real transition
- <criterion with no action — presence, appearance, or a constraint>
```
(end-to-end and user-observable — see `CONVENTIONS.md`'s Voice follows type.)

**Task:**
```
## Objective
<what needs to be accomplished>

## Description
<what needs to be done and why>

## Expected Result
<what should be true when this is complete>

## Acceptance Criteria
- <criterion>
```

**Bug:**
```
## Description
<what is happening>

## Steps to Reproduce
1. <step>

## Expected Behavior
<what should happen>

## Actual Behavior
<what actually happens>

## Impact
<who/how many are affected>
```

## Step 5 — Sub-tasks

**A Sub-task without falsifiable criteria is not creatable** — `/plan` types
each criterion and plans from it; `/review` re-verifies each.

Read the item body, `ARCHITECTURE.md`, `TECH_STACK.md`, `PRODUCT.md`,
`DOMAIN.md`, `GLOSSARY.md` (+ `UX.md`, `DESIGN.md` for UI).

**Size heuristic.** Avoid Sub-tasks under ~20 changed lines; merge siblings
that small into one Sub-task with multiple criteria (`reference.md`).

```
## Description
<what needs to be done>

## Acceptance Criteria
<explicit, falsifiable — what /plan types and plans from>
- <criterion>

## Files / Modules
- <path>
```

**Spike Sub-tasks add two fields** to that body — the deliverable is a finding:

```
## Question
<the one thing this Spike must answer>

## Timebox
<effort ceiling — the Spike ends here, answered or not>
```

Their first criterion is the finding — "the chosen approach and why are written
back to this issue" (`inspect`) — plus one per piece of code that must survive.

- **Criteria** are falsifiable conditions — never restatements of the title,
  never Given/When/Then — and **one claim each**: split any asserting both
  structure and styling. Word each so its proof type (`CONVENTIONS.md`) is
  obvious: behavior → "returns 401 for an expired token" (`test`); a readable
  fact → "the workflow triggers on `pull_request`" (`inspect`); appearance →
  "the active tab uses `--color-accent` per `DESIGN.md` § Color" (`render`),
  which **must name the token or section** — "styled per `DESIGN.md`" is
  unfalsifiable and blocks the gate. Many Sub-tasks have no `test` criterion at
  all (`reference.md`). Can't write one? Stop and ask. A criterion upholding
  an invariant or interaction rule cites it: "a submitted relevé rejects
  edits (INV-002)". Criteria use `GLOSSARY.md` terms only: pipe every drafted
  body through `../glossary/scripts/glossary.sh scan -` before the gate.
- **Under a `Bug`**, one criterion names the reported reproduction case from the
  item's Steps to Reproduce, always `test`.
- **Files/modules** come from `ARCHITECTURE.md`'s map and must honour
  `TECH_STACK.md`'s pins — never invented paths (`reference.md`).
- **Criteria/files coverage** — before the gate, name the file that satisfies
  each criterion. A criterion covering two flows ("stored after sign-in **or**
  sign-up") needs one for each; a criterion whose only home is a path this
  Sub-task does not declare is mis-scoped, or belongs to a sibling. Any
  criterion the list cannot satisfy **blocks the gate** (`reference.md`).
- **Blocking dependencies** are drafted as pairs, applied after creation as
  native blocked-by links, never body text.
- **Foundation gate** — item touches UI and the `foundation` Epic has open
  items? Block **every root** of this graph (each Sub-task with no other
  blocker) on those items, never the Epic. Epic unsplit → say so and stop
  (`reference.md`).
- **Flag exploratory Sub-tasks** as `Spike` candidates.

Then ask: **one-by-one** or **batch** (one confirmation for the list).

### Dependency graph

Build it from the drafted dependencies, then **cross-check file overlap**: for
every pair with no stated dependency, compare files lists. On overlap,
auto-insert an ordering dependency (default — later in the build order depends
on the earlier), or batch unclear pairs for a quick yes/no.

**Trace for cycles before creating anything.** A cycle in the draft means refuse
and report it exactly (`#12 → #14 → #12`) with the conflicting dependencies.

### Verify, don't assert

After the edges are applied, **run the sorter, don't claim an order**:

```bash
../gh-sub-issues/scripts/issue.sh order <item-issue>
```

Exit 1 means the graph you just created is broken — fix the edges now, never
leave it for `/build` to hit. Exit 5 means a Sub-task is blocked by an issue
outside this parent: legitimate, but say so explicitly so nobody reads the
split as ready to build. Report its output as the execution order — the same
command `/build` runs.

## Step 6 — Keep the docs living

If the split expands scope beyond the upstream docs, **offer** — never
auto-edit — to append a dated scope note to `PRODUCT.md`, or `DESIGN.md` if
design-relevant. On the go-ahead, stage that file only, commit
`docs(<scope>): <what changed>`, push.

## Failure handling

Missing or ungated doc, unknown target type, `sub-task` target, unresolvable
criterion, or a dependency cycle → refuse, naming what's wrong and what
unblocks it. `gh` failures → `gh-sub-issues`' handling; fail loud.

Undoing a run is manual — see `reference.md`.
