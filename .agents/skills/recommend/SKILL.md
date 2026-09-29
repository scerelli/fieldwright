---
name: recommend
description: Use when the user asks what to work on next, wants a prioritized view of the open backlog, or wants a recommendation among open Epic/Story-Task-Bug/Sub-task issues. Read-only — never creates, edits, labels, or closes an issue, and never touches git.
---

# /recommend — what to build next

Surveys the open backlog and recommends the single best next action.
**Read-only**: it queries and summarizes, never creates, edits, labels,
closes, or branches.

## Step 1 — Survey

```bash
scripts/backlog.sh survey
```

TSV, already ranked: `bucket, rank, milestone-rank, number, type,
milestone, title, detail`.

| bucket | meaning | next command |
|---|---|---|
| `in-progress` | branch exists, no escalation marker | resume `/build #N` |
| `ready-to-build` | ≥1 open Sub-task with all blockers closed | `/build #N` |
| `needs-decomposition` | open, zero children | `/decompose #N` |
| `blocked` | open Sub-tasks, every one blocked | report only |
| `cascade-failed` | **every sub-task closed, item still open** — the `/ship` cascade did not complete (red CI at the item merge, or a crash) | re-run `/ship`, or `/ship --force-close #N` |
| `maybe-stuck` | branch idle past the threshold, **no** escalation marker | report as an unconfirmed inactivity signal, never as confirmed |
| `stuck` | branch + escalation marker | report only |

Ranking is already applied: bucket order first (**actionability outranks
everything** — a blocked item in `v1.0` is not a better pick than a ready one
in `v1.1`), then **milestone by due date**, then issue number. There is no
priority field to weigh; see `CONVENTIONS.md`. `stuck` is emitted but never
ranked.

**Group the report by milestone** when more than one is in play, earliest
phase first — that's the shape a human reads a phased roadmap in. Say which
milestone the Top pick belongs to, and if the current phase is fully closed
out, say *that* plainly before recommending work from the next one.

Open milestones sort by due date; **closed ones sort after all of them**, so
a shipped phase's stragglers can't head the report. That only holds once the
phase is actually closed:

```bash
scripts/backlog.sh closable-milestones      # "<title>\t<closed count>"
```

Any row here is a phase whose issues are all closed while the milestone is
still open. Report each one and offer
`../gh-sub-issues/scripts/issue.sh close-milestone "<title>"` — `/recommend`
is read-only, so it names the command and never runs it.

If it exits 1 with "no open hierarchy issues", say so plainly and point to
`/init` or `/decompose`. `/recommend` reads a backlog; it does not bootstrap
one.

## Step 2 — Report

- **Top pick** — number, title, type, one-line reasoning, and the exact
  next command.
- **Shortlist** — the next 2–4, one line each.
- **Blocked / stuck** — name each and what must resolve first. For every
  stuck item run `scripts/backlog.sh markers <n>` and report **each** marker
  separately — "one resolved" must never read as "all resolved."
- If everything open is blocked, say so and name the single upstream item
  whose completion unblocks the most work. Never fall silent for want of a
  clean pick.

**Inactivity is not a marker.** An item with a branch but no marker comment
and an old last commit may be a `/build` that crashed before it could post
one. Say plainly that this is an inactivity signal, not a confirmed
escalation — there is no mechanical staleness threshold to apply.

## Step 3 — Route

- **Default** — ask whether to run the Top pick now, e.g. *"Would you like me
  to run `/build #N`?"* If accepted, invoke it.
- **`--auto`** — invoke `/build #N` on the Top pick without asking, **only**
  when all three hold; otherwise fall back to asking and say why:
  1. the Top pick is `ready-to-build` or `in-progress` — never auto-invoke
     `/decompose`, which mutates the hierarchy;
  2. nothing is in the `stuck`, `maybe-stuck`, or `cascade-failed` buckets —
     any of the three means a human looks before more work starts;
  3. exactly one candidate sits in the winning bucket in the earliest
     milestone — a genuine tie gets a question, not a silent pick, even
     though the issue-number tiebreaker would resolve it mechanically.

  Report the auto-invoked command and result exactly as a confirmed one.
  `--auto` changes who decides, never what gets logged.

## Common mistakes

- Creating, editing, labeling, or closing anything → `/recommend` only reads.
- Recommending a `needs-decomposition` item as a `/build` target.
- Treating an unmilestoned item as unranked → it sorts to the bottom of its
  bucket, it is not dropped from the report.
- Classifying an item with an escalation marker as plain in-progress → it
  must never be the Top pick or on the Shortlist.
