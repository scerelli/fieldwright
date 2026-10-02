# ADR-0016: First-run Example Project

Status: Accepted
Date: 2026-10-02
Doc: ARCHITECTURE.md

## Decision
On first launch the client seeds an Example Project — a real local Project flagged as an example — that is browsable and demonstrates the journey. It is never linked or exported (INV-017), and it is the only Project that may be hard-deleted; it is re-seeded while the person has no non-example Project. The example is client-only and never syncs. A Project also gains an optional `description`, which does sync to the server and is shown on the Project card.

## Context
A newcomer had no working reference for the field journey, and `/init` deferred `DESIGN.md`, so onboarding had nowhere to land (PRODUCT.md Now item 10; UX-018). The Project aggregate already holds everything a demonstration needs (Protocol version, Survey periods, Sites).

## Alternatives considered
- An app-owned demo not persisted as a Project — rejected: it duplicates the Project rendering and drifts from the real screens.
- Hard-coded screenshots or a scripted tour — rejected: it does not exercise the real journey.
- A read-only clone of the Project type — rejected: one representation is simpler, and INV-017 already constrains the exclusions.

## Consequences
Locks in: the client `projects` module seeds and owns the Example Project, its cards and the empty-state prompt; the client `projects` store gains `description` and an `example` flag; the server `project` table gains a nullable `description` (server-schema migration), which also travels through `/projects` and the config pull so joined members see it; a small `help` module owns the in-app manual (UX-023). The `example` flag is client-only — an example never reaches the server. To revisit, supersede this ADR and coordinate the store, server and onboarding changes.
