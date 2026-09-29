# preflight — reference

## Why the lock is a directory

`mkdir` is the atomic primitive. The filesystem guarantees exactly one caller
wins when two processes race to create the same directory at the same
instant. A plain "check the file exists, then write it" cannot guarantee that
— two `/build` invocations started moments apart could both observe "absent"
before either writes, defeating the lock entirely.

The `info` file inside is written *after* the directory is won, and is a
marker for a human to read, not the mutex itself. It records the item number
and a UTC timestamp, best-effort.

The release lives in the same script as the acquire, as `release-lock`. It
used to live in `build/SKILL.md` as prose, which put half a mutex in the hands
of a model that may never reach that instruction — and a lock nothing reliably
clears makes every exit 5 ambiguous, so the prompt it produces stops carrying
information. `release-lock` runs before the gh checks, deliberately: a crashed
run must be able to clean up without a working network. It also honours the
`item=` line, refusing to release a lock another `/build` recorded.

## Why the lock is checked before the clean-tree test

A genuinely running concurrent `/build` has an in-flight subagent, which
necessarily makes the working tree dirty. If the clean-tree check ran first,
it would misdiagnose that as an ordinary dirty tree and tell the human to
"commit or stash" — silently clobbering the other run's uncommitted work.

Order matters here for correctness, not tidiness.

## What the lock does and does not guard

It guards **one clone's working directory** — exactly one `/build` process
may touch this repo's working tree at a time.

It does **not** guard the GitHub repo. The lock file is gitignored, local-only
state, so a second `/build` started from a different clone or machine against
the same repo will not be detected. Nothing in this pipeline currently
detects that case.

## Why labels are created rather than checked

`gh issue create --label` and `gh issue edit --add-label` both fail if the
label does not already exist, so preflight creates all ten unconditionally
with `--force` (create-or-update). That also normalizes color and description
regardless of prior state — including GitHub's auto-created default `bug`
label. See `gh-sub-issues`' reference for the collision that causes on repos
already using `bug` for ordinary reports.

A label-creation failure is a permissions problem and stops the pipeline. It
is never a reason to fall back to a body-text or title-prefix convention.

## When the lock is stale

The lock records a UTC timestamp in `.shipwright/build.lock/info` and nothing
else — no PID, no heartbeat. That is intentional: an agent has no reliable
cross-platform clock or process table, so the file is a marker for a human to
read, not a mutex with liveness.

The practical consequence for a solo developer: **you are almost never racing
yourself across two clones.** The lock's real-world effect is blocking you
after your own crash. So when preflight exits 5, the question to put to the
human is specific, not open-ended — show the recorded item and timestamp and
ask: *"Is a `/build` actually running right now? If not, this is crash
residue and safe to clear."*

An hours-old timestamp with no agent running is crash residue. Clearing it is
`scripts/preflight.sh release-lock`. What is never acceptable is clearing it
**without asking**, because the one case it exists for — a genuinely running
build in another window — is exactly the case where clearing it destroys work
that is not yours to destroy.
