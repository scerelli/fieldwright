---
name: adr
description: Use when /discover or /architect write or revise a pinned decision in TECH_STACK.md or ARCHITECTURE.md, to record or supersede a durable Architecture Decision Record in docs/adr/.
---

# adr — durable decision records

## Overview

`/discover` and `/architect` write living documents that get rewritten
wholesale on revision — the reasoning behind a decision would otherwise be
lost the moment it changes. This skill is the shared mechanism both use to
record every pinned decision as its own numbered, durable file in
`docs/adr/`, independent of the living doc's own rewrite cycle.

Recipe skill: no interview, no human gate of its own. It runs as a side
effect of the confirm-before-write step already gated by
`gated-doc-interview` in the calling command.

Every ADR file this skill writes or edits gets its own commit, staged and
pushed alongside — or immediately after — the calling command's own
`docs(...)` commit for `TECH_STACK.md`/`ARCHITECTURE.md`, per
`gated-doc-interview`'s commit step. An ADR left uncommitted is the same
dirty-tree problem as an uncommitted living doc.

## When to call

Once per **individual** pinned decision (not once per document, not once per
run):

- **New decision** (first time this decision is pinned, in either an initial
  run or as a brand-new addition during a revision) → record mode.
- **Changed decision** (a revision interview replaces a previously-pinned
  choice) → supersede mode.
- **Unchanged decision** carried through a revision untouched → do not call
  this skill; nothing to record.

## Numbering

```bash
ls docs/adr/ 2>/dev/null | grep -oE '^[0-9]{4}' | sort -n | tail -1 || true
```

Next number = that value + 1, zero-padded to 4 digits (or `0001` if the
command produces no output — `docs/adr/` doesn't exist yet or is empty).
Taking the max existing number (not a count of files) means a deleted or
renamed ADR never causes the next number to collide with and overwrite a
still-live file. The command already exits cleanly (0) on an empty or
nonexistent `docs/adr/` — `tail` is the last stage of the pipe and succeeds
on empty input — but the trailing `|| true` documents that this is the
intended, non-error path. `docs/adr/` may not exist yet on a project's
first decision — create it.

Re-run this command — re-deriving the number from what's actually on disk —
immediately before writing *each* ADR file. Never compute numbers for a
batch of decisions up front: if you're recording three decisions in one
`/discover` or `/architect` run, derive, write, derive again, write, derive
again, write — not derive once and assign three numbers from that one
count.

## Record mode — new decision

Write `docs/adr/000N-<slug>.md` (slug: lowercase, hyphenated, from the
decision title):

```markdown
# ADR-000N: <decision title>

Status: Accepted
Date: <YYYY-MM-DD>
Doc: TECH_STACK.md | ARCHITECTURE.md

## Decision
<one or two sentences — the choice made>

## Context
<the constraint or requirement that drove this>

## Alternatives considered
<option — why rejected, one line each>

## Consequences
<what this locks in, and what would need to change to revisit it>
```

Return `ADR-000N` to the caller, which inlines `(ADR-000N)` into the line it
writes in `TECH_STACK.md`'s "Rejected alternatives" or `ARCHITECTURE.md`'s
"Key decisions".

## Supersede mode — changed decision

1. Find the prior ADR for this decision. The caller knows which one — it is
   revising a specific line in the living doc that already carries an
   `(ADR-000N)` reference; use that number. If the living doc predates this
   skill and carries no reference, search `docs/adr/*.md` for a `Doc:` and
   decision title match; if none is found, treat it as a new decision
   (record mode) rather than guessing at a supersede target.
2. Determine both numbers *before writing either file*: the prior ADR's
   number (already known from step 1) and the next number for the new
   decision (derive it now, per Numbering above). Fixing both numbers up
   front — rather than re-deriving between steps 3 and 4 — avoids an
   off-by-one if anything else touches `docs/adr/` in between.
3. In the prior file, change only the `Status:` line to:
   `Status: Superseded by ADR-000M` (`000M` = the new decision's number,
   determined in step 2). Leave every other line untouched — it is the
   historical record of what was decided and why, at the time it was
   decided.
4. Record the new decision in record mode (above), using the number
   determined in step 2.

Never edit a superseded ADR's `Decision`, `Context`, `Alternatives`, or
`Consequences` sections. If the old reasoning turns out to have been
factually wrong (not just outdated), note that in the *new* ADR's Context —
do not rewrite history.

## Common mistakes

- Calling this once per document instead of once per decision → each
  decision needs its own file and its own history; batching loses that.
- Editing a superseded ADR's body → only the `Status:` line ever changes on
  an existing file.
- Guessing which ADR a changed decision supersedes → use the living doc's
  existing `(ADR-000N)` reference; if there isn't one, record fresh instead
  of guessing.
- Skipping unchanged decisions during a revision → only decisions that
  actually change (or are newly added) get a call to this skill.
- Assigning numbers to a batch of decisions up front (e.g. "these are
  three, four, five") instead of writing each ADR file and re-deriving the
  next number from disk before writing the next one.
