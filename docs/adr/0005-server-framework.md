# ADR-0005: Server framework: NestJS on TypeScript/Node

Status: Accepted
Date: 2026-09-29
Doc: TECH_STACK.md

## Decision
A NestJS 12 REST API on TypeScript 7 and Node 24 LTS.

## Context
One developer across client and server; the brief proposes NestJS REST and a
self-hostable Node image.

## Alternatives considered
- Hand-rolled Express/Fastify — less structure and conventions out of the box.
- A second-language backend (Laravel, Django, Go) — a second language for a solo developer.
- GraphQL — added complexity for a small, known client set.

## Consequences
The server is TypeScript/Node, sharing a toolchain with Drizzle and the
generated API types. Revisit only if a hard requirement appears that NestJS
cannot meet.
