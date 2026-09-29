---
name: discover
description: Use when turning an approved PRODUCT.md into TECH_STACK.md — the technology selection gate of the Shipwright pipeline, before architecture work begins.
---

# /discover — TECH_STACK.md

Turns an approved `PRODUCT.md` into the pinned, justified stack that
`/architect` and every later `/plan` treats as ground truth. **Human gate.**

**REQUIRED SUB-SKILLS:** `gated-doc-interview` for the protocol, `adr` to record every
substantive decision.

## Prerequisites — fail loud

`PRODUCT.md` must exist; if not, point to `/validate`. Read `DOMAIN.md`
(→ `/model`) first: invariants' `Enforced at` and provenance rules constrain
the data layer. If `TECH_STACK.md` exists, run in revision mode.

## Detect the existing stack first

**Before drafting any question** — this decides which questions are even
open. Scan for manifests (`package.json` + lockfile, `pyproject.toml`,
`go.mod`, `Cargo.toml`, `Gemfile`, `pom.xml`, `composer.json`), framework
config (`next.config.*`, `vite.config.*`, `manage.py`, …), infra
(`Dockerfile`, `docker-compose.yml`, `.github/workflows/`, `terraform/`), and
the `src`/`app` layout.

- **Stack already present** → treat every detected piece as an
  **already-pinned fact**, not an open decision. Interview only the *gaps*:
  what `PRODUCT.md`'s Now — v1/MVP requires that nothing detected provides
  (payments, a job queue, an auth provider, a missing data store). Reopen an
  installed choice only if it's clearly inadequate for a required feature or
  the user asks — and verify the inadequacy by web search (unmaintained,
  deprecated, missing a hard requirement) first. **"A newer option exists" is
  never sufficient grounds.**
- **Greenfield** → run the full recommendation flow across every area below,
  web-searching for current, actively-maintained options and pinning versions.

Either way, fold findings into the questions' options and recommendations.
**Never present a fact you could find as something the user must look up.**

## Interview areas

Skip what `PRODUCT.md` answers and what the scan found installed and
adequate. **Favor familiarity and ecosystem fit for a solo dev over
theoretical optimum.**

- **Platform targets** — derived from `PRODUCT.md`'s Now — v1/MVP, not a
  generic list. A platform named only in Next/Later becomes a Revisit
  trigger, not something built for now.
- **Language/runtime** — one primary language where possible. Already in use?
  That's the answer; don't reopen it.
- **Frameworks per surface** — 2–4 concrete current options with tradeoffs.
  **Verify currency by web search and pin major versions. Never recommend a
  framework you haven't confirmed is still alive.**
- **Tooling commands & MCP servers** — for each pinned library shipping its
  own scaffolding/component/package CLI, capture the **exact current
  command** in the same search that verified the pin. Never reconstruct one
  from memory. If it ships an official MCP server, note it and ask whether to
  install now (recommend yes — it's a reversible `.mcp.json` entry).
- **Data layer** — database, ORM/query layer, migrations.
- **Auth** — session vs. token, first-party vs. provider, matched to the
  chosen platforms.
- **Third-party services** implied by `PRODUCT.md`'s Now features — email,
  payments, storage, analytics. Confirm each still exists on comparable terms.
- **Hosting/infrastructure** — matched to scope size. **Do not propose
  Kubernetes for a weekend project.**
- **Testing & tooling** — test runner, lint/format, typecheck, CI baseline.
  Record **exact commands**, not tool names — every sub-task's local gate runs
  them. Give the linter's **autofix** form alongside the check-only one, both
  taking a trailing file list (`npm run lint -- <paths>`, or the underlying
  binary). **Include a
  dependency/vulnerability audit job** (Dependabot, or a scheduled/on-push
  action running `npm audit`/`pip-audit`/`govulncheck`/`osv-scanner`). This is
  the one place that check belongs — `/review`'s per-sub-task scan covers
  secrets only, so without it here it doesn't exist at all.
  Several packages → one block per package, keyed by path prefix.
- **Render proof** — per UI platform, the exact golden/screenshot test
  command and image path: a rerunnable `render` proof on a headless agent.
- **Release artifacts** — each thing a release produces (store build,
  container image): build command, destination, version file, and whether
  publishing is a command or manual. `/release` reads this by name.
- **Constraints** — cost ceiling, offline needs, existing code to match. **Ask
  early**; constraints invalidate options and shape later questions.

Ground every not-already-detected recommendation in web search, not memory.

## Recording decisions

For every **substantive** pin — data layer, auth, hosting, primary
language/framework, and any third-party service central to the product (not
routine tooling defaults unless the interview treated them as contested):

- New decision → `adr` in **record** mode; inline the returned `ADR-000N`
  into that line of Rejected alternatives.
- Revision changing a previous pin → `adr` in **supersede** mode with the
  existing reference; inline the new one.
- Carried through unchanged → no call, keep its existing reference.
- Routine/non-substantive → no call; note it inline without a reference.

Runs once per decision, immediately before writing the doc. Not a second
human gate — the summary confirmation already covered it.

## Installing confirmed MCP servers

Add or merge each confirmed server into `.mcp.json` at the repo root
(creating it if absent), using that server's **own published install spec**
(command, args, env) verified by web search — never a guessed package name or
transport. This edits a repo file; it does not network-install anything, as
most servers launch lazily via `npx`/`bunx`.

If the current agent reads MCP config elsewhere, still write `.mcp.json` and
note in the table below that other agents may need to mirror the entry.

## Output — write to `docs/shipwright/TECH_STACK.md`

```markdown
# Tech Stack: <name>

## Platforms
<targets, from PRODUCT.md's Now — v1/MVP>

## Languages & runtimes
<pinned major versions>

## Frameworks & key libraries
<pinned major versions, one line of rationale each>

## Data layer
<database, ORM/query layer, migrations>

## Auth
<strategy and provider>

## Infrastructure & hosting
<where it runs, how it deploys>

## Third-party services
<service — which PRODUCT.md feature requires it>

## Testing & tooling
<one block per package when there are several, headed by its path prefix>
<test runner — exact command to run the full suite, and to run one file>
<lint/format — exact autofix command, then the check-only command CI runs;
both in a form that takes a trailing file list>
<typecheck — exact command, listed separately from the linter>
<CI baseline, including the dependency audit job>
<render proof — golden/screenshot test command per UI platform, and the image path>

## Release artifacts
| Artifact | Build command | Published to | Version lives in | Publish step |
|---|---|---|---|---|

## Tooling & CLI
<library — exact command to scaffold/add code with it, pinned to the version
above (e.g. `bunx --bun @react-native-reusables/cli@latest add button`);
omit libraries with no such command>

## MCP servers
<library/service — official server name, install target (`.mcp.json` entry
added | available, not installed | none found), and the command if not
installed>

## Rejected alternatives
<one line per pinned decision: the choice, why alternatives lost, and its
`(ADR-000N)` reference>

## Revisit triggers
<what change (scale, platform, cost, team) would invalidate a choice>
```

Every choice pinned and justified in one line. **Four sections are
load-bearing:** Rejected alternatives and Revisit triggers stop `/plan` and
`/review` re-litigating settled decisions; Tooling & CLI and MCP servers are
quoted **verbatim** by `/plan` and `/implement` instead of reconstructing an
equivalent command.

## After the gate

`/architect` requires this file, and `/plan` refuses to run for any sub-task
without it. Suggest — do not run — `/architect`.
