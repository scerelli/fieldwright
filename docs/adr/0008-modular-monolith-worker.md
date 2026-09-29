# ADR-0008: Modular monolith server with a BullMQ export worker

Status: Accepted
Date: 2026-09-29
Doc: ARCHITECTURE.md

## Decision
The server is a NestJS modular monolith that also runs as a BullMQ worker
process for Exports; Redis backs the queue.

## Context
Project exports (detection-history matrix, Darwin Core, GeoPackage) can be
heavy and must not block API requests. Self-hosting must stay simple for a
non-devops operator, but the owner chose a queue over synchronous exports.

## Alternatives considered
- No queue; exports in the request — risks request timeouts and blocks the API.
- Serverless functions — conflicts with the self-hostable docker-compose requirement.
- A separate export service repository/process — extra overhead for a solo developer.

## Consequences
Redis joins the Compose stack and the worker is a second container from the
same image; export jobs must be idempotent and retryable. Revisit if Redis
becomes an operational burden for non-devops self-hosters.
