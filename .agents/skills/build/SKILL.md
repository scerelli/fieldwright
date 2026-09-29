---
name: build
description: Use when executing a decomposed Story, Task, or Bug issue end to end from the main agent context.
---

# /build — Story/Task/Bug Orchestrator

`/build <item>` executes every Sub-task of a Story, Task, or Bug in
dependency order. It runs in the **main agent context** and never implements
anything itself — each Sub-task runs in its own subagent.

**Core principle: orchestrate, never implement.** The subagent owns the
branch and the loop; this skill owns the order, the todo list, and the stop
conditions.

**REQUIRED SUB-SKILLS:** `preflight`, `gh-sub-issues`. See `CONVENTIONS.md` for the
branch model and return vocabulary.

## Prerequisites — fail loud

The argument must be an open `epic`, `story`, `task`, or `bug`
(`../gh-sub-issues/scripts/issue.sh type <n>`).

- **Epic** → fetch its open child items and build them sequentially (Step 3).
- **Story/Task/Bug with sub-tasks** → orchestrate normally.
- **Story/Task/Bug with none** → judge complexity. *Simple* (isolated, few
  files) → offer to build it directly, stating **why** it looks isolated
  (which modules, and why nothing in `ARCHITECTURE.md`'s map depends on them)
  so the accept is informed; setup is in `reference.md`. *Complex* → ask
  whether to `/decompose` first.

## Step 0 — Preflight

```bash
../preflight/scripts/preflight.sh build --item <n> [--ui]
```

Exit 5 → the lock is held; ask the human before doing anything (see
`preflight`). Then verify the subagent **tool** yourself: can a subagent
spawn **nested** subagents? Reasonix = `task` tool, Claude Code = `Task`.
Without nesting, `/build` spawns the reviewer itself per `review`; without a
tool at all, warn and offer inline sub-tasks (same order, same branches).
**Never silently degrade.**

## Step 1 — Derive execution order

```bash
../gh-sub-issues/scripts/issue.sh order <n>
```

**Never derive this order yourself.** The script runs a real topological
sort over native blocked-by links and treats closed Sub-tasks as satisfied.
**Exit 1** = cycle or unresolvable reference: the decomposition is broken,
stop and point to `/decompose`. **Exit 5** = an open blocker outside this
parent: not broken — report which issue blocks, and stop until it closes.
Re-run on every `/build`; never reuse a cached order.

## Step 2 — Todo list

One entry per open Sub-task in execution order. Update after every subagent
return — this is the user-facing progress view.

## Step 3 — Run the Sub-tasks

**Epic:** run Steps 1–4 against each open child as if it were the top-level
argument — own order, own nested todo list, own one-subagent-per-Sub-task.
Skip Step 0 per item (the Epic's preflight holds the lock). A paused item
pauses the Epic run.

**Ensure the item branch exists** before the first subagent. It branches from
production. Ask the script; never hardcode the name:

```bash
BASE=$(../gh-pr-merge/scripts/pr.sh production-branch) || exit 1
git ls-remote --heads origin feature/<n>-slug | grep -q . \
  || { git checkout -b feature/<n>-slug "$BASE" && git push -u origin feature/<n>-slug; }
```

**Fill `<n>-slug` from the issue — number + title slug** (`reference.md`).
If it already exists, check it out — never recreate.

**One subagent at a time, in order.** Wait for each return before touching
the next Sub-task. The shared working directory is safe precisely because
only one runs — `/build` never runs Sub-tasks concurrently, and there is no
flag to make it. See `reference.md` for why.

**Run Sub-tasks through the platform's subagent tool** — Reasonix `task`,
Claude Code `Task`; verify the tool first.
**Pre-load context into the subagent prompt.** The prompt must include:
- the Sub-task issue body **verbatim** (from `gh issue view <n> --json number,title,body,state`)
- the relevant sections of `TECH_STACK.md`, `ARCHITECTURE.md`, `DOMAIN.md`,
  `UX.md`, and `DESIGN.md` that the issue touches, plus the `GLOSSARY.md`
  entries it uses — do not make the subagent re-read them
- the item branch and checkout command
- the pipeline (`/plan` → `/implement` (`tdd`) or `/direct` (`direct`) per its
  `## Build mode`, `Spike`-labelled issues always `/spike` → `/review` →
  `domain-review` → `/ship`)
- that `/review` and `domain-review` each run in a fresh context (or inline under `review`'s
  trivial-change fast path)
- that retries stay on the **same** branch, cap 3
- `CONVENTIONS.md`'s return contract **quoted, not referenced**

**Batch consecutive `direct` Sub-tasks** — two or more in a row with no
`test`-type criteria and no `Spike` label — into one subagent run; the rules
are in `reference.md`.

If the executor reports a mistyped criterion (`/direct` hit one needing a
test), treat it like a review rejection: same branch, resume with
`/implement`, do not reset the retry counter.

## Step 4 — Handle the return

- **`shipped`** → mark done; move to the next Sub-task in the order.
- **`stuck`** / **`design-flaw`** → **write the marker comment to GitHub
  first, before anything else**, per `CONVENTIONS.md`. The marker is the
  first line; **the body must then name which Sub-task escalated, what was
  tried across the attempts, and the final error** — the marker makes the
  state greppable, the body is what a human actually needs to act. Then
  pause — nothing else is in flight, so the pause is immediate. Never
  continue into a Sub-task that depends on the escalated one. For
  `design-flaw`, name the implicated doc and tell the user to re-run that
  gate (`/validate`, `/model`, `/glossary`, `/discover`, `/architect`, `/ux`,
  `/design`) before re-running
  `/build`. The resolution writes back to the issue; the next `/plan` reads
  it as spec.

**On `design-flaw`, report the decision — never a menu.** The brief format is
in `reference.md`: the conflict verbatim, each reading it admits with its
evidence (silence is evidence), a recommendation and its reason, and the
blast radius per reading. A bare menu of options only when the readings are
genuinely equally supported — and say that is why.

**Route the spec fix to the right tool** — never blanket-suggest `/decompose`;
it bulk-splits a *full* level and refuses a single addition.

| the fix is | the tool |
|---|---|
| an existing Sub-task's criteria or files list is wrong | `gh issue edit <n>` — `/build` and `/plan` re-read the body live, so nothing needs re-splitting |
| one new Sub-task belongs under the item | `/ideate <item>` |
| the criteria change ripples across siblings | `/decompose <item>`, bulk-catch-up mode |

Name **exactly one** row and why. If none fits, say so and stop for the human.

**Release the lock once the run has fully paused:**
`../preflight/scripts/preflight.sh release-lock --item <n>`. A paused
`/build` is not running, and the lock would block the human's fix-up session.

An ambiguous, contradictory, or impossible acceptance criterion is a
`design-flaw`, never something to guess around.

## Crash recovery

Restart re-derives everything from live state. For each open Sub-task:

```bash
scripts/subtask-state.sh <subtask-issue> feature/<m>-slug
```

- `never-started` → spawn normally.
- `merged-not-closed` → the work already shipped; run `/ship` Step 2 (comment
  the PR link, close the issue). Do **not** re-implement.
- `in-flight` → a subagent died. Fetch the branch, diff it against the item
  branch, compare to the criteria. Substantially complete → spawn a subagent
  to verify tests, `/review`, `domain-review`, `/ship`. Partial → resume `/implement` on the
  same branch. Can't tell → ask.
- `done` → nothing to do.

**Never delete, reset, or rebranch a died Sub-task's branch** — see
`reference.md`.

## When all Sub-tasks ship

`/ship` already ran the cascade. Verify via `gh` that the item issue is
closed; if not, report that the cascade didn't complete and point to
`/ship --force-close <item>`. Either way, release the lock:
`../preflight/scripts/preflight.sh release-lock --item <n>`.

