# Brief: collaborative field app for detection/non-detection surveys

Input for `/init`. Every interview drafts from this and asks only what it
leaves open. Status tags: **[decided]** the owner has said so; **[proposed]**
recommended in discussion, not yet confirmed; **[open]** undecided.

## Product

- A mobile app for ecologists to run species detection/non-detection
  (presence/absence) surveys under a shared protocol, for **any taxon**,
  plants and animals alike. **[decided]**
- One person creates a project and defines the protocol; the others join and
  collect data following it. **[decided]**
- Primary users: trained researchers and students. A student doing a thesis
  must be able to use it alone to organize, collect, and export thesis data.
  A one-member project must work without collaborative friction. **[decided]**
- Data must be publishable and analysis-ready: every non-detection traceable
  to how the species was searched for. **[decided]**
- Measurements can come from phone sensors or be entered from field
  instruments. **[decided]**
- Owner: one developer, solo, repo on GitHub, docs and code in English.
  **[decided]**

## Why this method, and why it is harder than it looks

Detection/non-detection is the standard basis of occupancy models (MacKenzie
et al. 2002; R package `unmarked`) and of distribution atlases. A
non-detection is only data when the search is recorded: which taxa were
searched for, with what effort, how many times the site was visited in the
same season, and by whom. Repeat visits are what separate "absent" from
"present but missed" (detection probability). The product's value is making
that rigor the default in the field. **[proposed]**

## Current landscape

- **eBird**, **Ornitho / NaturaList**: complete checklists with effort, birds
  (and some other groups on Ornitho). Citizen-science oriented; sites and
  repeat-visit designs are not defined by a project coordinator.
- **iNaturalist**: opportunistic presence-only records.
- **Epicollect5, KoboToolbox/ODK, Survey123**: generic collaborative forms; a
  researcher must hand-build effort, target lists, and repeat-visit logic,
  and nothing enforces them.
- **Vegapp, TurbovegSD**: vegetation relevés, Android, single device.
- **Gap this product targets** [proposed]: project-defined sites and survey
  periods, protocol-enforced effort and target lists, any taxon, iOS and
  Android, offline with a self-hostable server, exports ready for occupancy
  analysis and GBIF. Honest caveat: presence/absence alone is the most
  crowded part of the market; the rigor above is the whole differentiator
  and must not be simplified away.

## Scope

**Now (MVP)** [proposed]
1. Project and protocol: taxonomic scope; target list, or complete-list mode
   within a declared taxonomic scope; allowed detection methods; required
   effort fields; survey periods; site and visit covariates; taxonomic
   reference and its version.
2. Sites: predefined by the creator (point, line, or polygon) and created in
   the field, with their origin recorded.
3. Roles: creator, collector, validator.
4. Offline visit: effort timer, a detected / not-detected record for every
   target taxon, detection method, optional count, evidence (photo, audio
   recording), opportunistic extra taxa, uncertain determinations with a
   specimen code, covariates from phone sensors or instruments with
   provenance.
5. Submit and sync.
6. Exports: detection-history matrix (sites × visits, per taxon) with site
   and visit covariate tables for occupancy analysis; Darwin Core Event +
   Occurrence with `occurrenceStatus` present/absent and effort terms from
   the Humboldt extension; CSV; GeoPackage.
7. Methods paragraph generated from the protocol.
8. Coordinate obfuscation for sensitive taxa in exports and shared views.

**Next**: Braun-Blanquet vegetation relevé as a second method on the same
core (plots, layers, cover-abundance); counts with distance bands (point
counts, distance sampling); transect GPS tracks as effort.

**Later**: camera-trap deployments, acoustic recorders, automatic species
identification (licences of available models to be checked), AR measurements,
systematic phone-sensor vs instrument calibration.

**Out of scope**: abundance estimation beyond optional counts; soil chemistry
logic (manual covariate entry only); species identification by image.

## Domain (input for /model)

**Core** [proposed]: a **Visit** is one sampling event at one **Site** within
one **Survey period**, under one **Protocol version**, with recorded
**Sampling effort**. It produces one **Detection** per target taxon (detected
or not detected) plus optional opportunistic detections. Visits to the same
site within the same survey period are its repeat visits. Future methods
(relevé, point count) are other kinds of visit on the same core.

**Candidate concepts**: Project, Membership (role), Protocol and Protocol
version, Survey period, Site (origin: planned or field; geometry), Visit,
Sampling effort, Target list, Detection (taxon, detected yes/no, detection
method, count, evidence), Detection method, Determination (taxon, qualifier
cf./aff./sp., specimen code, determiner, date), Taxonomic reference
(versioned), Covariate (site-level or visit-level), Measurement (value, unit,
provenance), Provenance (method: phone sensor / field instrument / visual
estimate; device model and sensor, or instrument make and model; calibration
state; uncertainty; observer; time), Evidence (photo, audio), Correction.

**Candidate invariants** [proposed]
- A submitted visit is never edited; every later change is a correction with
  author, time, and reason. (both)
- A visit cannot be submitted until every target taxon has a detection
  record; "not recorded" and "not detected" are distinct states and only the
  second is data. (both)
- An opportunistic detection outside the target list is presence-only and
  never implies a non-detection anywhere. (both)
- A complete-list visit declares its taxonomic scope; only taxa within that
  scope and not recorded count as non-detections. (both)
- A visit records the sampling effort fields its protocol version requires:
  start, duration, observers, detection methods. (both)
- A visit belongs to exactly one site, one survey period, and one protocol
  version. (both)
- A protocol version referenced by any visit is immutable; changes create a
  new version. (server)
- Taxon names resolve against the taxonomic reference version the project
  pins; that version is stored with the data. (both)
- A determination is never overwritten; a revised one links to the one it
  replaces. (both)
- Every measurement carries its provenance; a value without method is
  invalid. (both)
- Coordinates of sensitive taxa never leave the server unobfuscated, except
  to roles the project allows. (server)

**Visit lifecycle** [proposed]: in progress (on the device, effort timer
running) → ended → submitted (immutable) → optionally validated; corrections
are events on a submitted visit.

**External vocabularies**: Darwin Core (Event, Occurrence,
`occurrenceStatus`), the Humboldt extension for effort and scope; taxonomic
references per group (for Italy: the vascular flora checklist; bird and
other fauna lists **[open]**), each with its version recorded per project.
"Plot" is reserved for the vegetation relevé in Next and is not a synonym of
Site.

**Glossary seeds** [proposed]
| Term | Code | Avoid |
|---|---|---|
| Site | `Site` | station, spot |
| Survey period | `SurveyPeriod` | season, campaign |
| Visit | `Visit` | outing, trip, session |
| Sampling effort | `SamplingEffort` | search effort |
| Target list | `TargetList` | watch list |
| Detection | `Detection` | sighting, observation |
| Non-detection | `-` (a Detection with `detected = false`) | absence |
| Detection method | `DetectionMethod` | technique |
| Determination | `Determination` | identification |
| Taxonomic reference | `TaxonomicReference` | species list, taxonomy |
| Measurement | `Measurement` | reading |
| Protocol | `Protocol` | template |

Checked with `glossary.sh lint`. Deliberately not avoided because they would
flag framework code everywhere: "form" (Flutter `Form`), "location"
(location services), "record" (Dart records). "Survey" cannot be avoided
while "Survey period" is a term.

Why "absence" is avoided: in the field the observed fact is a non-detection;
absence is what an occupancy model infers from it. Keeping the words apart
keeps the data honest.

## Stack (input for /discover)

- Mobile: not React Native **[decided]**; Flutter **[proposed]** over native
  ×2 (one developer) and Kotlin Multiplatform (younger iOS ecosystem).
  Sensors via `sensors_plus` (accelerometer, magnetometer, barometer); many
  low-end Android phones have no barometer, so every sensor-backed field
  falls back to manual entry. Audio recording for evidence.
- Backend self-hostable by a non-devops person **[decided]**: docker-compose
  with API + Postgres/PostGIS, media on a volume, optional S3 **[proposed]**.
- API: NestJS **[proposed]**, REST.
- ORM: Prisma suggested by the owner; Drizzle or Kysely proposed for PostGIS
  types; Prisma acceptable with isolated raw spatial queries **[open]**.
- Sync **[proposed]**: no sync engine. In-progress visits live only on the
  device; submitted visits are immutable server-side; corrections are
  append-only events; client-generated UUIDv7 IDs; an outbox uploads
  submissions; the client pulls project config, protocol, sites, and target
  lists since a version. PowerSync was considered; proposed against for
  self-hosting weight and its source-available (non-OSI) licence.

## Architecture notes (input for /architect)

**Compatibility surfaces** [proposed]
- Sync API: a self-hosted server may be one release behind the app.
- Client SQLite schema: forward-only migrations, tested.
- Server schema: forward-only migrations.
- Protocol definition format: shared by app and server, versioned.
- Export formats (detection-history matrix, Darwin Core, CSV, GeoPackage):
  golden fixtures.

**Release artifacts** [proposed]: Android app bundle (Play), iOS build
(TestFlight/App Store), server container image (GitHub Container Registry),
docker-compose file.

## UX (input for /ux)

Context of use: outdoors in alpine, forest, and wetland terrain; direct sun,
rain, cold, gloves; binoculars in one hand; eyes on the animal, not the
screen; no connectivity for whole days; long sessions on one battery;
low-end Android phones common among students.

Critical tasks to budget: start a visit at a site (starts the effort timer);
mark each target taxon detected or not detected; add an opportunistic taxon
by abbreviation search; attach an audio or photo record as evidence; record
visit covariates (weather, wind, temperature); end and submit. Reference for
budgets: the paper field sheet it replaces.

Key UX consequence of the domain: "not yet recorded" must look unmistakably
different from "not detected", and submission must be impossible while any
target taxon is unrecorded.

States to design: offline, syncing, sync failed, effort timer running in
background, missing sensor, sensor not calibrated, GPS accuracy poor, low
battery, storage full (audio).

## Risks

- A crowded space for presence data; mitigated only by the protocol rigor
  and analysis-ready exports above.
- Detection data quality depends on observers following the protocol;
  mitigated by enforced effort fields, target lists, and observer identity.
- Phone-sensor accuracy varies by model; mitigated by provenance and
  uncertainty on every value.
- Taxonomic references for fauna: which lists, their licences and update
  cadence **[open]**.
- GDPR: collectors' locations and tracks are personal data. Sensitive-species
  locations are a conservation risk if leaked.
