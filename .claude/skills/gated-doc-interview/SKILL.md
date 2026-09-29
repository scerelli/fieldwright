---
name: gated-doc-interview
description: Use when a pipeline command (ideate, validate, model, glossary, discover, architect, ux, design) must interview the user before writing or revising a document.
---

# Gated Doc Interview

The document-producing commands never generate a doc from one freeform
prompt. They run a structured interview and treat the **confirmed summary as
the human gate** — the file is written only after the user confirms the
collected decisions.

**The gate is the summary, not the file.** Two rules run through every round:
every question carries the interviewer's own recommended answer, and **any
fact you could find yourself is never put on the user.**

## Protocol

1. **Check prerequisites.** Missing upstream doc → refuse, naming the command
   that produces it. Never proceed on assumptions.

2. **Map the frontier, then ask it as one round.** Sketch the decisions this
   doc needs as a tree: each open question and which others it depends on.
   The **frontier** is every question whose prerequisites are already settled
   — by an earlier answer, an upstream doc, or research. Ask the *entire*
   frontier in one numbered message. **Never trickle out one question when
   two are already askable.** A question depending on a still-open answer
   belongs to a later round — asking it early forces the user to guess.

3. **Every question carries a recommendation.** Propose 2–4 concrete options
   reasoned from the answers so far, the upstream docs, and any research —
   never generic placeholders — then pick one with a one-line reason.

   - **With a structured choice tool** (Claude Code's `AskUserQuestion`, or a
     native equivalent): use its own affordance. Recommended option **first**,
     `(Recommended)` suffixed to its label, reason in that option's
     description. Don't also embed `💡 Recommended:` in the question text, and
     don't add a manual "Other" — the tool provides one. These tools cap each
     call (commonly 4 questions × 2–4 options); if the frontier is larger,
     **issue multiple calls back-to-back in the same round** rather than
     deferring the overflow. A round is "what the user answers before the next
     round can be mapped," not "one tool call."
   - **Otherwise**: a numbered list with `💡 Recommended: <option> — <why>`
     beneath, accepting a number or freeform.

4. **Always allow a manual answer.** The options are a starting point, never
   a constraint. If the user types something else, that answer wins.

5. **Find facts yourself.** Before a question would depend on something
   lookup-able — a library's current API or maintenance state, a competitor's
   pricing, the existing module layout — go find it (web search, repo search,
   `gh`, or a dispatched subagent) and fold it into that question's options
   and recommendation. **Only decisions belong to the user.** A lookup in
   flight is an unsettled prerequisite: it blocks only the questions that
   depend on it, so ask the rest of the frontier now.

6. **Adapt each round.** Skip what context already answers. Drill deeper
   where an answer was vague — that drill-down joins the *next* round's
   frontier. There is no target question count. **Stop when the frontier is
   empty**, never on a count or a feeling that there's "enough to draft."

7. **Summarize and confirm — an explicit yes, not a vibe.** Present the
   collected decisions as compact bullets mirroring the target doc's
   sections, in the user's own words where they gave them, and **always
   include an explicit "Out of scope" bullet** — silent disagreement about
   exclusions is half of all misalignment. Then:

   - *"Whatever you think is best"* (declining to decide) → don't accept it;
     re-ask as a forced choice between two concrete options.
   - *"Sounds good"* / *"sure, let's go"* (low-signal) → ask once more,
     specifically: *"Anything you'd refine before I write this?"*
   - Silence, then *"okay let's start"* (didn't read it) → stop and ask which
     part to revisit. **Momentum is not agreement.**

   Any amendment → update the summary and confirm again, same rules.

8. **Only then write the document**, and commit it. Every pipeline doc lives
   under **`docs/shipwright/`** (`IDEA.md`, `PRODUCT.md`, `DOMAIN.md`,
   `GLOSSARY.md`, `TECH_STACK.md`, `ARCHITECTURE.md`, `UX.md`, `DESIGN.md`) — create the directory if absent; writing
   one to the repo root breaks `preflight`, which looks only there. Stage
   exactly that file (**never `git add -A`**), commit as `docs(<scope>):
   <what changed>` (scope = the doc's short name, e.g. `product`), and push
   (`git push -u origin <branch>` if it has no upstream yet) — there is no later "ship" step for these files, so this is the only
   point they reach the remote. Each write is its own commit; **never amend a
   previous doc commit**, even a local one. End by suggesting — not running —
   the next pipeline step.

## Revision mode

If the target doc exists, don't start from a blank page. Show the current
content, say this is a revision, and ask what's changing. Interview over the
deltas only, then rewrite the **full** document (after the same gate) so it
stays self-contained.

**One exception: a `<!-- shipwright:deferred -->` placeholder is not a
document.** `/init` writes those to satisfy file-existence checks, so
"the file exists" is true and meaningless — interviewing over its deltas
would mean interviewing over a stub that says only which command should have
written it. Treat the file as absent: full blank-page interview, and say
this graduates the doc off `/init`'s placeholder rather than revising
anything. Same rule downstream — a placeholder was never written against
this doc's pre-revision content, so don't flag it as stale; name it as still
deferred.

**Then flag downstream staleness.** The docs form a fixed order:
`IDEA → PRODUCT → DOMAIN/GLOSSARY → TECH_STACK → ARCHITECTURE → UX → DESIGN`, each treating every
earlier one as ground truth at the moment it was written. A revision can't
know whether it invalidates what was built on top of it, so never guess:
check which downstream docs exist, name them explicitly, and say they were
written against this doc's **pre-revision** content — worth a read to confirm
they still hold, or a revision of their own. **Never auto-regenerate a
downstream doc.**

## Skipping the interview

If the user supplies the substance inline, draft from it directly, show the
draft summary for confirmation, and write on confirm. The interview exists for
ideas that aren't fully formed — it is not a mandatory ritual.

## Common mistakes

- A question with no recommendation → that's surveying, not interviewing.
- Embedding `💡 Recommended:` in a structured tool's question text instead of
  using the tool's own mechanism.
- Letting a round exceed the tool's per-call cap and silently dropping the
  overflow → issue another call in the same round.
- Batching a question whose prerequisite isn't settled → it belongs next round.
- Asking the user for a fact you could look up → find it first.
- Accepting "sounds good" / "whatever you think" / silence as the gate.
- Confirming the *file* instead of the *summary* → the gate is before
  generation, on the decisions.
- Treating the recommendation as a forced choice → it's a lean, not a decision
  made for the user.
- Overwriting an existing doc without showing its content first.
- Writing the doc without committing it → an uncommitted doc leaves the tree
  dirty, which fails `preflight`'s clean-tree check the moment `/build` runs.
