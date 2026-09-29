# Architecture: IBIS — Integrated Biodiversity Inventory Survey

## Business context

IBIS turns a project's protocol into the default field workflow: a creator
defines a Project, its Protocol versions, Survey periods, Sites and Target
list; collectors capture Visits offline and submit them; submitted Visits are
immutable and change only through Corrections; validators may validate them;
researchers export occupancy- and GBIF-ready data. Recurring vocabulary is
defined in `GLOSSARY.md` and the model in `DOMAIN.md` — this document maps
them onto modules and persistence, and never restates them.

## Quality attributes

Ranked; the top one breaks ties everywhere below.

1. **Offline reliability & data integrity** — no Visit or Detection is lost on the device, and submitted data stays trustworthy and auditable.
2. **Non-devops deployability & operability** — the whole server is one Compose stack an operator can run and upgrade.
3. **Field performance & battery on low-end devices** — the capture loop stays responsive during long sessions.
4. **Privacy & security** — collector data is personal data (GDPR) and sensitive-taxa locations are a conservation risk.

## Assumptions & constraints

- One developer, one repository; a self-hosted single-host deployment.
- Devices are offline for whole days; the server may be one release behind the app.
- Low-end Android has no barometer: every sensor-backed field falls back to manual entry.
- Protocol definition is shared across Dart and TypeScript (ADR-0009).
- Postgres 18 + PostGIS, Redis, and Node; media on a volume with optional S3 (ADR-0007).

## System view

A Flutter client talks to a self-hosted NestJS modular monolith over a
versioned REST sync API. The same server image also runs as a BullMQ worker
consuming Export jobs from Redis. Postgres/PostGIS is the system of record;
evidence files live in a volume or an optional S3 backend.

```mermaid
flowchart LR
  Creator[Creator] --> App[IBIS mobile app]
  Collector[Collector] --> App
  Validator[Validator] --> App
  Researcher[Researcher] --> App
  App -->|/api/v1 sync + evidence| API[NestJS API]
  API --> PG[(PostgreSQL + PostGIS)]
  API --> Redis[(Redis queue)]
  API --> Store[(Media volume / S3)]
  Worker[BullMQ worker] --> Redis
  Worker --> PG
  Worker --> Store
  Operator[Self-hosting operator] --> API
  App -. tiles .-> OSM[OpenStreetMap tiles]
  Projects -. pin .-> Taxon[Taxonomic references]
```

## Module map (container view)

Each module names the `DOMAIN.md` aggregates it owns; an aggregate has exactly
one owner. Client modules own no authoritative aggregate — the in-progress
Visit and a field-created Site exist transiently on the device until
submitted.

### Client — `app/` (Flutter)

| Module | Responsibility | Interface | Owns |
|---|---|---|---|
| `shell` | App shell, routing, design tokens, Riverpod wiring (the foundational Epic) | navigation + theme providers | — |
| `identity` | Better Auth client; current person and their project roles | sign-in/out, session | — |
| `projects` | Pull and cache Project config, Protocol version, Survey periods, Target list, Sites | config providers | — |
| `capture` | Offline Visit capture loop: effort timer, per-target Detection entry, opportunistic taxa, covariates, end Visit | Visit state notifiers | in-progress Visit (local) |
| `sites` | Site list/map display and field Site creation | site editor | field-created Site (local) |
| `store` | drift database, schema, forward-only migrations | DAOs | local SQLite schema |
| `sensors` | sensors_plus / geolocator / record / image_picker wrappers + Provenance | measurement/evidence services | — |
| `outbox` | Submission upload, retry/backoff, config pull | sync orchestration | — |

### Server — `server/` (NestJS, REST)

| Module | Responsibility | Public interface | Owns |
|---|---|---|---|
| `identity` | Better Auth integration; resolves person and Memberships | auth guard, `@CurrentPerson()` | — |
| `projects` | Project setup and config for sync | `/projects`, `/protocol-versions`, `/survey-periods` | Project (with Membership, ProtocolVersion, SurveyPeriod, Target list, settings, pinned TaxonomicReference) |
| `sites` | Site lifecycle | `/sites` | Site |
| `visits` | Idempotent ingest, immutability, corrections, validation | `/visits`, `/visits/:id/corrections` | Visit (with Detection, Determination, Measurement, Evidence metadata, Correction) |
| `media` | Evidence storage abstraction and upload/download | `/media` | — |
| `exports` | Detection-history matrix, Darwin Core, CSV, GeoPackage (queue jobs) | `/exports` | — |
| `sync` | The versioned transport | `/api/v1/*` controllers | — |
| `worker` | Same image, BullMQ consumer for `exports` | queue consumer | — |

### Shared — `packages/protocol/` (TypeScript + Dart codegen)

Protocol definition format: TS types + JSON Schema, generated Dart, and golden
fixtures. No runtime aggregate.

## Data model

Persistence per aggregate; enforcement locus is recorded per `INV-` in
`DOMAIN.md`. Structural rules are Postgres constraints; rule-heavy rules run
in server code inside a transaction (ADR-0010).

```mermaid
erDiagram
  PROJECT ||--o{ MEMBERSHIP : has
  PROJECT ||--o{ PROTOCOL_VERSION : versions
  PROJECT ||--o{ SURVEY_PERIOD : defines
  PROJECT ||--o{ SITE : owns
  SITE ||--o{ VISIT : hosts
  VISIT ||--o{ DETECTION : produces
  DETECTION ||--o{ DETERMINATION : revised_by
  VISIT ||--o{ MEASUREMENT : records
  VISIT ||--o{ EVIDENCE : attaches
  VISIT ||--o{ CORRECTION : corrected_by
```

- **Project** → `project` (settings jsonb, pinned taxonomic-reference id + version), `membership`, `protocol_version` (document jsonb, `frozen_at`), `survey_period`.
- **Site** → `site` with `geom geometry(Geometry, 4326)` and `origin` enum; `site_measurement` for site covariates.
- **Visit** → `visit` (project/site/survey_period/protocol_version FKs, `state` enum, effort jsonb, timestamps, validation fields); `detection` (unique per target taxon per Visit, `opportunistic` flag); `determination` (`replaces_id` self-reference for append-only revisions); `measurement` (value, unit, `provenance` jsonb, owner = visit or detection); `evidence` (storage key + `sha256`, immutable); `correction` (author, reason, payload jsonb, append-only).
- **Constraints**: FKs, `state` enums, `CHECK` on non-negative counts, `ST_IsValid`/SRID checks, partial unique index `(visit_id, taxon_ref) WHERE NOT opportunistic`.
- **Immutability & append-only** (INV-001, INV-009): no UPDATE path for a submitted Visit, Determination or Correction in application code.
- **Provenance** (INV-010): `provenance.method` NOT NULL whenever a `measurement` row exists.
- **Sensitive coordinates** (INV-011): true geometry is stored; obfuscation happens in the read/export layer, never in storage.
- **Auth tables** are owned by Better Auth, co-located in Postgres via Drizzle.

## Compatibility surfaces

| Surface | Paths | Other side & skew tolerated | Rule | Proof owed |
|---|---|---|---|---|
| Sync REST API | `server/src/sync/**`, `app/lib/outbox/**` | app ↔ server; server may be one release behind | `/api/v1`, additive only, unknown fields ignored | contract tests both sides (OpenAPI + client) |
| Protocol format | `packages/protocol/**` | app ↔ server | versioned; additive changes extend; Project pins a version | golden fixtures validated in Dart and TS |
| Client schema | `app/lib/store/**` | device upgrades | forward-only migrations | migration test from each prior version |
| Server schema | `server/drizzle/**` | operator upgrades | forward-only migrations | migration test on a populated DB |
| Export formats | `server/src/exports/**` | analysts, GBIF | stable per format version; additive columns | golden fixtures |
| Media | `server/src/media/**` | volume/S3 | content-hashed keys, never mutated | upload + hash test |

## Key flows

**Authentication.** The client signs in against Better Auth; the API resolves
the person and their Memberships on every request via the auth guard. Roles
are project-scoped, never global.

**Primary journey.**

```mermaid
sequenceDiagram
  participant C as Collector (app)
  participant S as Server
  participant Q as Redis/worker
  C->>S: pull config since token
  S-->>C: project, protocol version, sites, target list
  C->>C: capture Visit offline (effort, detections, evidence)
  C->>C: end Visit
  C->>S: submit Visit (idempotent, UUIDv7)
  S->>S: enforce invariants, store immutable Visit
  S-->>C: accepted
  Note over S: validator validates or issues a Correction
  S->>Q: enqueue export
  Q-->>C: export artifact (matrix / Darwin Core / GeoPackage)
```

## Cross-cutting concerns

- **Error handling**: one error shape on the API; the client outbox retries with backoff and is idempotent on UUIDv7 ids (ADR-0011).
- **Logging/observability**: structured logs; `GET /healthz` (liveness) and `/readyz` (DB + Redis); queue depth visible to the operator.
- **Config/environments**: environment variables via Compose — DB/Redis URLs, Better Auth secret, optional S3 keys, tile URL.
- **Security boundaries**: internet → API (TLS terminated by the operator's reverse proxy), API → Postgres/Redis internal only; authn via Better Auth, authz via project Membership; sensitive coordinates obfuscated before leaving the server (INV-011).

## Deployment view

- **Local dev**: `docker compose up` (Postgres/PostGIS, Redis, server, worker) plus the Flutter app on a device/emulator.
- **Production (self-hosted)**: one Linux host running the Compose stack from GHCR images, with persistent volumes for the database and media and an operator-provided reverse proxy for TLS; optional MinIO for S3.

```mermaid
flowchart TB
  subgraph Host
    Proxy[Reverse proxy / TLS] --> API
    API --- PG[(postgres volume)]
    API --- Media[(media volume)]
    API --- Redis[(redis)]
    Worker[worker] --- Redis
    Worker --- PG
  end
  App[mobile app] --> Proxy
  Research[Researcher] --> Proxy
```

## Operational view

- **Observability**: health endpoints and logs only; no external APM at v1.
- **Incident handling**: restart the stack; failed export jobs are retried from Redis.
- **Backup/recovery**: documented `pg_dump`/`pg_restore` and a media-volume snapshot, with a restore procedure in the operator docs.
- **Capacity**: sized for a project-scale single host; revisit at media or visit-volume thresholds.

## Key decisions

- Modular monolith NestJS plus a BullMQ worker for Exports (ADR-0008).
- Protocol format shared through `packages/protocol` with Dart codegen (ADR-0009).
- Invariants: DB constraints where cheap, application rules for the rest, minimal triggers (ADR-0010).
- Versioned additive `/api/v1`, idempotent UUIDv7 submission, append-only corrections (ADR-0011).
- Evidence uploaded through the API, presigned S3 when configured (ADR-0012).
- Hosting via Docker Compose + GHCR (ADR-0006); storage volume by default with optional S3 (ADR-0007).

## Open questions

- Whether a new Project has validation enabled or disabled by default (the setting itself is designed; the default is not).
- Person identity options to expose at sign-in (email/password only, or also OAuth).
- Export artifact retention and where downloads live (volume vs streamed).
- Self-hosted tile server threshold under the OSM usage policy.

## External references

- Darwin Core (Event, Occurrence, `occurrenceStatus`) and the Humboldt extension.
- `docs/adr/` for the full reasoning behind each pinned decision.
