# field-app

Collaborative detection/non-detection survey app. Planning and delivery run on
Fieldwright (a Shipwright fork), installed in this repo under `.claude/`.

## First run

```bash
cd field-app
git init -b main
git add -A && git commit -m "chore: bootstrap with fieldwright skills and brief"
gh repo create field-app --private --source=. --push
claude
```

Then, inside Claude Code:

```
/init docs/brief.md
```

The interviews draft from `docs/brief.md` and ask only what it leaves open.
Every doc lands in `docs/shipwright/`; `/init` ends by writing `CLAUDE.md`.
Next: `/decompose docs/shipwright/PRODUCT.md`, then `/recommend` and `/build`.

## Requirements

A recent `gh` (supports `gh issue create --parent` and
`gh issue edit --add-blocked-by`), `jq`, `git`, bash, awk. `/build` also
needs CI on the repo (add a workflow once `/discover` has pinned the stack).

## Updating the skills

`.agents/skills` (the canonical, vendor-neutral copy; `.claude/skills` is a
symlink to it) and `.claude/commands` are a copy of the Fieldwright plugin.
To update, replace both from a newer Fieldwright and commit.

## Repository layout

- `app/` — Flutter client (created by the app-shell Epic).
- `server/` — NestJS API and BullMQ worker.
- `packages/protocol/` — the shared protocol definition format.
- `infra/` — Docker Compose stack and CI workflows.
- `docs/shipwright/` — the planning documents (product, domain, glossary, stack, architecture, UX, design).
- `docs/adr/` — the decision log.
