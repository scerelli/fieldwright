# ADR-0021: Submit a Visit as it stands; enforce analysis-readiness at export

Status: Accepted
Date: 2026-10-06
Doc: ARCHITECTURE.md

## Decision

A Visit is captured, ended and submitted with only a Site. While it lacks a Protocol version, a Survey period, its Project's pinned Taxonomic reference, a recorded target, or a resolved taxon, it is **provisional**: the server stores it as it stands (normalized nullable columns; each Detection carries a resolved `taxon` or an explicit `provisionalName`), derives analysis-readiness from stored state plus applied Corrections, and excludes non-analysis-ready Visits from every export. Resolution of a synced Visit is an append-only Correction. Submission never depends on analysis-readiness.

## Context

ADR-0019 enforced resolution at submission: the server rejected a Visit whose Project had no pinned reference or whose Detections did not resolve, and provisional taxa stayed local. In the field a student may not know which reference or Protocol version applies, so blocking submission strands real work and pushes a desk decision onto the field moment. The product's rigor is not "reject at submit" — it is that a non-detection is only data when the search is recorded, and that nothing unresolved silently enters the analysis. That guarantee is better placed at export, where unresolved data actually corrupts the detection-history matrix, than at submission, where it only blocks the collector.

## Alternatives considered

- **Keep ADR-0019 (reject at submission)** — rejected: blocks the field user on decisions they cannot make there, and the rigor it protects is enforceable at export instead.
- **Upload provisional, unflagged** — rejected: unresolved names would sit on the server with no marker and leak into exports; the explicit resolved-vs-provisional tag is what keeps corruption from being silent.
- **Hold unresolved Visits on the device until resolved** — rejected: leaves finished field data device-only and exposed to device loss; uploading provisional (then resolving by Correction) is safer.
- **Opaque jsonb for a provisional Visit until resolved** — rejected: two shapes and a materialization step to design and test; normalized nullable columns keep one shape for every query and export.
- **Server re-verifies each resolved taxon against the pinned artifact now** — rejected for v1: the same client-resolution trust ADR-0019 already relied on; keeping the tag explicit is enough, artifact cross-check is later hardening.

## Consequences

The server schema gains nullable `visit` resolution columns and a `detection.provisional_name`, with a forward-only migration; the sync contract is additive (a Detection carries `taxon` or `provisionalName`). The `visits` module derives analysis-readiness and `exports` filters on it. Resolution is a Correction, so immutability (INV-001) holds. Revisit if references become always available, if the export gate proves insufficient against client mis-tagging, or if the capture/submission split is restructured.
