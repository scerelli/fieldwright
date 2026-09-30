# DX entry points. `make dev` is the one you usually want.
SHELL := bash
COMPOSE := docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml
DB_URL ?= postgres://postgres:postgres@localhost:55432/ibis
REDIS_URL ?= redis://localhost:56379
EMULATOR_ID ?= Medium_Phone_API_36.0
API_PORT ?= 3000

.PHONY: dev infra migrate migrate-generate server worker android stop logs

## Everything: db + redis, migrations, API watch, Flutter on the emulator.
dev:
	EMULATOR_ID=$(EMULATOR_ID) API_PORT=$(API_PORT) ./scripts/dev.sh

## Just the backing services (published on localhost for host-run API/worker).
infra:
	$(COMPOSE) up -d db redis

## Apply the server schema migrations to the dev database.
migrate:
	DATABASE_URL=$(DB_URL) pnpm --dir server run drizzle:migrate

## Generate a new migration from the server schema.
migrate-generate:
	DATABASE_URL=$(DB_URL) pnpm --dir server run drizzle:generate

## Run the API on the host with hot reload.
server:
	DATABASE_URL=$(DB_URL) REDIS_URL=$(REDIS_URL) API_PORT=$(API_PORT) pnpm --dir server run start:dev

## Run the worker on the host.
worker:
	DATABASE_URL=$(DB_URL) REDIS_URL=$(REDIS_URL) pnpm --dir server run start:worker

## Flutter only (expects `make infra` + `make server` already running).
android:
	EMULATOR_ID=$(EMULATOR_ID) API_PORT=$(API_PORT) ./scripts/dev-android.sh

## Stop db + redis.
stop:
	docker compose -f infra/docker-compose.yml down

## Tail db + redis logs.
logs:
	$(COMPOSE) logs -f db redis
