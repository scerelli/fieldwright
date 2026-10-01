# field-app

Collaborative detection/non-detection survey app. Planning and delivery run on
Fieldwright (a Shipwright fork), installed in this repo under `.claude/`.

## First run

```bash
cd field-app
git init -b main
git add -A && git commit -m "chore: bootstrap with fieldwright skills and brief"
gh repo create field-app --private --source=. --push
claude
```

Then, inside Claude Code:

```
/init docs/brief.md
```

The interviews draft from `docs/brief.md` and ask only what it leaves open.
Every doc lands in `docs/shipwright/`; `/init` ends by writing `CLAUDE.md`.
Next: `/decompose docs/shipwright/PRODUCT.md`, then `/recommend` and `/build`.

## Requirements

A recent `gh` (supports `gh issue create --parent` and
`gh issue edit --add-blocked-by`), `jq`, `git`, bash, awk. `/build` also
needs CI on the repo (add a workflow once `/discover` has pinned the stack).

## Updating the skills

`.agents/skills` (the canonical, vendor-neutral copy; `.claude/skills` is a
symlink to it) and `.claude/commands` are a copy of the Fieldwright plugin.
To update, replace both from a newer Fieldwright and commit.

## Repository layout

- `app/` — Flutter client (created by the app-shell Epic).
- `server/` — NestJS API and BullMQ worker.
- `packages/protocol/` — the shared protocol definition format.
- `infra/` — Docker Compose stack and CI workflows.
- `docs/shipwright/` — the planning documents (product, domain, glossary, stack, architecture, UX, design).
- `docs/adr/` — the decision log.

## Local development

```bash
make dev        # Turborepo-like TUI (mprocs): api + mobile + db logs
```

`make dev` opens an [mprocs](https://github.com/pvolok/mprocs) TUI with a
process sidebar — switch with the arrow keys, `r` restarts a process, `s`
starts the on-demand `worker`. Processes: `api` (infra → migrations → Nest
watch), `mobile` (emulator + `flutter run`), `db` (compose logs), `worker`.

### Dev lifecycle

`make dev` brings up `db` + `redis` (Docker) and the API runs migrations, then
starts `api`, `mobile` and the `db` log tail; `worker` starts on demand with
`s`.

Press `q` to quit. mprocs stops `api`, `mobile` and `worker`, then exits
without needing to close the terminal — each proc is declared
`stop: "SIGKILL"`, so a child that ignores SIGTERM (the
`docker compose logs -f` tail is the usual one) cannot hold the TUI open.
Quitting leaves the **emulator** and **db + redis** running, so the next
`make dev` reuses the emulator and the database.

`make dev-stop` clears stuck dev processes: it kills any leftover mprocs, api,
worker or `flutter run` while leaving the emulator and db/redis up.
`make stop` then stops db + redis.

```bash
make dev-one    # same stack in a single terminal, no TUI
```

Other targets: `make infra`, `make migrate`, `make migrate-generate`,
`make server`, `make worker`, `make android`, `make dev-stop`, `make stop`,
`make logs`.

Overrides (env or `make VAR=...`): `EMULATOR_ID`, `DEVICE`, `API_PORT`,
`DATABASE_URL`, `REDIS_URL`. The dev database/redis are published on
`55432`/`56379` so the host-run API does not collide with a local Postgres on
`5432`.

Requires `docker`, `pnpm` 12.8, Node 24, and the Flutter SDK.

### API base URL

The app reads its server root from one compile-time value,
`IBIS_API_BASE_URL`, passed with `--dart-define`. Its default is
`http://localhost:3000`, correct for a host-run API reached from the iOS
simulator or desktop. Override it per environment:

```bash
# Local host (iOS simulator / desktop) — the explicit form of the default
flutter run --dart-define=IBIS_API_BASE_URL=http://localhost:3000

# Android emulator — 10.0.2.2 is the host loopback as seen from the emulator.
# scripts/dev-android.sh (make dev / make android) passes this for you.
flutter run -d emulator-5554 \
  --dart-define=IBIS_API_BASE_URL=http://10.0.2.2:<API_PORT>

# Production
flutter build apk --release \
  --dart-define=IBIS_API_BASE_URL=https://api.example.com
```

A release (`--release`) build that does not define `IBIS_API_BASE_URL` fails
loudly at startup instead of silently pointing at `http://localhost:3000`.
