---
name: domain-review
description: Use inside a /build sub-task subagent after /review passes and before /ship, to verify a sub-task's diff against DOMAIN.md invariants and lifecycles, GLOSSARY.md, provenance rules, and ARCHITECTURE.md's compatibility surfaces.
---

# /domain-review: the model and compatibility gate

`/review` asks whether the code does what the issue said and is good code.
This gate asks whether it is still **the domain's code**: the model's rules
hold, its words are used, and nothing that another version of the software
depends on broke. Green tests do not answer that; a test only checks what
its author thought of.

Runs after `/review` passes, before `/ship`. Findings and return rules are
`/review`'s; `CONVENTIONS.md` holds the retry cap and vocabulary.

## Fresh context, always

A **dedicated reviewer subagent**, never the context that wrote the code,
and never `/review`'s reviewer. Hand it crafted context only:

- the Sub-task's acceptance criteria **verbatim**, and `/plan`'s proof
  table, whose `guards` entries name the `INV-`/`UX-` IDs each criterion
  upholds;
- `HEAD_SHA` and `BASE_SHA`, derived exactly as in `review`;
- `DOMAIN.md` and `GLOSSARY.md` in full; `ARCHITECTURE.md`'s Module map and
  Compatibility surfaces;
- no implementation narrative.

No subagent mechanism → review inline and **say so in the report**, as
`review` does.

## Scope check: which checks apply

List the diff's files: `git diff --name-only "$BASE_SHA" "$HEAD_SHA"`. Map
each to the Module map's owned aggregates and to the Compatibility surfaces'
paths. **Touches neither** (CI, docs, tooling) → run only Check A and pass
on clean, noting "no domain surface touched".

## Check A: language

```bash
../glossary/scripts/glossary.sh check "$BASE_SHA" "$HEAD_SHA"
```

Exit 1 → each line is an **Important** finding. Exit 3 → the glossary is
broken: `design-flaw` naming `/glossary`. Exit 2 → your call is wrong; fix
it. Then read the diff for **new domain concepts with no entry**: a type,
table, or screen that names a concept `GLOSSARY.md` lacks is **Important**
(add it via `/glossary`, or use the existing term). A `glossary:allow` with
no reason on its line is **Minor**.

## Check B: invariants and lifecycles

For every aggregate the diff touches, walk its `INV-` rows **one by one, in
writing**: `holds` / `violated:<file:line, how>` / `unguarded:<the new path
that could break it with no test enforcing it>`. Honour `Enforced at`: an
invariant marked `both` or `client` enforced only on the server is
`unguarded`.

- `violated` → **Critical**.
- `unguarded` → **Important**; the fix is a test at the enforcement point.
- A state or transition not in the aggregate's lifecycle → **Critical**,
  unless a criterion demands it: then the model is stale, return
  `design-flaw` naming `DOMAIN.md` and `/model`.

Also check `Provenance & audit`: data it covers is written with its
provenance, and nothing it calls immutable gains an update path.

## Check C: compatibility

For each Compatibility surface the diff touches, apply that surface's
declared rule and demand its declared proof (a migration with its test, a
contract test, an updated golden fixture, a bumped format version).
**Missing proof or broken rule → Critical**: this is the class of bug that
reaches users who never installed the new version.

Diff touches persistence, a wire contract, or an export, and
`ARCHITECTURE.md` declares **no** Compatibility surfaces → **Important**,
reported as a gap: "no surfaces declared; revise `/architect`".

## Report and outcomes

Same shape as `review`: strengths, then findings labelled **Critical** /
**Important** / **Minor** with `file:line`, what, why; the per-invariant
table; a verdict. Critical and Important block.

- **Pass** → `/ship`.
- **Fail** → back to the executor on the **same branch**; this attempt
  counts against the same retry cap as `/review`'s. Re-run `/review` and
  this gate after the fix.
- **The model or a criterion is wrong, not the code** → `design-flaw` with
  the rule verbatim, the readings it admits, and the doc to revise.

Never rewrite `DOMAIN.md`, `GLOSSARY.md`, or `ARCHITECTURE.md` to make a
finding go away.
