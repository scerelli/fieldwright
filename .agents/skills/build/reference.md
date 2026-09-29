# /build — reference

## Branch names — `<n>-slug` is never a literal

`<n>-slug` in `feature/<n>-slug` and `subtask/<n>-slug` is a template you
fill from the issue: `<n>` is the issue number, `slug` the issue's **title
slug**. Derive it: title lowercased; non-alphanumerics → `-`; drop stop
words ("a", "an", "of", "and", "to", "for", "the"); collapse repeated `-`;
trim leading/trailing `-`; cap at ~40 chars. **Never write the literal
"s-slug", "slug", or a bare number.** Example — story #42 "Add Expo
notifications" → `feature/42-add-expo-notifications`; its sub-task #47
"Wire up push token registration" → `subtask/47-wire-up-push-token-registration`.
Read the issue title fresh each time (never a remembered slug), build the
name, and re-check it against number + shortened title before
`git checkout -b`. A branch named `subtask/47-slug` or `subtask/47` is a
placeholder that slipped through — stop and rename.

## Building an item directly, with no Sub-tasks

`/plan`, `/implement`, and `/ship` are all written in terms of a Sub-task:
`/plan` refuses without a files/modules list, and `/implement`/`/ship` refuse
unless the branch is `subtask/<n>-slug`. An item issue satisfies neither by
default — the Story/Task/Bug templates carry acceptance criteria but no
files/modules list. Satisfy both before treating the item as plan-ready:

1. If the item has no files/modules list, derive one from
   `ARCHITECTURE.md`'s module map — the same way `/decompose` derives it for
   a real Sub-task — append it to the issue body with `gh issue edit`, and
   note the addition in a comment.
2. Ensure `feature/<n>-slug` exists, same as the orchestration path.
3. Check out `subtask/<n>-slug` off it, using **the item's own issue number**.
   There is no separate Sub-task, so the item stands in for its own sole
   sub-task everywhere the pipeline says "the Sub-task issue."
4. Run `/plan` → `/implement`, `/direct`, or `/spike` → `/review` → `/ship`
   inline in the main context. Do not spawn a subagent for it.

`/ship` Step 3 runs `issue.sh all-closed` on the item, which returns **exit 3
(`no-children`)** here — a distinct outcome from both "all closed" and "some
open", precisely so this path is defined rather than improvised. Step 3
treats it as ship-the-item. Its Step 2 and Step 3 close the same issue number
(once as "the sub-task", once as "the item"); `gh issue close` on an
already-closed issue is a no-op, not a bug to work around.

## Why Sub-tasks run one at a time

Running unblocked Sub-tasks concurrently in isolated worktrees would turn an
item's build time from the **sum** of its Sub-tasks into the **max**. That is
the only thing it would buy, and the price is disproportionate for one
developer:

- Several `stuck`/`design-flaw` escalations open at once, arriving as a
  cluster to untangle — and one person can only untangle one anyway.
- Pausing becomes scoped rather than immediate: stop spawning dependents, let
  unrelated in-flight subagents land, pause only once nothing is spawnable.
  Three rules where serial needs none.
- The item branch needs re-fetching before every wave, because siblings ship
  by merging **on GitHub**, which never advances a local ref. Miss that fetch
  and a later wave branches off a stale tip missing merged sibling work, with
  nothing erroring to catch it.
- Crash recovery runs per worktree instead of per branch.
- `/ship`'s item-ship check becomes a genuine TOCTOU race: two subagents
  finishing seconds apart both observe "all siblings closed".

Serial keeps one working directory, one branch checked out, one escalation,
and one recovery path. Latency is the cheapest thing on that list to give
up.

## Why the nesting rule holds at every level

An Epic loop runs inline in the main context, but that does not make its
child items' Sub-tasks inline too. One dedicated subagent per Sub-task holds
at every nesting level — the reason `/review` is trustworthy is that it runs
in a context that did not write the code, and collapsing the nesting quietly
destroys that property.

## Reviewer fallback when nested subagents are unavailable

If a sub-task subagent cannot spawn its own reviewer, it returns
`implemented` after `/implement`/`/direct`/`/spike` and **must include `/plan`'s
build-mode classification (`tdd`/`direct`) and its per-criterion proof
table** alongside it. `/plan` never persists either anywhere on disk, so this
return is the only way they reach the reviewer `/build` is about to spawn — and
without the proof table the reviewer has to infer how each criterion was
verified, which is the one thing the table exists to prevent. `/build` spawns
the reviewer, then resumes the subagent with the verdict.

The same holds for `domain-review`: after `/review` passes, `/build` spawns
the domain reviewer too, handing it the proof table with its `guards`
column. Two separate reviewer subagents, in that order, never one context
doing both: the domain reviewer must not inherit the code reviewer's
conclusions.

## A sub-task closed by hand

`issue.sh order` treats any CLOSED sub-task as satisfied, so a human closing
one in the GitHub UI unblocks its dependents and lets `/ship` merge the item
as complete — whether or not the work exists.

That is deliberate: GitHub is the single source of truth, and a closed issue
means done. But it makes manual closes load-bearing. Before spawning the
first subagent, sanity-check any CLOSED sub-task that has **no merged PR**
against the item branch:

```bash
scripts/subtask-state.sh <subtask-issue> feature/<m>-slug
```

`done` with no merged PR anywhere means someone closed it by hand. Say so
explicitly and ask whether it was genuinely descoped — never assume the work
happened, and never silently reopen it either.

## Crash recovery — why a died branch is never touched

A `subtask/<n>-slug` branch left behind by a dead subagent is the **only
record of the attempted work**. It is not in a PR, not merged, and not
described anywhere else — deleting, resetting, or re-branching it destroys
the one artifact that says what was tried. Inspect it, continue it, or ask;
never clean it up.

The same applies to a dirty working tree on resume: it belongs to whichever
sub-task branch is checked out. Inspect before assuming it is junk — it is
the crashed sub-task's uncommitted work.

Exactly one Sub-task can have been mid-flight when a crash happened, because
exactly one ever runs. That is what makes the state check above a single
question rather than a sweep.

## Batching consecutive `direct` Sub-tasks

If two or more consecutive Sub-tasks in the execution order carry no
`test`-type criteria and no `Spike` label, group them into a single subagent
run. The subagent still checks out one `subtask/<n>-slug` branch per Sub-task
and ships each before starting the next, but it loads the shared docs once
and keeps its context alive across the batch. `/review` follows the
trivial-change fast path when the combined diff stays under 20 lines.

## Writing the `design-flaw` brief — the decision, never a menu

The human owns one question; surface it with what it takes to answer, from
the subagent's return plus the item body and the docs it names:

- **the conflict** — the criterion verbatim, and why it cannot be satisfied as
  scoped.
- **each reading it admits, with its evidence** — quote the line in the item
  body, `PRODUCT.md`, or `DESIGN.md` that supports it. **Silence is evidence**:
  "the parent Story says nothing about sign-up sessions" settles most scope
  questions on its own, and is the fact a menu leaves out.
- **a recommendation and its reason** — default to the narrower claim unless
  something upstream argues for the wider one. Recommending is not deciding.
- **blast radius** — which open Sub-tasks change under each reading, and
  whether a proposed new Sub-task clears the size floor
  (`decompose/reference.md`) or should fold into an existing one.

Three options and a stop hands back the judgment call *and* the research. Do
that only when the readings are genuinely equally supported — and say that is
why.

## Common mistakes

- Implementing a Sub-task in the main context when a subagent mechanism
  exists → this skill orchestrates; it never writes code.
- Deriving the execution order yourself instead of running `issue.sh order`
  → a silently wrong order builds against work that doesn't exist yet.
- Retrying a failed Sub-task on a fresh branch → same branch, always.
- Continuing into a Sub-task that depends on an escalated one.
- Pausing on `stuck` without the marker comment → a silent pause leaves only
  an open branch as a clue.
- Sending the human to `/decompose` for a single-field spec fix → it refuses
  single additions; route per Step 4's table.
- Reporting a `design-flaw` as numbered options with no recommendation and no
  evidence → the human gets the judgment call and the research.
- Running Sub-tasks concurrently — the order is sequential, always.
- Deleting `.shipwright/build.lock` by hand instead of `release-lock` → the
  command refuses when the lock belongs to another item; `rm -rf` does not.
