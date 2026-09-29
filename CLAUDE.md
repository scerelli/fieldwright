# CLAUDE.md

This repo keeps one agent-instruction source of truth, in the vendor-neutral
agents format. Read and follow **`AGENTS.md`** and the skills under
**`.agents/skills/`** — do not duplicate or fork their guidance here.
`.claude/skills` is a symlink to `.agents/skills`; `.opencode/command`
symlinks `.claude/commands`.

## Commit attribution

Never add `Co-Authored-By`, Claude/AI attribution trailers, `Claude-Session:`
lines, or "Generated with" footers to git commit messages or pull request
descriptions. Plain conventional-commit messages and PR bodies only.

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
