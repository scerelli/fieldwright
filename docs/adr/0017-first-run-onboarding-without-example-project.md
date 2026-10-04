# ADR-0017: First-run onboarding without a seeded Example Project

Status: Accepted
Date: 2026-10-04
Doc: ARCHITECTURE.md

## Decision
On first launch with no Project, the client shows an empty Projects list with a create action and a link into the in-app manual instead of seeding an Example Project. Creating a Project is a guided form with inline validation and explanatory helper text on the non-obvious fields. The client no longer marks, seeds, links, exports, or re-seeds an example Project; the `projects.example` flag, INV-017, and the Example Project term are removed. The optional synced Project `description` and the `help` module's in-app manual (UX-023) are retained unchanged.

## Context
ADR-0016 seeded a browsable Example Project to give a newcomer a working reference for the field journey. In practice that carried a whole parallel lifecycle — an example flag, exclusion from linking and export (INV-017), and delete-and-re-seed rules — for onboarding value that a clearer empty state and a self-explanatory create form can carry more cheaply. The product direction is to simplify first-run onboarding to: empty state → guided create form → manual.

## Alternatives considered
- Keep the Example Project and also improve the empty state — rejected: duplicates the onboarding job and keeps the parallel lifecycle.
- Keep the example but drop only the re-seed rule — rejected: still leaves the flag and the link/export exclusions with no clear owner.
- A read-only demo not persisted as a Project — rejected in ADR-0016 for duplication and drift from the real screens; still applies.

## Consequences
Locks in: the `projects` client module owns no example seed; the `projects` store loses the `example` column (forward-only migration); the linking and export paths no longer special-case examples; the Project lifecycle stays `active → archived` with no client hard-delete in v1. Retained from ADR-0016: the nullable synced `description` (server `project.description`, `/projects`, config pull, and the Project card) and the `help` module manual. To revisit, supersede this ADR and coordinate the store and onboarding changes.
