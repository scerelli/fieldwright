# ADR-0014: Local-first Projects: client-assigned identity, linked on sign-up

Status: Accepted
Date: 2026-10-02
Doc: ARCHITECTURE.md

## Decision
A Project may be created with no account; its identity is a client-assigned UUIDv7, and that same identity is used server-side when the Project is linked on sign-up. The client store owns one local Project aggregate, and the server `POST /projects` accepts an optional client-supplied id (idempotent create-or-return).

## Context
Story #277 needs accountless creation and capture, then a link to a new account. `DOMAIN.md` (revised) assigns a Project's identity at creation — by the client when created offline — and never changes it (INV-015), and requires linking to create exactly one creator Membership (INV-016, INV-014). Today the server assigns the Project id and the client only caches pulled config, so no id exists before link.

## Alternatives considered
- Server-assigned id with a temporary local id remapped on link — rejected: remaps the id and every reference.
- A separate "local Project" entity — rejected: duplicates the aggregate and splits one rule across two owners.
- A new `POST /projects/link` endpoint — rejected: the existing `POST /projects` plus an optional id is additive and idempotent.

## Consequences
Locks in: the server accepts client-supplied Project ids (it must treat a repeat as idempotent, or reject a conflicting id), and the client local store is the single representation of a Project (locally created and joined). To revisit, supersede this ADR and coordinate a server + client migration.
