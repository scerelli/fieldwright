# ADR-0011: Versioned, additive sync API with idempotent submission

Status: Accepted
Date: 2026-09-29
Doc: ARCHITECTURE.md

## Decision
The sync API is REST under `/api/v1`, additive-only with unknown fields
ignored; submissions are idempotent on client-generated UUIDv7 ids; submitted
Visits are immutable and change only through append-only Corrections.

## Context
A self-hosted server may be one release behind the app, so both sides must
tolerate skew. Devices are offline for days and may retry or duplicate a
submission. Submitted data must be auditable (PRODUCT.md, DOMAIN.md).

## Alternatives considered
- Unversioned API — no room to evolve under skew.
- Last-write-wins updates — destroys the audit trail.
- Server-assigned ids — force a round-trip before a Visit can be captured offline.

## Consequences
Both client and server must ignore unknown fields and never assume a peer's
version; retries are safe by construction. Revisit only if a breaking change
is unavoidable, then add `/api/v2` rather than mutating v1.
