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
