---
name: conventional-commits
description: Use when a pipeline skill (implement, ship, release) is about to write a git commit message or a PR title on the target repo, to format it per Conventional Commits.
---

# conventional-commits — commit and PR title format

Every commit `/implement` writes and every PR title `/ship` and `/release`
open uses this format, so the git and PR history reads as one
machine-parseable log.

```
<type>(<scope>): <description>

<body>

Refs #<n>
```

Write it, then verify:

```bash
scripts/check.sh "feat(auth): add login"      # header or PR title
scripts/check.sh --file <path>                # full message
```

Exit 1 names every problem. Fix and re-check rather than shipping a
malformed header.

## Rules

- **Header** — one line, imperative mood ("add", not "added"), no trailing
  period, under 72 chars.
- **Description from an issue title** — normalize it: imperative, lowercase
  first word unless a proper noun, no period. Identical whether it becomes a
  commit message or a PR title.
- **Body** — optional, after one blank line. Explain *why*; the diff shows
  what.
- **Footer** — `Refs #<n>`. **Never `Closes #<n>` in a trailer** — closing is
  an explicit `gh issue close` step, not a side effect of a commit landing
  somewhere. This governs trailers and titles only; PR **bodies** keep
  `Closes #<n>` deliberately, as GitHub's merge-time link.

## Types

`feat` (user-visible capability) · `fix` · `docs` · `refactor` (no behavior
change) · `test` · `perf` · `build` · `ci` · `chore` · `revert`

Pick the single type matching the **primary** nature of the issue's
acceptance criteria. Never blend (`feat/fix:`) — name the dominant type in
the header, mention the rest in the body.

## Scope

Optional. Derive from the primary module in the issue's files/modules list
(`src/auth/` → `feat(auth):`). **Omit it** when the change spans unrelated
areas — a misleading scope is worse than none.

For item- and epic-level PRs, which carry no files/modules
list: type is the dominant type across the closed children, defaulting to
`feat` when mixed; scope only when every child shares one module.

## Common mistakes

- `Closes #<n>` in a commit trailer → use `Refs #<n>`.
- Blending types → pick the dominant one.
- Forcing a scope across unrelated areas → omit it.
- Copying an issue title verbatim as a PR title → it needs the type prefix;
  the title itself must be a valid header.
