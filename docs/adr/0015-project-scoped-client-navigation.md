# ADR-0015: Project-scoped client navigation

Status: Accepted
Date: 2026-10-02
Doc: ARCHITECTURE.md

## Decision
The app's top-level navigation is the Projects list, with Account reached from the app bar. A Project is the hub for its own Sites, Visits, Protocol version, Survey periods and Members; there is no global list of Sites or Visits. A single persistent shell indicator shows offline, unlinked, syncing and sync-failed state on every screen.

## Context
A Site and a Visit each belong to exactly one Project (INV-006, INV-012), and the core field journey is create a Project → start a Visit at its Site → capture. The shipped shell exposed Sites and Visits as top-level destinations alongside Projects, so a collector could not tell which Project a Site or Visit belonged to, and the journeys read as disjointed (UX-019, UX-020). The shell had been built with global tabs (#10, #92, #201); this reverses that model.

## Alternatives considered
- Global tabs with an "active project" filter — rejected: the project context is implicit and easy to lose, and it still allows cross-project lists.
- Fully global with Project as a tag — rejected: contradicts the domain, where every Site and Visit is Project-scoped.
- A dedicated "current visit" destination — rejected: a mostly-empty tab in exchange for one tap; a pinned banner covers resume (UX-021).

## Consequences
Locks in: the shell owns project-scoped routing; `sites` and `capture` are reached only inside a Project; Account moves to the app bar; the shell carries the system-state indicator (revised UX-008). The global-tab shell and its routes are reworked, superseding the outcomes of #10/#92/#201. To revisit, supersede this ADR and rework the shell and routes again.
