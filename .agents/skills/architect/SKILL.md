---
name: architect
description: Use when turning PRODUCT.md, DOMAIN.md and TECH_STACK.md into an approved ARCHITECTURE.md — the system-level design gate of the Shipwright pipeline, after /discover and before any Epic decomposition.
---

# /architect — ARCHITECTURE.md

Turns `PRODUCT.md` (Now — v1/MVP), `DOMAIN.md` (the model) and `TECH_STACK.md`
(locked stack) into the system shape, module boundaries, persistence mapping,
and compatibility surfaces that `/design`, `/decompose`,
`/plan`, and `/build` treat as ground truth. **Human gate.**

**REQUIRED SUB-SKILLS:** `gated-doc-interview`, `adr` for every pinned decision.

## Prerequisites — fail loud

`PRODUCT.md` (→ `/validate`), `DOMAIN.md` and `GLOSSARY.md` (→ `/model`),
and `TECH_STACK.md` (→ `/discover`) must exist. The model is ground truth:
map it, never re-model it. A concept the architecture needs that `DOMAIN.md`
lacks is a `/model` revision, not a new entity invented here. If `ARCHITECTURE.md` exists, run in revision mode over the deltas only.

## Interview areas

Skip what the upstream docs answer. **Options must be constrained by
`TECH_STACK.md` — never propose a shape the stack can't support.** Size the
operational questions to `PRODUCT.md`'s Scope size: a weekend project needs
one line per question, not a paragraph.

- **Business context** — the domain in a few sentences. Vocabulary lives in
  `GLOSSARY.md`: link it, never restate it.
- **Quality attributes** — which non-functional properties matter most,
  **ranked, not just listed**. Pull from `PRODUCT.md`; ask only where silent.
- **Assumptions & constraints** — existing systems this integrates with, team
  limits, hard technical ceilings. Ask only what's new at this level.
- **System shape** — monolith, modular monolith, client+API, serverless, or
  worker+queue.
- **External actors & systems** — who or what sits outside the boundary and
  how each interacts.
- **Module boundaries** — map each module to a chunk of Now — v1/MVP: name,
  responsibility, public interface, and which part of the stack it runs on.
  Each module also names the **aggregates it owns** (from `DOMAIN.md`); an
  aggregate has exactly one owner. **These drive Epic/Story/Sub-task
  decomposition, so keep them few and cohesive** — and where the roadmap already names a Next-phase item, prefer
  a boundary it could grow into over one that would need a redesign.
- **Data model** — how `DOMAIN.md`'s aggregates persist: tables or
  documents per aggregate, where each invariant is enforced in storage
  (constraint, trigger, application code), and how history and provenance are
  stored.
- **Compatibility surfaces** — every boundary where two independently
  released things meet: the wire contract between client and server
  versions, a client-local schema, the server schema, file and export
  formats. For each: the paths that define it, the version skew it must
  tolerate (e.g. a self-hosted server one release behind the app), the rule
  (additive only, versioned, forward-only migrations), and the proof a diff
  touching it owes (contract test, migration test, golden fixture).
- **Key flows** — authentication and the primary journey at **sequence level**
  (actor → modules touched → data written/read), not screen level.
- **Cross-cutting concerns** — error handling, logging/observability,
  config/environments, security boundaries (authn/authz, secrets, trust edges).
- **Deployment topology** — local/staging/production, what runs where.
- **Operational concerns** — incident handling, backup/recovery, capacity.
  "N/A at this scope" is valid for a weekend project, **not** for an ongoing
  product — check Scope size before accepting it.

## Recording decisions

For every entry in "Key decisions": new → `adr` **record** mode, inline the
returned `ADR-000N`; changed during revision → `adr` **supersede** mode with
the existing reference, inline the new one; carried through unchanged → no
call, keep the reference.

Runs once per decision immediately before writing. Not a second human gate.

## Output — write to `docs/shipwright/ARCHITECTURE.md`

Progressively detailed — business framing first, system shape next,
operational detail last, in the spirit of a [C4 model](https://c4model.com/):
each view assumes only the ones before it.

Use mermaid `C4Context`/`C4Container`/`C4Deployment` **only** where the syntax
fits *and* the doc will be viewed somewhere that renders them — C4 support has
historically lagged plain flowchart support in several renderers. Otherwise
fall back to a plain flowchart with the same information. **Never ship a
diagram type the viewer can't render.**

```markdown
# Architecture: <name>

## Business context
<the domain in a few sentences + recurring vocabulary worth pinning>

## Quality attributes
<the ranked non-functional priorities that shape every choice below>

## Assumptions & constraints
<design limits later decisions must respect>

## System view
<system shape in one paragraph, plus a context diagram: this system as one
box, its actors, and the external systems it talks to>

## Module map (container view)
<per module: name, responsibility, public interface, tech — plus a
container-level diagram>

## Data model
<persistence per aggregate + where each INV- is enforced in storage; a
mermaid ER diagram is fine>

## Compatibility surfaces
| Surface | Paths | Other side & skew tolerated | Rule | Proof owed |
|---|---|---|---|---|

## Key flows
<authentication + primary user journey, sequence level>

## Cross-cutting concerns
<error handling, logging/observability, config, security boundaries>

## Deployment view
<local / staging / production, what runs where — a diagram for anything past
a single-environment weekend project>

## Operational view
<observability, incident handling, backup/recovery, capacity — one line each,
or "N/A at this scope">

## Key decisions
<one line per decision: the choice and its `(ADR-000N)` reference — full
detail lives in docs/adr/, never duplicated here>

## Open questions
<unresolved points that do not block decomposition>

## External references
<links beyond this pipeline's own docs — omit if none>
```

**Size to Scope size, capped at four pages.** Overflow belongs in `docs/adr/`
or a dedicated doc, never padding this file — `/plan` and `/decompose` re-read
it in full for every sub-task, so length is a live cost. Decisions owned by
`TECH_STACK.md` are already made: reference them, don't re-litigate them.

## Common mistakes

- Writing every section to the same depth regardless of Scope size → a
  weekend project's Operational view is one line, not a backup strategy.
- Renaming or dropping **Module map**, **Compatibility surfaces**, or **Key
  decisions** → `/decompose`, `/plan`, `/review`, `domain-review`, and `adr`
  all read these by name.
- Treating Business context or Quality attributes as filler → they keep later
  decisions traceable; a System view with no stated quality attributes is
  unreviewable.
- Duplicating ADR content into Key decisions → that section is a one-line
  index; reasoning lives in `docs/adr/`, linked, never copied.

## Downstream

`/plan` hard-requires this file for every sub-task. `/decompose` uses the
Module map for per-sub-task file estimates — vague boundaries produce vague
estimates. A `design-flaw` from `/build` may route back here: run revision
mode and correct the specific flaw, don't re-interview from scratch.

Suggest, do not run, `/ux` if `UX.md` is missing, `/design` if `DESIGN.md`
is missing, otherwise `/decompose docs/shipwright/PRODUCT.md`.
