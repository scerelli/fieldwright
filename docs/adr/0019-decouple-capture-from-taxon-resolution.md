# ADR-0019: Decouple capture from taxon resolution; provisional taxa are local-only

Status: Superseded by ADR-0021
Date: 2026-10-04
Doc: ARCHITECTURE.md

## Decision

A Visit may be captured with only a Site, and its Detections may hold provisional (unresolved) taxa. Taxon resolution runs client-side against the Project's cached pinned reference and is enforced at submission: the server rejects a submitted Visit whose Project has no pinned reference or whose Detections do not resolve. Provisional taxa never reach the server.

## Context

The earlier model required a Project to pin a Taxonomic reference and Protocol version before a Visit could be started. A creator (often a student) may not know which reference applies at the moment they are in the field, so blocking Visit start strands real field work. That contradicts UX-007 and UX-028 (a hard gate blocks only submission/export, never capture) and the v1 goal of a first recorded Visit in the first session. Simply allowing free-text taxa without a gate would pollute the data, so resolution must be enforced — at submission, where rigor actually matters.

## Alternatives considered

- Block Visit start until a reference and Protocol version exist — rejected: strands field work and contradicts UX-007/UX-028.
- Allow free-text taxa with no resolution gate — rejected: unreconciled names silently corrupt the detection-history matrix and exports.
- Resolve server-side on submit — rejected: the client cannot render a pick-list offline (UX-005) and users would learn of failures only after submitting.

## Consequences

Capture needs only a Site; `INV-006` and `INV-008` are restated at submission time. The client store derives a Detection's provisional status (no pin, or the stored taxon key does not resolve) and the wire contract carries only resolved Detections. A new submission guard in the server `visits` ingest rejects an unresolvable Visit. Revisit if references become always available or the capture/submission split is restructured.
