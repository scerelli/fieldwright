---
description: Run the document pipeline end-to-end (validate → model → discover → architect → ux; --full adds ideate and design)
argument-hint: '[--full | --lean] [brief file or text]'
---

Invoke the `init` skill and follow it exactly. The default solo profile runs
`/validate`, `/model`, `/discover`, `/architect`, `/ux` and defers `DESIGN.md`
to a `<!-- shipwright:deferred -->` placeholder. `--full` adds `/ideate` and
`/design`; `--lean` also defers `UX.md`. Any other text is a brief or
additional context for the pipeline: $ARGUMENTS

<!--
Invocation:
- Claude Code: /init
- Kimi Code CLI: /skill:init
-->
