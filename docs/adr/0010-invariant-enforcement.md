# ADR-0010: Invariant enforcement — database constraints plus application rules

Status: Accepted
Date: 2026-09-29
Doc: ARCHITECTURE.md

## Decision
Cheap structural invariants are Postgres constraints (foreign keys,
uniqueness, NOT NULL, enums, geometry checks); rule-heavy invariants run in
server application code inside a transaction; triggers are minimal.

## Context
DOMAIN.md defines 13 INV-* rules, several of them cross-record (target-list
completeness, submitted immutability, append-only corrections). The top
quality attribute is offline reliability and data integrity.

## Alternatives considered
- Application code only — no database safety net against a bug or manual write.
- Heavy triggers for every invariant — strongest, but hard to evolve and debug, and awkward for payload-heavy rules.

## Consequences
Some invariants have two checkpoints (client and server, plus a constraint
where cheap); each INV-* records its enforcement locus. Revisit if writes
bypass the API.
