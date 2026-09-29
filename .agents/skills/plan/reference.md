# /plan — reference

## The `<!-- shipwright:deferred -->` exception

`/init` deliberately defers `/design` (and, under `--lean`, `/ux`), writing a placeholder doc that
opens with the literal marker `<!-- shipwright:deferred -->`.

When the specific doc a step depends on carries that marker, a missing module
map, stack pin, or design direction is **not** a design-flaw — it is the
accepted cost of prototyping fast. Plan directly from the issue's acceptance
criteria and files/modules list alone (for a UI sub-task, from criteria alone,
with no visual or tone grounding), and add a one-line note to the plan's
output saying which guidance was unavailable and why, so whoever reads it
knows to revisit once the real gate runs.

This applies **only** to that exact marker on the exact doc a step depends on.
A doc that is merely thin or vague, without the marker, is still a design-flaw
signal as usual.

## Why the mode is per sub-task but the proof is per criterion

A sub-task is one commit, one review, one merge — so the **mode** stays single-
valued, because it selects which skill executes the sub-task and only one can.

The **proof** cannot be. A single sub-task legitimately mixes claims of
different kinds: a themed tab shell both changes route on tap (behavior, worth
a test that would catch a regression) and paints the active tab with the accent
token (appearance, worth a look). Forcing one bucket over both is how a pipeline
burns tokens for nothing: `tdd` swallows the whole sub-task, the Iron Law then
demands a failing test per criterion, and the appearance criterion gets
`expect(getByRole('tablist')).toBeTruthy()` — a test that re-asserts that JSX
exists, costs a round-trip, and catches nothing.

There is a real objection to mixing proofs inside one sub-task: part of the diff
is verified one way and part another, and if nothing records which was which the
reviewer has to guess. That is exactly what the proof table answers. `/plan`
records the type per criterion, and `/review` receives that table verbatim next
to the build mode. Nothing is inferred, so nothing is guessed. If the table ever
stops travelling with the review context, the objection lands and the vocabulary
stops being safe.

The reflex that causes it: typing a criterion you can already see is about
appearance `test` "to be safe." The tiebreak is for when you can't tell what a
criterion claims, not for when you can; that reflex is the tautological-test
burn itself.

## Why `direct` skips red-green

A sub-task with no `test`-typed criterion has nothing the Iron Law can bite
on. Nothing there needs red-green, so requiring it buys latency, not safety.

## Why `/review` re-checks the typing

`/plan` types criteria before any code exists, from a plan that is itself a
prediction. `/review` sees the actual diff. When they disagree, the diff wins:
a criterion typed `inspect`/`render` whose diff turns out to carry a branch, an
error path, or a side effect is mistyped, and Check 1 routes it back to
`/implement` for a real test. The typing is a first pass, never a final word,
which is why it is safe to make it cheaply — and why the re-check runs on
every mode, not just `direct`.

## Why the plan never goes on disk

`/build` orchestrates from context and expects the plan in the subagent's
return, not in the working tree. A `PLAN.md` would also dirty the tree, which
fails `preflight`'s clean-tree check on the next `/build`, and would end up
committed to the sub-task branch as an artifact nobody wants in the history.

## Why a pinned tool beats a working generic example

A generic example that "technically works" quietly bypasses the decision
`/discover` recorded and `docs/adr/` justifies. The next sub-task touching that
layer then has two incompatible patterns to choose from, and the ADR trail no
longer describes the code. `TECH_STACK.md` winning every disagreement is what
keeps the decision record true.

## Common mistakes

- Writing a `PLAN.md` file → it stays in context, always.
- Treating criteria as documentation rather than spec.
- Planning around an ambiguous criterion → that's the design-flaw case.
- Adding files beyond the declared list without flagging it.
- Exploring "just a little" code first → no changes before the plan exists.
- Typing a behavioral criterion `render` or `inspect` because the sub-task is
  "just UI" → the layer never decides the type; the claim does.
- Paraphrasing a glossary term into a synonym while restating a criterion →
  the restatement is what the executor names things after.
- Leaving `guards` empty on a criterion that writes to an aggregate →
  `domain-review` then has no invariant list to start from.
