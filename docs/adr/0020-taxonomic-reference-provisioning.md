# ADR-0020: Taxonomic reference provisioning — operator-supplied versioned artifacts, pulled and cached

Status: Accepted
Date: 2026-10-04
Doc: ARCHITECTURE.md

## Decision

Versioned Taxonomic-reference artifacts are operator-supplied files placed on a server volume; the API serves each `id`+`version` immutably, and the client pulls the pinned version and caches it in its local store for offline resolution. The app ships a small built-in catalogue (id, label, taxon group, latest version) used to suggest a per-group default at Project creation.

## Context

ADR-0019 makes the client resolve taxa offline and offer a pick-list, so the client must hold the pinned reference's data. External checklists are large, versioned, and variously licensed (the Italy vascular-flora list is named; fauna lists are open). The self-hosted, non-devops deployment (ADR-0006) must not depend on a third-party service or on server internet availability at capture time.

## Alternatives considered

- Bundle checklists in the app — rejected: a large checklist bloats the app and every reference update needs an app release.
- Client fetches the upstream checklist directly — rejected: needs network and licensing/CORS handling, and breaks the self-hosted, offline-first model.
- Bundle checklists in the server image — rejected: the project would have to license and ship the data and cut a release per checklist.

## Consequences

A new server module (`taxonomic-references`) and read surface serve artifacts from a volume; a new versioned, additive compatibility surface (golden-fixture proof) is declared between it and the client's cache. The operator gains a documented import step (like backup/restore). The client gains cache tables and a resolution service. Catalogue changes require an app release. Revisit if a shared reference registry or server-side upstream fetching becomes desirable.
