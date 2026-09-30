# DX entry points. `make dev` is the Turborepo-like TUI (mprocs); `make dev:one`
# runs the same stack in a single terminal.
SHELL := bash
EMULATOR_ID ?= Medium_Phone_API_36.0
API_PORT ?= 3000

.PHONY: dev dev:one infra migrate migrate-generate server worker android stop logs

## Turborepo-like dev TUI: api + mobile (+ db logs; worker starts on demand).
dev:
	@PORT=$$(./scripts/free-port.sh $(API_PORT)); \
	  echo "==> API port $$PORT — mprocs: arrows switch procs, r restarts, s starts worker"; \
	  API_PORT=$$PORT mprocs --config mprocs.yaml

## Single-terminal dev: infra -> migrations -> API watch -> flutter run.
dev:one:
	API_PORT=$(API_PORT) EMULATOR_ID=$(EMULATOR_ID) ./scripts/dev.sh

## Just the backing services (published on localhost for host-run API/worker).
infra:
	docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml up -d db redis

## Apply the server schema migrations to the dev database.
migrate:
	@bash -c 'set -euo pipefail; . ./scripts/dev-env.sh; dev_api_env pnpm --dir server run drizzle:migrate'

## Generate a new migration from the server schema.
migrate-generate:
	@bash -c 'set -euo pipefail; . ./scripts/dev-env.sh; dev_api_env pnpm --dir server run drizzle:generate'

## Run the API (infra -> migrations -> watch).
server:
	./scripts/dev-backend.sh

## Run the worker.
worker:
	./scripts/dev-worker.sh

## Flutter only (expects infra + API already running).
android:
	EMULATOR_ID=$(EMULATOR_ID) ./scripts/dev-android.sh

## Stop db + redis.
stop:
	docker compose -f infra/docker-compose.yml down

## Tail db + redis logs.
logs:
	docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml logs -f db redis
