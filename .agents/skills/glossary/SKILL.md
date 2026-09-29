---
name: glossary
description: Use when a domain term must be added, renamed, or retired in GLOSSARY.md, when /model seeds the glossary, or when text or a diff must be checked against the project's ubiquitous language.
---

# /glossary: the ubiquitous language, enforced

`docs/shipwright/GLOSSARY.md` is the one list of words this project uses for
its domain concepts, and the code identifiers each word becomes. Issues,
criteria, code, UI copy, and commit messages all speak it. A second word for
the same concept is how a model drifts: two names get two classes, and the
bug is the day they disagree.

The file is written in English and read by a script, so its shape is fixed.

**REQUIRED SUB-SKILL:** `gated-doc-interview` for `add`/`revise`/`retire`.

## Entry format: exact

```markdown
## Relevé
- code: `Releve`
- definition: The record of every plant taxon in one plot at one visit, with its cover-abundance per layer.
- concept: DOMAIN.md › Relevé (aggregate)
- source: Veg-X `plotObservation`
- avoid: survey, sample, vegetation record
```

- `## <Term>` opens an entry: the word people say, singular, English.
- `code:` required. Backticked identifiers, comma-separated; `-` when the
  concept has no identifier. An identifier belongs to exactly one term.
- `definition:` required. One or two sentences a newcomer could act on;
  never a synonym, never circular.
- `concept:` which `DOMAIN.md` element this names, when it names one.
- `source:` the external standard or reference the term aligns with.
- `avoid:` synonyms that must not be used for this concept. The script
  flags them in text and diffs, identifier-aware and plural-aware
  (`avoid: sample` flags `sampleId`, `SAMPLES`, "samples").
- `note:` anything else. No other field is valid.

Text before the first `##` is free prose. Order entries alphabetically.

## Modes

**`seed`**: called by `/model` once its gate clears, with the confirmed
term list. Write every entry, run `lint`, commit as
`docs(glossary): seed from domain model`. No interview of its own: the
`/model` summary already carried each term, identifier, and avoid list.

**`add <term>` / `revise <term>` / `retire <term>`**: a short
`gated-doc-interview`: definition, identifier, avoid list, concept, source,
each with a recommendation. Before recommending an identifier, run `terms`
and search the code for existing names of the concept, so the proposal
matches what exists or says what must be renamed. Retiring a term moves it
under a final `## Retired` heading as `- <Term>: retired <YYYY-MM-DD>, use
<Replacement>`, and adds the old word to the replacement's `avoid:`.

A rename of an identifier that exists in code is **scope, not a glossary
edit**: after the gate, offer `/ideate` for a `Task` carrying the rename.
Never rename code from here.

Commit each change alone: `docs(glossary): add <term>` (or `revise`,
`retire`). Stage exactly `GLOSSARY.md`.

**`check`**: run the script; see below.

## The script

```bash
scripts/glossary.sh lint                    # structure, duplicate codes, self-flagging avoid entries
scripts/glossary.sh terms                   # "<Term><TAB><codes>" per entry
scripts/glossary.sh scan -  < issue-body.md # avoided words in free text
scripts/glossary.sh check "$BASE_SHA" "$HEAD_SHA"   # avoided words in added lines
```

| exit | meaning | what the caller does |
|---|---|---|
| 0 | clean | continue |
| 1 | findings on stdout, one per line: location, the avoided word, the term to use | treat each as a finding; never edit the glossary to make one disappear |
| 2 | usage error or unresolvable revision | fix the call |
| 3 | `GLOSSARY.md` missing or malformed | `/model` or `/glossary`, then `lint` |

`check` skips `docs/shipwright/`, `docs/adr/`, `CHANGELOG.md`, lockfiles,
and every glob in a root `.glossaryignore` (generated or vendored code). A
line containing `glossary:allow` is skipped: the escape for a name you do
not own (a standard's field, a library API). It must say why on the same
line, and `/domain-review` rejects a bare one.

## Common mistakes

- Adding an `avoid:` entry that is part of another term's own name → `lint`
  rejects it, because every correct use would be flagged.
- The same avoided word under two terms → `lint` rejects it: a finding must
  name exactly one term to use instead.
- Loosening the glossary to silence a `check` finding → the finding is
  about the code. Change the glossary only through a gated `revise`.
- One term per class → the glossary lists concepts people talk about, not
  every type. A helper class needs no entry; a new concept does.
- Defining a term with its avoided synonym ("a relevé is a survey…").
