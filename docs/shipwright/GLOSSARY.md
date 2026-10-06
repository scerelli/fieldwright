# Glossary

The ubiquitous language for IBIS. Every field is read by `glossary.sh`; entries
are ordered alphabetically and each identifier belongs to exactly one term.

## Analysis spec
- code: `AnalysisSpec`
- definition: A declarative, versioned definition of an analysis a Project may run: the question it answers, the data shape it requires, the target tool, and the bundle it emits. It is data, not code; selecting one never modifies captured data and never runs author-supplied code.
- concept: DOMAIN.md › Analysis spec (value)
- source: unmarked (Fiske & Chandler 2011); MacKenzie et al. occupancy modelling
- avoid: analysis kind

## Analysis-ready
- code: `analysisReady`
- definition: The derived state of a submitted Visit that has exactly one Survey period and one Protocol version, its Project's pinned Taxonomic reference, every target taxon recorded, and no provisional Detection. Only an Analysis-ready Visit enters an export or the authoritative dataset; one that is not is provisional.
- concept: DOMAIN.md › Visit (aggregate)
- avoid: finalized

## Correction
- code: `Correction`
- definition: An append-only change to a submitted Visit, carrying its author, time, and reason. A Correction never mutates the submitted record; it is the only way a submitted Visit changes in effect.
- concept: DOMAIN.md › Correction (entity)
- avoid: edit, amendment
- note: resolving a provisional Visit's taxa is a Correction.

## Covariate
- code: `Covariate`
- definition: An environmental or contextual variable recorded with a Site or a Visit. Its definition (name, type, unit) lives in a Protocol version; its value lives on the Site or Visit with its Provenance.
- concept: DOMAIN.md › Covariate
- avoid: variable

## Detection
- code: `Detection`
- definition: The record that one taxon was detected, or searched for and not detected, in one Visit. Its taxon is resolved against the pinned Taxonomic reference, or held as a provisional taxon until it can be. A non-detection is a Detection with `detected = false`.
- concept: DOMAIN.md › Detection (entity)
- source: Darwin Core Occurrence
- avoid: sighting, observation

## Detection method
- code: `DetectionMethod`
- definition: The way a Detection was made, chosen from those the Protocol version allows.
- concept: DOMAIN.md › Detection (entity)
- source: Humboldt extension
- avoid: technique

## Determination
- code: `Determination`
- definition: A taxon assignment for a Detection, with its qualifier, specimen code, determiner, and date. A revision is a new Determination that links to the one it replaces; none is overwritten.
- concept: DOMAIN.md › Determination (entity)
- avoid: identification

## Evidence
- code: `Evidence`
- definition: A photo or audio recording attached to a Visit as proof of a Detection. Immutable once attached.
- concept: DOMAIN.md › Evidence (entity)
- avoid: attachment

## Measurement
- code: `Measurement`
- definition: A value with a unit and its Provenance. A value without a method is invalid.
- concept: DOMAIN.md › Measurement (value)
- avoid: reading

## Membership
- code: `Membership`
- definition: The link between a person and a Project, carrying the single role they hold there (creator, collector, or validator). A person has at most one Membership per project.
- concept: DOMAIN.md › Membership (entity)
- avoid: participant

## Non-detection
- code: `-`
- definition: A Detection with `detected = false`: the taxon was searched for, under recorded effort, and not found. It has no separate identifier — it is a Detection.
- concept: DOMAIN.md › Detection (entity)
- avoid: absence
- note: absence is an inference an occupancy model draws from non-detections, never a field fact. A non-detection also requires a resolved target list, so a Visit whose taxa are provisional records opportunistic presence only. A target taxon with no Detection is "not recorded" — a distinct state, never counted as a non-detection (INV-019).

## Project
- code: `Project`
- definition: The container a creator sets up: its protocol, members, survey periods, sites, settings, optional objective, and the Analysis spec it runs. Sites, visits, and exports are scoped to one Project.
- concept: DOMAIN.md › Project (aggregate)
- avoid: study
- note: its pinned Taxonomic reference may be chosen after the Project is created; until then Detections hold provisional taxa and a submitted Visit is provisional, held out of every export.

## Protocol
- code: `Protocol`
- definition: The rules a project's surveys follow: taxonomic scope, target list or complete-list mode, allowed detection methods, and required effort and covariate fields. A Protocol is versioned.
- concept: DOMAIN.md › Protocol version (entity)
- avoid: template

## Protocol version
- code: `ProtocolVersion`
- definition: An immutable snapshot of a Protocol, identified by a monotonic version number. A version freezes the first time a Visit references it; a change creates a new version.
- concept: DOMAIN.md › Protocol version (entity)
- avoid: protocol revision

## Provenance
- code: `Provenance`
- definition: How a Measurement was obtained: method (phone sensor, field instrument, or visual estimate), device or instrument model, calibration state, uncertainty, observer, and time. Every Measurement carries it.
- concept: DOMAIN.md › Provenance (value)
- avoid: metadata

## Provisional taxon
- code: `ProvisionalTaxon`
- definition: A taxon recorded on a Detection before the Project's pinned Taxonomic reference is available — a name or abbreviation not yet resolved to a reference taxon. It is presence-only and is resolved before the Visit is analysis-ready.
- concept: DOMAIN.md › Provisional taxon (value)
- source: Darwin Core Occurrence (`scientificName` with no resolved `taxonID`)
- avoid: draft species, free text

## Sampling effort
- code: `SamplingEffort`
- definition: The fields a Visit records about how the search was carried out: start, duration, observers, and detection methods. Required by the Protocol version.
- concept: DOMAIN.md › Visit (aggregate)
- source: Humboldt extension
- avoid: search effort

## Site
- code: `Site`
- definition: A place a survey happens, with a geometry (point, line, or polygon) and an origin (planned or field-created). A Site belongs to one Project.
- concept: DOMAIN.md › Site (aggregate)
- avoid: station, spot

## Survey period
- code: `SurveyPeriod`
- definition: A named date range in which Visits are expected. Visits to the same Site within one Survey period are its repeat visits, and the period is the closure window for a closed occupancy analysis.
- concept: DOMAIN.md › Survey period (entity)
- avoid: season, campaign

## Target list
- code: `TargetList`
- definition: The taxa a Visit must record a Detection for, defined in a Protocol version. Its absence means complete-list mode, where the declared taxonomic scope defines them.
- concept: DOMAIN.md › Protocol version (entity)
- avoid: watch list

## Taxonomic reference
- code: `TaxonomicReference`
- definition: The versioned external checklist taxon names resolve against. A Project pins one version — a reference id and version pair — recorded on a Visit whenever the Project has one; a resolved Detection requires it. Until one is pinned, Detections hold provisional taxa and a submitted Visit is provisional, held out of every export.
- concept: DOMAIN.md › Project (aggregate)
- avoid: species list, taxonomy

## Validation
- code: `Validation`
- definition: A validator's acceptance or rejection of a submitted Visit, available only when the Project enables it. It records validator and time and never deletes data.
- concept: DOMAIN.md › Visit (aggregate)
- avoid: review

## Visit
- code: `Visit`
- definition: One sampling event at one Site, captured offline, submitted immutably, and corrected via Corrections. It belongs to one Survey period under one Protocol version once it is analysis-ready.
- concept: DOMAIN.md › Visit (aggregate)
- source: Darwin Core Event
- avoid: outing, trip, session
- note: a Visit may be captured, ended and submitted with only a Site and provisional taxa; it becomes analysis-ready — and fit for an export — only with its Protocol version, Survey period, the Project's pinned reference, every target recorded, and every taxon resolved.
