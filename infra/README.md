# infra

Deployment and CI infrastructure for IBIS: the `docker-compose` stack for
local development and self-hosting, and the GitHub Actions workflows.

## The Compose stack

`docker-compose.yml` runs the whole server from one command:

| Service | Image / build | Published | Notes |
|---|---|---|---|
| `api` | builds `../server/Dockerfile` | `${API_PORT:-3000}` → 3000 | runs `node dist/main.js` |
| `worker` | builds `../server/Dockerfile` | none | overrides the command with `node dist/worker.js` |
| `db` | `postgis/postgis:18-3.6` | none (internal only) | PostgreSQL 18 + PostGIS |
| `redis` | `redis:7-alpine` | none (internal only) | BullMQ queue backend |

`api` and `worker` share the same image, built once from `server/Dockerfile`.

## Configuration

Copy the example and adjust:

```bash
cp infra/.env.example infra/.env
```

`POSTGRES_USER`, `POSTGRES_PASSWORD` and `POSTGRES_DB` name the database and
build the `DATABASE_URL` that `api` and `worker` connect with, so the three
stay in sync. `API_PORT` is the host port the API is published on. Every
setting has a default in the Compose file, so the stack starts without a
`.env`; the file only changes the defaults.

The `DATABASE_URL` and `REDIS_URL` the server reads point at the Compose
service names (`db`, `redis`) on the internal network, so no connection string
is configured by hand.

## Volumes

Two named volumes hold persistent state:

- `db` — mounted at `/var/lib/postgresql` (PostgreSQL 18's data directory).
- `media` — mounted at `/data/media` in both `api` and `worker`; the storage
  location for Evidence files.

`docker compose down` keeps both. `docker compose down -v` removes them.

## Running

```bash
docker compose -f infra/docker-compose.yml up --build
```

`api` and `worker` wait for `db` and `redis` to report healthy before
starting. Validate the file without starting anything with:

```bash
docker compose -f infra/docker-compose.yml config
```

## Smoke test

`scripts/smoke.sh` verifies `docker compose up` end to end: it brings the stack
up, polls `GET /readyz` until the API reports ready (HTTP 200), then tears the
stack back down.

```bash
infra/scripts/smoke.sh
```

It exits non-zero if a required service fails to become healthy — either
`/readyz` never returns 200 before the timeout, or a Compose service has
exited, died, or turned unhealthy. The stack is torn down (`docker compose
down`, keeping the named volumes) whether the check passes or fails.

The script reads `infra/.env` if it exists, so it honours the same `API_PORT`
as the stack. These environment settings tune it:

| Setting | Default | Effect |
|---|---|---|
| `API_PORT` | `3000` | host port the API is polled on |
| `SMOKE_TIMEOUT_SECONDS` | `180` | how long to wait for `/readyz` |
| `SMOKE_POLL_INTERVAL_SECONDS` | `2` | delay between `/readyz` polls |

`scripts/smoke.test.sh` exercises the script's control flow with stubbed
`docker` and `curl`, without a Docker daemon:

```bash
infra/scripts/smoke.test.sh
```
