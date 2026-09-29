# /decompose — reference

## Why the milestone goes on the item, not the Epic

Containment and phasing are orthogonal. An Epic is a coherent capability; a
milestone is a ship date. Put the milestone on the Epic and any capability
that spans two phases has to be split into two Epics — fragmenting something
whole so the tree can express a date.

Concrete: an `Authentication` epic with email login in v1.0 and SSO in v1.1.
With milestones on items, that's one Epic and two differently-milestoned
children. With phase modelled as a tier, it's two Epics, and moving SSO
earlier means restructuring the hierarchy instead of editing a field.

Sub-tasks get no milestone either: the Story/Task/Bug is the unit that ships
(it owns the `feature/` branch), so its children inherit the phase implicitly.
Milestoning them would double-count every item in GitHub's progress bar.

## Why there is no tier above Epic

`PRODUCT.md` is the top of the hierarchy. A tier above Epic would restate
its Vision, Goals & metrics, and Scope at smaller granularity, and nothing in
the pipeline could act on it: no branch, no build, no merge — a level that
exists only to be closed by hand.

Every tier is real cost: more issues to create, another cascade level to keep
correct, another thing to remember to close. For one product with one
developer, a fourth is `PRODUCT.md` retyped into GitHub. Several distinct
product lines in one repo is the case that would seem to justify it — the
answer there is a second repo.

## Foundation Epic — `PRODUCT.md` split only

Now/v1 has UI and `DESIGN.md` exists? One Epic, labelled `foundation`, must
own it: themed app shell, navigation, `DESIGN.md`'s tokens wired into the
registry `TECH_STACK.md` pins. None does → draft it marked `(inferred)`,
recommended by default, same gate as the rest.

## Rollback — undoing a run

`/decompose` gates creation on an explicit confirmation, but has **no
automated undo** once issues exist. Reversing dozens of real issues
automatically would itself be silent, unattended mutation — the thing this
pipeline avoids everywhere else.

Every run ends with its created-issue list. **That list is the undo
manifest.** To reverse a run that turns out wrong after the fact (the
confirmation covered the plan, not what happened to it later):

```bash
gh issue close <n1> <n2> <n3> ...                    # every issue this run created
gh issue edit <child> --remove-blocked-by <parent>   # every edge this run added
```

- Close children before judging whether the parent's sub-issue count looks
  wrong. A parent left with zero children is **not** closed by this — that
  stays a deliberate human or `/ship --force-close` action, same as `/ship`'s
  report-only epic step.
- This undoes **only this run's** creations. If work already started on a
  since-closed issue (a `subtask/<n>-slug` branch exists), closing the issue
  does not delete the branch. Inspect it first, with the same caution
  `/build`'s crash recovery uses for an in-flight branch.
- **Keep the created-issue report until you're confident the split is
  right.** Once it scrolls out of view, reconstructing "what did this run
  create" from `gh` alone means diffing issue-creation timestamps — exactly
  the kind of guess this pipeline avoids.

## Why a shallow split omits `--parent` rather than inventing a parent

When the user skips the Epic tier, there is no real issue at that tier to
link to. The alternatives are all worse than no link:

- Inventing a placeholder Epic creates an issue nobody asked for, which then
  shows up in `/recommend` as `needs-decomposition` forever.
- Leaving a stale or guessed `--parent` number links children to an unrelated
  issue, silently corrupting every hierarchy query downstream.

An absent native sub-issue link for a tier that doesn't exist is **correct**,
not a gap to patch around. Type labels and milestones still apply —
`--parent` is the only thing skipped.

## Why acceptance criteria are mandatory at the Sub-task tier only

Epic and Story/Task/Bug bodies carry goal and boundary content.
Their "acceptance criteria" are end-to-end and user-observable — useful for a
human reading the backlog, but not consumed by any command.

Sub-task criteria are different: `/plan` turns each one into a plan step and
assigns it a proof type, the executor discharges it, and `/review` walks them
one by one as the compliance checklist. They are the only criteria in the
hierarchy that are *executed*, which is why a Sub-task without them is not
creatable while a thin Epic is merely unhelpful.

## Why Sub-tasks have a size floor

A Sub-task that changes fewer than ~20 lines — a single config file, a token
swap, a label rename — still pays the full `/plan` → `/implement`/`/direct`
→ `/review` → `/ship` overhead. The pipeline cost is fixed per Sub-task; the
work cost is variable. Below that floor the overhead dominates.

When several such small changes are siblings, merge them into one Sub-task
with multiple acceptance criteria. The criteria stay falsifiable and
per-proof-type; the branch, review, and merge happen once.

## Why criteria are written to make their proof type obvious

The proof type is assigned by `/plan`, but it is *determined* by how the
criterion is worded — so a badly worded criterion decides its own proof badly,
and nothing downstream can recover.

Two failure modes, both from writing every criterion in one shape:

- **A criterion that bundles claims.** "I see a tab bar with the app's primary
  destinations, styled per `DESIGN.md`" asserts a structural fact and a visual
  one at once. It has no single proof type, so whichever one `/plan` picks
  leaves half the criterion unverified. Split it and each half gets a real
  proof.
- **A criterion phrased as an API assertion when it isn't one.** If the only
  modeled example is "returns 401 for an expired token", a token swap gets
  written the same way, `/plan` types it `test`, and `/implement` owes a
  failing test for something a regression could never silently break. That is
  where `expect(getByRole('tablist')).toBeTruthy()` comes from — a test that
  exercises the framework, costs a round-trip, and catches nothing.

Hence the requirement to **name the token or `DESIGN.md` section** in an
appearance criterion. "Styled per `DESIGN.md`" is not a weak `render`
criterion, it is an unfalsifiable one: no diff can contradict it, so `/review`
cannot fail it and the gate stops being a gate. Naming `--color-accent` and
`§ Color` makes it checkable at the cost of one more word.

## Why the classifier is where a wrong template comes from

The body templates are type-specific — `Task` takes plain bullets, `Bug` takes
expected-vs-actual, and neither uses Given/When/Then. So a migration or a CI job
that arrives wearing a user narration was not mis-templated; it was **mis-typed**,
and then correctly templated for the type it was wrongly given. Fixing that means
tightening the classifier, not adding templates.

The obvious phrasing of the `Story` test is the one to avoid. "Value the end user
directly experiences" reads like a test but rationalizes freely: a cache rewrite
makes the app faster, a logging change means fewer unexplained errors, a
dependency bump closes a CVE users would care about. Every technical task has
some downstream user benefit, so a test that accepts downstream benefit accepts
everything, and `Story` becomes the default rather than the narrow case.

The test used instead cannot be satisfied that way: *could a user describe this
change without being told how the system works?* A user can say "I can log in
with my email" without knowing there is a session table. Nobody describes
"the events list query stops doing N+1 lookups" without describing internals,
however much they enjoy the result. Naming the categories outright — refactor,
tech debt, migration, CI, deploy, infra, ops, observability, dependency bump,
internal tooling — removes the judgment call for the cases that actually recur,
and `Task` is the tiebreak so the ambiguous ones land in the tier whose
template asks for no fictional actor.

## Why Given/When/Then is not the only Story criterion shape

Given/When/Then encodes a **state transition**: a precondition, an action, an
observable result. Presence, appearance, and constraints have no action, so
forcing them into the template produces a filler one — "When I look at the
primary screen" — and a reader cannot tell a real trigger from a padded slot.

Keeping GWT for transitions and a plain bullet for everything else is not a
style preference. A Story's criteria are the input `/decompose` re-reads when
splitting it into Sub-tasks, and a filler action invites a Sub-task criterion
about "looking at the screen" rather than about what must be true of it.

## Why cycles are traced by hand before creation, then verified after

Two different checks, deliberately:

- **Before creation**, the graph exists only as drafted pairs — there is
  nothing on GitHub for `issue.sh order` to read. Tracing by hand is the only
  option, and catching a cycle here means no issues are created at all.
- **After creation**, `issue.sh order` reads the real native links and is
  authoritative. It catches anything the hand-trace missed, plus edges that
  failed to apply.

The second check is what makes the reported execution order trustworthy: it
is the same command `/build` will run, not a separate derivation that can
disagree with it.

## Why a missing foundation epic is drafted, not merely flagged

A product with UI in Now/v1 and no Epic named "shell/theme" has a real gap:
each Epic's Stories end up re-deriving the same `DESIGN.md` tokens against
the registry `TECH_STACK.md` pins, and the visual drift `DESIGN.md` exists to
prevent shows up anyway, one Epic at a time. A question buried in the
confirmation prompt ("want one of these?") is easy to wave past — the whole
point is that this gap is otherwise invisible, so surfacing it as a plain
yes/no repeats the mistake at one remove. Drafting it as an actual Epic and
putting it in the list, recommended by default, means the human is deciding
on a concrete thing — same as reviewing any other drafted Epic — not
answering an abstract question about whether they want one.

The trigger is *any* UI in Now/v1, not "UI across two or more Epics". A
single-Epic v1 needs its tokens wired exactly as much; the only thing a
higher threshold buys is a silent miss on the smallest products. The gate is
`DESIGN.md` existing instead — with no design doc there is nothing to wire,
and under `/init`'s default profile that is the expected state until `/design` runs.

**This is not the placeholder-parent case above.** That section's objection
is to a *hollow* Epic invented only to satisfy a structural link nobody asked
for — content-free, existing purely so `--parent` has somewhere to point.
This Epic has real, specific content (theme wiring, app shell, navigation
skeleton) responding to a gap actually present in the drafted split, and it
sits in the same confirmation gate as every other Epic — the human can strike
it in one edit if it's wrong for this product. Silence is still not a yes;
it needs the same explicit confirmation as the rest of the list.

## Why the foundation item blocks, rather than merely existing first

Creating the Epic buys nothing on its own. Epics own no branch and are never
sequenced, and `/recommend` ranks by bucket, then milestone due date, then
issue number — a foundation Epic and the feature Epics it should precede sit
in the same `v1.0` milestone, so the only thing putting it first is the
accident of a lower issue number. `/build` takes whatever target it is given.
Left there, the drift this Epic exists to prevent happens anyway, with an
extra issue open to describe it.

The ordering lever is the same one every other dependency uses: a native
blocked-by edge, drafted at Step 5. Three details decide whether it actually
gates anything, and getting any one of them wrong makes it decorative.

**It goes on the Sub-task tier, not the item tier.** `backlog.sh` computes
the `blocked` bucket from Sub-task `blockedBy` alone — an item-tier edge is
invisible to `/recommend`, a comment pretending to be a gate.

**It goes on every root of the item's graph, not just the first Sub-task.**
`backlog.sh` stops at the first open Sub-task with no open blockers and calls
the whole item `ready-to-build`. Decompose only draws edges for stated
dependencies and file overlap, so independent parallel Sub-tasks are the
normal case, not the exception — leave one root unblocked and `/build`
reaches it, foundation or no foundation. Blocking the roots is sufficient as
well as necessary: every other Sub-task already sits downstream of one.

**It points at the foundation Epic's items, never the Epic.** `/ship` Step 4
closes an Epic *report-only* — it names the `gh issue close` command and
waits for a human. An Epic-tier blocker therefore outlives the work that
satisfied it, and every dependent item reads `blocked` indefinitely with
nothing in the report explaining that a manual close is the thing standing in
the way. The Story/Task items under it close automatically in the cascade, so
they are the honest thing to depend on. This is why the gate needs the
foundation Epic split into items *first*: before that there is nothing
closable to point at, and Step 5 says so and stops rather than quietly
skipping the edge.

The `foundation` label (created by `issue.sh ensure-labels`, alongside
`Spike`) is what makes the Epic findable at Step 5 without re-reading
`PRODUCT.md` and guessing which Epic counts as foundational — same reason
every other piece of state lives on the issue rather than in prose.

With those in place the foundation item reads `ready-to-build`, its
dependants read `blocked`, and `issue.sh order` exits 5 on them until it
ships — the out-of-parent blocker is reported, never silently treated as
ready.

Ideally this never triggers — `/validate`'s Scope & roadmap question now asks
about this directly, so a `PRODUCT.md` written after that change already
names it as real scope, and `/decompose` treats it like any other stated
capability. This check is the fallback for a `PRODUCT.md` written before that
change, or one where the question was answered "no" and the product's shape
changed since.

## Why there is no priority label

Nothing would schedule by one. `/build` takes the target it is given, and
`/recommend` already ranks by actionability and phase — both facts the
pipeline reads from live state rather than being told.

A hand-maintained rank on top of that is a second source of truth that drifts
the moment the backlog moves, bought with a question on every split. With one
person building, "what first" is answered by what is unblocked in the nearest
milestone, which is exactly what `/recommend` computes.

The same batching rule applies to unclear file-overlap pairs in Step 5.

## Why a files/modules list must honour the pinned stack

The list is not just paths — it implies *artifacts*. Naming a hand-written
migration file where `TECH_STACK.md` pins an ORM's own schema/migration
format quietly bypasses a decision that `/discover` recorded and `docs/adr/`
justifies. `/plan` then builds against the wrong pattern, `/review` has no
basis to object because the Sub-task said so, and the ADR trail stops
describing the code.

Invented paths fail the same way one level down: `/implement`'s scope guard
treats the list as the boundary, so a path that doesn't correspond to a real
module either blocks legitimate work or licenses work nobody scoped.

## Why criteria/files coverage is checked before creation

The criteria and the files list are two halves of one spec, written in the
same pass and never reconciled against each other again. Nothing downstream
can repair a mismatch: `/plan`'s scope check compares the union of planned
edits against the list and refuses, `/implement`'s scope guard treats the list
as the boundary and trips, and `/review` grades the diff against a criterion
the diff was never permitted to satisfy. All three refusals are correct, and
all three arrive **after** the issue exists, a branch exists, and a subagent
has spent an attempt.

This split is the only stage that sees the mismatch cheaply. It holds the item
body, `ARCHITECTURE.md`'s map, and every sibling at once, so *which file would
satisfy this criterion* is answerable here and merely guessable later. The
recurring shape is a criterion covering two flows against a list covering one:
each half was written correctly, against a different reading of the item.

The check is deliberately mechanical — name the file per criterion, block the
ones with no answer — and not "does this scope look right". The latter is the
judgment call the `design-flaw` escalation exists to route to a human, and
asking for it here would just move the guess earlier.

## Why `Spike` is independent of the build mode

`Spike` marks *intent* — the point is to learn whether an approach works.
`/plan`'s `direct`/`tdd` call is derived from the criteria's proof types. A
Spike issue can still carry `test` criteria, and a non-Spike sub-task can carry
none. Conflating them would let intent excuse skipping tests on real behavior,
which is exactly what `/direct`'s mistyping path exists to prevent.
