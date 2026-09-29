---
name: repo-bootstrap
description: Use when /init has finished writing its document set and must finish one-time repo setup — project-context pointers and local .shipwright state.
---

# repo-bootstrap — one-time greenfield repo setup

## Overview

`/init` ends here, once its document set exists: point future agents at the
pipeline, and set up local working-tree state. Neither step depends on
anything the interviews decided — they're pure repo bootstrapping — so this
skill is the one place that logic lives.

Recipe skill: no interview, no human gate of its own. It runs once, at the
end of `/init`, after the document-writing steps have committed, deferred
placeholders included.

## Step 1 — Project context files

Upsert a pointer section into `CLAUDE.md` and `AGENTS.md` at the repo root
(create either file if it doesn't exist) so agents working the repo later
can infer when to reach for a pipeline command from a plain-language
request, not just from a typed slash command:

```markdown
<!-- shipwright:start -->
## Delivery pipeline (Fieldwright)

This repo uses Fieldwright, a fork of [Shipwright](https://github.com/cherfia/shipwright),
for planning and delivery. Before improvising a plan, decomposition, or build
step by hand, check whether one of these already covers the ask:

| If the user wants to... | Reach for... |
|---|---|
| turn a rough idea into the doc set | `/init` (greenfield; `--full` adds `/ideate` and `/design`, `--lean` also defers `UX.md`) |
| revise one doc | `/validate` `/model` `/discover` `/architect` `/ux` `/design` (revision interviews) |
| add, rename, or retire a domain term | `/glossary` |
| split a doc or issue into smaller GitHub issues | `/decompose <target>` |
| know what to work on next | `/recommend` (read-only) |
| implement an epic/story/task/bug | `/build <item>` |
| mark a sub-task/item done | `/ship` (`--force-close` to close an item with sub-tasks descoped) |
| cut a release | `/release <version>` |

Pipeline state lives in `docs/shipwright/` (`PRODUCT.md` → `DOMAIN.md` +
`GLOSSARY.md` → `TECH_STACK.md` → `ARCHITECTURE.md` → `UX.md` → `DESIGN.md`).
Check which exist, and which still carry a `<!-- shipwright:deferred -->`
marker, before assuming greenfield vs. in-flight.

**Always, even outside the pipeline:** name domain concepts only with
`GLOSSARY.md` terms and their `code:` identifiers, and keep `DOMAIN.md`'s
`INV-` invariants true. `/glossary check` flags avoided synonyms in a diff.
<!-- shipwright:end -->
```

Idempotent: if a file already has a `<!-- shipwright:start -->` /
`<!-- shipwright:end -->` block, replace only what's between the markers —
never touch the rest of the file. If a file exists without the markers,
append the block to the end (preceded by a blank line). Never overwrite
unrelated content, and never create a file just to delete it — if writing
fails, warn and continue; this step never blocks the pipeline.

## Step 2 — Local working-tree state

Once the project-context pointers are committed, add `.shipwright/` to
**`.git/info/exclude`** — not `.gitignore`. The lock is local-only state, and
`.gitignore` is tracked, so writing it would dirty the working tree that
`/build`'s own preflight later requires clean. `preflight` writes the same
entry on its first `build` run; doing it here just means it is in place from
the start. Nothing to commit either way. Also create the
`.shipwright/` directory locally now, for this session's convenience — it
won't survive a fresh clone since it's gitignored, so this is a courtesy,
not the guarantee: `preflight`'s `/build`-mode check creates it again
(`mkdir -p`) whenever it's missing, regardless of what ran first.

## Completion

Done once the above completes. End by **suggesting — not auto-running** —
the next step:

```
/decompose docs/shipwright/PRODUCT.md
```

to generate the first round of epics from the approved product
definition.

## Common mistakes

- Running this before the document set is committed → the pointer block is
  meant to describe a repo that already has its docs in place, not an empty
  or partial one.
- Writing `.shipwright/` to `.gitignore` instead of `.git/info/exclude` →
  `.gitignore` is tracked, so that dirties the tree `/build` requires clean.
