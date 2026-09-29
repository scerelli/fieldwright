---
name: preflight
description: Use at the start of /init, /decompose, or /build before any pipeline work begins, when environment problems (gh auth, no GitHub repo, missing type labels, dirty tree, no subagent mechanism) must fail fast instead of mid-run.
---

# Preflight — fail fast, not mid-pipeline

Environment problems found three sub-tasks into a `/build` waste hours. One
call converts them into one message up front.

```bash
scripts/preflight.sh build --item <n> [--ui]     # from /build
scripts/preflight.sh decompose [--fast]          # from /decompose
scripts/preflight.sh init                        # from /init
scripts/preflight.sh release-lock --item <n>     # when /build returns control
```

Checks gh auth, that a GitHub repo actually backs this directory, gh version
(`--parent`/`--add-blocked-by`), `jq`, the label set, and — for `build` — the
build lock, a clean tree, the required docs, that `GLOSSARY.md` lints, and
that CI exists at all. It
stops at the first failure and names the fix.

| exit | meaning | what the caller does |
|---|---|---|
| 0 | passed | continue, after the manual check below |
| 1 | a check failed | refuse to start; show stderr verbatim |
| 5 | build lock held | **ask the human** — see below |

## The CI question, answered once

CI is the only thing gating every merge below production, so `build` refuses
to start on a repo that has none — checked as an in-repo config file, else a
live GitHub Actions workflow count. A repo genuinely without CI says so with
`SHIPWRIGHT_NO_CI=1`, and preflight reports that it is running ungated.

That declaration belongs to the human and is made here, once. **Never set it
to get past a failing gate mid-run** — `pr.sh` refuses to merge without checks
precisely so this cannot be decided at the moment it is inconvenient.

## The one check you must do yourself

`preflight.sh` cannot see whether your platform can spawn a subagent. After
it passes, verify that yourself:

- **No subagent mechanism** → warn explicitly and offer to run sub-tasks
  inline in the main context, same sequence and branch rules. Never silently
  degrade.
- **No *nested* subagents** (a sub-task subagent can't spawn its own
  reviewer) → plan the `/build`-spawned reviewer fallback in the `review`
  skill.

## Exit 5 — the build lock

The lock guards this working directory against a second concurrent `/build`.
On exit 5, stop and show the human `.shipwright/build.lock/info`. Either
another `/build` is genuinely running (do not touch it, or the tree), or a
prior run crashed (`scripts/preflight.sh release-lock`, then retry). **Never
guess which.**

Release the lock with `scripts/preflight.sh release-lock --item <n>` whenever
`/build` returns control — `shipped`, `stuck`, or `design-flaw`. A paused
`/build` is not a running one, and holding the lock would block the human's
own fix-up session. Passing `--item` makes the release refuse (exit 1) if the
lock belongs to a different item, so a crash-recovery cleanup cannot drop
another run's lock.

## Mode notes

- **init** — greenfield: no docs required, a dirty tree is expected. A GitHub
  repo **is** still required — `gh auth status` passing says nothing about
  this directory, and without a remote `/init` would clear preflight, run five
  interviews, then fail at the first push. The fix is named:
  `gh repo create --source=.`.
- **build** also reports which docs still carry `/init`'s
  `<!-- shipwright:deferred -->` marker — a note, not a failure, so a lean
  start that outgrew itself stays visible rather than silently keeping
  `/plan` lenient.
- **decompose** — `--fast` skips only the target-doc gate check, and only
  when the human passed it explicitly. Never infer it from "this looks like a
  small project."
- **build** — pass `--ui` for items that touch UI, so `UX.md` and
  `DESIGN.md` are required too (a deferred placeholder satisfies this).

See `reference.md` for why the lock is a directory and why it is checked
before the clean-tree test.
