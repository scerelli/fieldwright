# ADR-0009: Protocol format shared via a TypeScript package with Dart codegen

Status: Accepted
Date: 2026-09-29
Doc: ARCHITECTURE.md

## Decision
`packages/protocol` defines the versioned protocol document as TypeScript
types plus JSON Schema; the Dart client is generated from that schema.

## Context
App and server must agree exactly on the protocol definition format, but are
written in Dart and TypeScript. The client must validate and use protocol
config offline before it is first used.

## Alternatives considered
- Hand-maintained JSON Schema and fixtures on each side — drifts silently.
- Server-owned, client fetches and trusts it — no offline validation.
- Duplicate definitions per side — the classic two-sources-of-truth drift.

## Consequences
Adds `packages/protocol` and a codegen step to both toolchains; the format is
versioned and additive. Revisit if codegen across the two toolchains proves
brittle.
