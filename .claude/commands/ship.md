---
description: Merge a finished sub-task and run the item ship cascade (epic and milestone closes are report-only)
argument-hint: '[--force-close <item-issue>]'
---

Invoke the `ship` skill and follow it exactly. With no flag, the argument is
the sub-task issue or additional context. `--force-close <item-issue>` runs
only the item-ship step by hand — merge the item branch and close the issue —
for an item whose remaining Sub-tasks are deliberately descoped, or whose
cascade needs re-running: $ARGUMENTS

<!--
Invocation:
- Claude Code: /ship
- Kimi Code CLI: /skill:ship
-->
