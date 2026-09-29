# ADR-0002: Client local store: drift on SQLite

Status: Accepted
Date: 2026-09-29
Doc: TECH_STACK.md

## Decision
The Flutter client persists offline data in SQLite through drift 2.35, with
forward-only migrations.

## Context
A Visit, including evidence, is captured fully offline for whole days and
lives only on the device until submitted. The brief fixes a client SQLite
schema with forward-only, tested migrations.

## Alternatives considered
- sqflite — raw SQL, no compile-time query safety and hand-rolled migrations.
- sqlite3 FFI with a hand-written layer — maximum control, most code to own.
- Hive / Isar — not SQL; weaker fit for relational visit/detection data.

## Consequences
Locks the client to drift's code generation (build_runner). Revisit if drift's
maintenance or performance proves inadequate.
