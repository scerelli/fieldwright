---
name: release
description: Use when cutting a production release — a short-lived release branch off production that lands back there under a tag.
---

# /release — cut, tag, and land a release

`/release <version>` cuts a short-lived `release/<version>` branch, hosts
last-minute stabilization and the changelog, then lands it into production
under a tag. Along with `/ship`'s last hop, it is one of only two ways
production is ever touched — see `CONVENTIONS.md`.

**REQUIRED SUB-SKILLS:** `gh-pr-merge` for the merge, `conventional-commits`
for every title and commit.

## Prerequisites — fail loud

- Working tree is clean.
- `scripts/version.sh check <version>` — exit 2 (`already-released`) means
  stop, this is not a retry. `retry-after-tag` / `retry-branch-exists` /
  `new` all proceed; every step below is idempotent.

## Step 0 — Suggest a version

```bash
scripts/version.sh suggest      # prints "<version>\t<reason>"
```

Present it with its reason and ask the human to confirm or override.
`<version>` is always whatever the human confirms — never applied silently.

## Step 1 — Cut the branch

```bash
BASE=$(../gh-pr-merge/scripts/pr.sh production-branch) || exit 1
git checkout -b release/<version> "origin/$BASE" && git push -u origin release/<version>
```

If it already exists (retry), check it out — never recreate. Cutting the
branch, rather than committing the changelog straight to production, is what
keeps the production gate in front of every release.

## Step 2 — Stabilize

Last-minute fixes are plain commits on `release/<version>`, formatted per
`conventional-commits`. Human-driven; `/release` hosts the branch, it does
not invent fixes.

## Step 3 — Changelog

```bash
scripts/changelog.sh <version>
git add CHANGELOG.md && git commit -m "docs(changelog): <version>" && git push
```

Must land **before** Step 4 so it merges into production in the same PR —
never pushed afterward as an afterthought.

## Step 3b — Versions, compatibility, artifacts

Read `TECH_STACK.md`'s **Release artifacts** table. Absent → say so and skip
this step; never guess an artifact list.

1. **Versions.** Set `<version>` in every file the table's "Version lives
   in" column names (a mobile build number must also increase
   monotonically). One commit: `chore(release): set version <version>`.
2. **Compatibility.** For each surface in `ARCHITECTURE.md`'s Compatibility
   surfaces, read the version this code actually speaks from the source
   (a protocol constant, the latest migration, a format version), never
   from memory, and add a `### Compatibility` block to this release's
   `CHANGELOG.md` entry: surface, version, oldest counterpart supported.
   Never amend: add a follow-up commit, `docs(changelog): compatibility`.
3. **Build** each artifact with its exact build command. A failed build is
   a stabilization fix (Step 2), never a skipped artifact.

## Step 4 — Merge into production, tagged

One merge, one tag, then the branch is deleted:

```bash
../gh-pr-merge/scripts/pr.sh land-and-tag \
  --head release/<version> --tag "v<version>" \
  --title "chore(release): <version>" --body "Release <version>"
```

Branch on the exit code per `gh-pr-merge`'s table — exit 4 (the human gate) is
handled exactly as it specifies, with the merge presented as
`release/<version>` → production plus the tag.

**Exit 3** → checks failed on the release branch. Stabilize further on the
same branch and re-run. The tag is only ever created after the production
merge lands, so an exit 3 never leaves a half-released version behind.

## Step 5 — Publish, after the tag

Only once Step 4 returned success. Publish what was built from the tagged
commit (rebuild if the tag is not the commit Step 3b built). List every
artifact with its destination, then ask for an explicit yes **per destination**: a store
submission cannot be recalled like a merge. Run pinned publish commands
exactly as written; for manual ones, hand the human a checklist. Report
what was published and what was left.

## Return

`shipped` (merged, tagged, branch deleted, publishing reported) or `stuck` with the error — the
vocabulary in `CONVENTIONS.md`, not a `/release`-only verb.

## Urgent single fixes

There is no separate emergency path. A production bug is a Bug issue, built
through `/build` like anything else, then released with
`scripts/version.sh suggest --patch` to force a patch bump. The same CI gate
and the same human gate apply — urgency is a reason to move fast through the
pipeline, never a reason around it.

## Common mistakes

- Guessing or auto-applying `<version>` → `suggest` recommends, the human
  decides.
- Tagging before the production merge lands → the tag belongs to the merge
  commit, and `land-and-tag` orders this correctly.
- Committing the changelog straight to production to skip the branch → that
  bypasses the gate the branch exists to preserve.

Reverting a release that already reached production is a new fix forward,
never a force-push — see `reference.md`.
