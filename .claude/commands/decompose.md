---
description: Decompose an approved doc or issue into the Epic/Story-Task-Bug/Sub-task GitHub issue hierarchy
argument-hint: '<target> [--fast]'
---

Invoke the `decompose` skill and follow it exactly. The target is the document
or parent issue to decompose into the hierarchy's labeled sub-issues (three
tiers: Epic → Story/Task/Bug → Sub-task). The optional `--fast` flag
skips `preflight`'s check that the target doc has been through its gate (e.g.
`docs/shipwright/PRODUCT.md` through `/validate`) — use only when you
deliberately accept decomposing against an ungated doc:
$ARGUMENTS

<!--
Invocation:
- Claude Code: /decompose
- Kimi Code CLI: /skill:decompose
-->
