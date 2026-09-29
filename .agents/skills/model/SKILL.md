---
name: model
description: Use when turning an approved PRODUCT.md into DOMAIN.md and GLOSSARY.md, the human-gated domain model (aggregates, lifecycles, numbered invariants, events) and ubiquitous language, before /discover picks a stack.
---

# /model: DOMAIN.md + GLOSSARY.md

Turns `PRODUCT.md` into the model of the problem, independent of any
technology: what the concepts are, what must always be true about them, and
what words everyone uses for them. `/architect` maps it onto modules,
`/decompose` writes criteria against it, `/plan` and `domain-review` hold
every sub-task to it. **Human gate.**

Stack-free on purpose: it runs before `/discover`, so no question here may
depend on a framework, a database, or a sync engine. "Must a submitted record
be immutable?" is a model question. "Postgres or SQLite?" is not.

**REQUIRED SUB-SKILLS:** `gated-doc-interview` for the protocol, `glossary`
in `seed` mode once the gate clears.

## Prerequisites: fail loud

`PRODUCT.md` must exist; if not, point to `/validate`. If `DOMAIN.md` exists,
run in revision mode over the deltas only.

## Find facts first

The domain usually has prior art: a data standard, a reference database, a
field protocol, a regulation. **Search for it before asking.** A concept the
standard already names gets the standard's meaning as the recommendation
(recorded as the glossary `source:`), and a deliberate departure from it is
a decision the user makes knowingly, never by accident.

## Interview areas

Skip what `PRODUCT.md` answers. Size to its Scope size.

- **Boundaries**: which parts of the problem this product owns, and which
  it only references (an external taxonomy, an identity provider). One
  context is the default for a solo project; propose a second only where one
  word genuinely means two things.
- **Concepts**: every noun the Now scope needs, classified: **aggregate**
  (has identity, a lifecycle, and rules spanning its parts: the unit that is
  saved, synced, and locked together), **entity** inside one, or **value**
  (defined by its content, immutable). Recommend the smallest aggregates
  that keep each rule inside one.
- **Lifecycles**: for each aggregate: its states, the transitions between
  them, who or what triggers each, and what is forbidden in each state.
  Irreversible transitions get called out: they drive the data rules.
- **Invariants**: the rules that must always hold, each one falsifiable,
  owned by one aggregate, and marked with where it is enforced: `client`,
  `server`, or `both` (for offline-capable products, a rule enforced only on
  the server can be broken for days on a device). Probe for them: what would
  make the data wrong, unpublishable, or untrustworthy?
- **Events**: facts the domain records in past tense ("Relevé submitted"),
  what each carries, and who reacts. Ask whether history must be kept as
  events rather than overwritten; audit needs usually decide it.
- **Policies**: reactions: "when <event>, then <command>".
- **Provenance & audit**: what must be traceable to who, when, how, and
  with what instrument or source; what may never be edited after the fact;
  how a correction is recorded.
- **Vocabulary**: for every concept: the English term, the code identifier,
  the synonyms to avoid, the source it aligns with. This is the glossary
  seed; ask it alongside the concept, never as a separate round.

## Numbering

Invariants are `INV-001`, `INV-002`, … in creation order. **A number is
never reused or renumbered**: a dropped invariant stays in the table marked
`(retired)`, because issues and code comments cite these IDs.

## Output: write to `docs/shipwright/DOMAIN.md`

```markdown
# Domain: <name>

## Purpose & boundaries
<what the model covers; what it only references, and where that lives>

## Contexts
<one line each; one context is normal>

## Model
### <Aggregate> (aggregate)
- identity: <how one is told apart; who assigns it>
- holds: <entities and values inside it>
- lifecycle: <state → state on trigger; forbidden actions per state>
- invariants: INV-001, INV-004

### <Value> (value)
- <what defines it>

## Invariants
| ID | Rule (falsifiable) | Aggregate | Enforced at |
|---|---|---|---|
| INV-001 | <rule> | <Aggregate> | client / server / both |

## Events
| Event | Raised when | Carries | Consumers |
|---|---|---|---|

## Policies
- When <event>, then <command>.

## Provenance & audit
<what is traced, what is immutable, how corrections are recorded>

## External vocabularies
<standards and references the model aligns with, and deliberate departures>

## Open questions
<unresolved points that do not block /architect>
```

A mermaid `stateDiagram-v2` per non-trivial lifecycle is welcome. **Cap at
four pages**; `/plan` and `domain-review` re-read it for every sub-task.

## After the gate

1. Write `DOMAIN.md`, commit `docs(domain): <what changed>`, push.
2. Invoke `glossary` in `seed` mode (revision: `add`/`revise`/`retire` for
   the deltas only) with the confirmed vocabulary. `lint` must pass before
   the commit.
3. In revision mode, list the `INV-` IDs that changed or retired and search
   open issues citing them (`gh issue list --search "INV-004"`), so their
   criteria can be revisited. Never edit those issues from here.

Suggest, do not run, `/discover`, unless inside `/init`.

## Common mistakes

- Writing tables and columns → that is `/architect`'s data model. Here there
  are only concepts, rules, and states.
- An invariant nobody could test ("data is consistent") → name the state
  that would be wrong.
- One giant aggregate "to be safe" → it becomes the lock everyone fights
  over, and the sync conflict unit.
- Skipping `Enforced at` → offline clients break server-only rules silently.
- Treating the glossary as a later chore → the names chosen here become the
  class names in the first sub-task.
