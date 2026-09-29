# Product: IBIS — Integrated Biodiversity Inventory Survey

## Vision & problem statement

IBIS is a mobile app for ecologists to run species detection/non-detection surveys under a protocol defined once by a project's creator, for any taxon, plants and animals alike. One person creates a project and defines the protocol — taxonomic scope, target list or complete-list mode, allowed detection methods, required effort fields, survey periods, site and visit covariates, and the taxonomic-reference version. Everyone else joins and collects data following it. Visits to the same site within one survey period are its repeat visits, which is what separates "absent" from "present but missed".

The pain it targets: existing tools let people record observations, or let a coordinator manage a project, but rarely both with the rigor occupancy analysis demands. A non-detection is only data when the search itself is recorded — which taxa were searched for, with what effort, how many times a site was revisited in a season, and by whom. Generic form tools (Epicollect5, KoboToolbox/ODK, Survey123) leave the researcher to hand-build that logic and enforce none of it; citizen-science apps (eBird, iNaturalist) optimise for presence records, not project-defined repeat-visit designs.

Elevator pitch: IBIS makes the rigor occupancy models require the default in the field. Every non-detection is traceable to how the species was searched for; it works offline for whole days on a low-end phone, is self-hostable by a non-devops person, and exports detection-history matrices and Darwin Core ready for occupancy analysis and publication.

## Current landscape & alternatives

- **eBird, Ornitho / NaturaList** — complete checklists with effort, birds (and some other groups on Ornitho). Citizen-science oriented; sites and repeat-visit designs are not defined by a project coordinator.
- **iNaturalist** — opportunistic, presence-only records; no protocol or effort.
- **Epicollect5, KoboToolbox / ODK, Survey123** — generic collaborative forms; the researcher hand-builds effort, target lists and repeat-visit logic, and nothing enforces them.
- **Vegapp, TurbovegSD** — vegetation relevés, Android, single device.
- **Gap IBIS targets** — project-defined sites and survey periods, protocol-enforced effort and target lists, any taxon, iOS and Android, offline with a self-hostable server, and exports ready for occupancy analysis and GBIF. Honest caveat: presence/absence alone is the most crowded part of the market; the protocol rigor above is the whole differentiator and must not be simplified away.

## Goals & success metrics

**v1**

- A solo student plans, collects, submits and exports a real thesis survey end-to-end on one device, without help.
- A real multi-collector project runs with at least two collectors, three sites, and three repeat visits per site.
- Exports load cleanly into an occupancy model (e.g. `unmarked` in R) and are GBIF-ready (Darwin Core Event + Occurrence with `occurrenceStatus` and Humboldt effort terms).

**Beyond v1**

- Second field methods (Braun-Blanquet relevé, distance-band counts, transects) run on the same core.
- Camera-trap, acoustic and automatic-identification workflows feed the same detection model.
- Independent projects adopt IBIS, and at least one published dataset cites it.

## Target users & personas

**Primary — the survey ecologist.** A trained researcher or student running a detection/non-detection survey for a project, a thesis, or a distribution atlas. Context of use: outdoors in alpine, forest and wetland terrain; direct sun, rain, cold, gloves; binoculars in one hand and eyes on the animal, not the screen; no connectivity for whole days; often a low-end Android phone. Their job is to define (or follow) a protocol and come away with publishable detection data. Whether solo or coordinating a team, it is the same job differing only in team size — a one-member project must work without collaborative friction.

**Secondary — the collector.** A non-creator team member who follows someone else's protocol to capture data offline. Genuinely distinct because their journey is constrained data capture with no protocol design, and because their locations and observations raise GDPR obligations the creator's do not.

## User scenarios

- As a project creator, I want to define a protocol (taxonomic scope, target list, allowed detection methods, required effort fields, survey periods, covariates) so that my team collects comparable data.
- As a creator, I want to define sites (point, line or polygon) and survey periods so that repeat visits are structured, not ad hoc.
- As a collector, I want to start a visit at a site and have the effort timer run so that effort is recorded automatically.
- As a collector, I want to record detected or not detected for every target taxon so that non-detections become valid data.
- As a collector, I want to add opportunistic taxa, evidence (photo, audio), uncertain determinations with a specimen code, and covariate values with their provenance.
- As a collector, I want to submit and sync a completed visit when connectivity returns, without editing it afterwards.
- As a validator, I want to review submitted records and issue corrections so that errors are fixed without erasing history.
- As a researcher, I want exports ready for occupancy analysis and publication, with sensitive taxa obfuscated.

## Scope & roadmap

### Now — v1 / MVP

1. Project and protocol: taxonomic scope; target list, or complete-list mode within a declared taxonomic scope; allowed detection methods; required effort fields; survey periods; site and visit covariates; taxonomic reference and its version.
2. Sites: predefined by the creator (point, line or polygon) and created in the field, with their origin recorded.
3. Roles: creator, collector, validator.
4. Offline visit: effort timer, a detected / not-detected record for every target taxon, detection method, optional count, evidence (photo, audio recording), opportunistic extra taxa, uncertain determinations with a specimen code, covariates from phone sensors or instruments with provenance.
5. Submit and sync.
6. Exports: detection-history matrix (sites × visits, per taxon) with site and visit covariate tables for occupancy analysis; Darwin Core Event + Occurrence with `occurrenceStatus` present/absent and effort terms from the Humboldt extension; CSV; GeoPackage.
7. Methods paragraph generated from the protocol.
8. Coordinate obfuscation for sensitive taxa in exports and shared views.
9. Foundational Epic: app shell, navigation, and the design tokens `/design` will settle, wired into the component registry `/discover` pins — so `/decompose` mints it once instead of each feature Epic re-deriving the theme.

### Next

- Braun-Blanquet vegetation relevé as a second method on the same core (plots, layers, cover-abundance).
- Counts with distance bands (point counts, distance sampling).
- Transect GPS tracks as effort.

### Later

- Camera-trap deployments and acoustic recorders.
- Automatic species identification (licences of available models to be checked).
- AR measurements; systematic phone-sensor vs instrument calibration.

## Non-functional requirements

- **Offline-first**: a full visit, including evidence capture, must work with no connectivity for whole days.
- **Device floor**: run acceptably on low-end Android phones common among students; every sensor-backed field falls back to manual entry (many have no barometer).
- **Field conditions**: legible and operable in direct sun, rain, cold and gloves; long sessions on one battery; bounded local storage for audio evidence.
- **Security & privacy**: collectors' locations and tracks are personal data under GDPR; sensitive-species coordinates must never leave the server unobfuscated except to roles the project allows.
- **Deployability**: self-hostable by a non-devops person via docker-compose (API + Postgres/PostGIS, media on a volume, optional S3).
- **Scale & performance**: not yet known — see `/architect`.

## Out of scope

- Abundance estimation beyond optional counts.
- Soil-chemistry logic (manual covariate entry only).
- Species identification by image (automatic photo-based ID).

## Risks & mitigations

- **Crowded presence-data market** — mitigated only by the protocol rigor and analysis-ready exports; never simplify the rigor away.
- **Data quality depends on observers following the protocol** — mitigated by enforced effort fields, target lists, and observer identity.
- **Phone-sensor accuracy varies by model** — mitigated by provenance and uncertainty on every value.
- **Taxonomic references for fauna: which lists, their licences and update cadence** — decide before fauna projects ship; monitor until then.
- **GDPR and sensitive-species leakage** — mitigated by coordinate obfuscation and role-based access.

## Assumptions, dependencies & constraints

- Owner is one developer, solo; repo on GitHub; docs and code in English.
- Mobile: not React Native (decided); Flutter proposed over native ×2 and Kotlin Multiplatform.
- Backend: NestJS REST proposed, Postgres/PostGIS, docker-compose, media on a volume, optional S3; self-hostable by a non-devops person (decided).
- Sync: no sync engine — in-progress visits live only on the device; submitted visits are immutable server-side; corrections are append-only events; client-generated UUIDv7 IDs; an outbox uploads submissions; the client pulls project config, protocol, sites and target lists since a version.
- Taxonomic references are pinned per project with their version recorded; external vocabularies are Darwin Core (Event, Occurrence, `occurrenceStatus`) and the Humboldt extension.

## Milestones

| Milestone | Covers | Target |
|---|---|---|
| v1.0 — MVP | Now | — |
| v1.1 | Next | — |
| Backlog | Later | — |

## Scope size

Multi-month, solo, ongoing. Effort drivers: the offline visit/test loop on real Android hardware, the export golden fixtures (detection-history matrix, Darwin Core, GeoPackage), and the sync/positional-data surface.

## Open questions

- **ORM**: owner prefers Drizzle (or whatever works best with PostGIS and the chosen database) — ratify at `/discover`. Prisma with isolated raw spatial queries was the earlier alternative.
- **Fauna taxonomic references**: which lists, their licences and update cadence — decide before fauna projects ship (`/discover`, `/model`).
- **Taxonomic-reference granularity and versioning per group**: e.g. the Italy vascular-flora checklist vs fauna lists (`/model`).

## Appendix

- Product brief: `docs/brief.md`.
