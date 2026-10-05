# UX: IBIS — Integrated Biodiversity Inventory Survey

How the product has to work for a real person in a real place: gloves on, sun
on the screen, one hand holding binoculars, no signal, a cheap phone at 15%
battery. Visual decisions belong to `DESIGN.md`; this document is rules that
can fail, numbered so criteria can cite them.

## Context of use

- **Where**: outdoors in alpine, forest and wetland terrain. Direct sun, rain, cold, wind; gloves are common.
- **Posture**: frequently one-handed — the other hand holds binoculars or an instrument; eyes are on the animal, not the screen.
- **Connectivity**: none for whole days; the app is offline-first and delivery waits for a connection.
- **Sessions**: long field days on one battery; Visits last minutes to hours.
- **Devices**: the low end of what students and researchers actually carry — modest Android phones (many without a barometer) and iOS. Every sensor-backed field has a manual fallback.

## Users

Trained researchers and students. Domain-skilled (they know their taxa and
protocol) but not necessarily phone-skilled, and often interrupted mid-task.
They work either alone or as a collector following someone else's protocol. A
creator may start with no account at all and adopt one later, so nothing may
assume a person is signed in. A newcomer may have no Project yet — and a
student may not know which Taxonomic reference a Project should pin — so the
app onboards them with an empty state, a guided name-only Project creation
form, and an in-app manual, and never blocks capture or submission while a
reference is still being chosen.

## Critical tasks

| Task | Frequency | Budget | Rules |
|---|---|---|---|
| Learn the app from the in-app manual | once | manual ≤ 2 taps from the Projects list | UX-023 |
| Create a Project and configure it offline, with no account | once per project | ≤ 3 taps to create (name only), no sign-in wall; reference and settings configured afterward | UX-015, UX-024, UX-025, UX-026 |
| State the objective and choose an Analysis spec | once per project | ≤ 3 taps to select; requirements shown inline | UX-027, UX-030 |
| Sign up and link local data to the account | once | ≤ 5 taps, resumable | UX-016, UX-017 |
| Open a Project and start a Visit at a Site (starts the effort timer) | 1–5/day | ≤ 4 taps, ≤ 20 s, one-handed | UX-009, UX-011, UX-019, UX-032 |
| Resume an in-progress Visit from home | 1–5/day | ≤ 1 tap | UX-021 |
| Mark a target taxon detected / not detected | dozens–hundreds/session | ≤ 2 taps, no typing, one-handed | UX-003, UX-004, UX-012 |
| Add an opportunistic taxon by abbreviation search | 0–20/session | ≤ 5 taps, ≤ 15 s, one-handed | UX-005 |
| Pin a Taxonomic reference and resolve provisional taxa | once per project, then whenever the list changes | pin ≤ 3 taps; the unresolved list is ≤ 1 tap away | UX-032, UX-033, UX-034, UX-035 |
| Attach Evidence (photo/audio) to a Detection | 0–20/session | ≤ 3 taps | UX-010 |
| Record visit covariates | 1/visit | ≤ 1 tap each with defaults, ≤ 30 s total | UX-011 |
| End and submit a Visit | 1–5/day | ≤ 3 taps; ending and submission are never blocked, and an unresolved Visit is held out of exports | UX-003, UX-006, UX-035 |

Budgets reference the paper field sheet this replaces: no task may be slower
than writing it on paper.

## Interaction rules

| ID | Rule (falsifiable) | Why | Proof hint |
|---|---|---|---|
| UX-001 | Touch targets are ≥ 48 dp (Android) / ≥ 44 pt (iOS), with ≥ 8 dp between adjacent targets. | Gloves and motion; platform minimums (Material 48 dp, HIG 44 pt). | render |
| UX-002 | Body text is ≥ 16 sp/pt; critical field text (effort, detection state, target names) has contrast ≥ 7:1, other text ≥ 4.5:1, non-text and large text ≥ 3:1. | Direct sun destroys low contrast; WCAG 2.2 AA baseline, critical text to AAA. | inspect |
| UX-003 | Detection marking is a two-state control (detected / not detected); "not yet recorded" is a visibly distinct third state; ending a Visit shows a non-blocking summary of the targets left unrecorded, and an unrecorded target is stored as "not recorded" and makes the Visit not analysis-ready (INV-019). | Non-detection is only data if the search is recorded; the domain makes "not recorded" and "not detected" different. | test |
| UX-004 | The next unrecorded target is reachable in ≤ 1 tap from the visit screen, without scrolling to find it. | The core loop must beat the paper sheet. | test |
| UX-005 | Taxa are entered by picking from a list or by abbreviation search once the Project's reference is available; before one is pinned, or for a name that does not resolve, entry is allowed only as an explicitly provisional taxon. Free text is never silently accepted as a resolved taxon (INV-021). | Typing outdoors in gloves is slow and error-prone, and unresolved free text pollutes the data; provisional entry keeps capture open without accepting it as final. | test |
| UX-006 | Every destructive action (end Visit, discard an in-progress Visit, delete Evidence) requires confirmation and offers undo where feasible. | A mis-tap must not lose field work. | test |
| UX-007 | Offline never blocks capture or submission: recording detections, capturing Evidence, ending a Visit and submitting it all work with no network; only delivery waits. | Connectivity is absent for whole days. | test |
| UX-008 | Sync and save state are always visible on every screen through one persistent, non-modal shell indicator. | The user must always know whether work is safe, whichever screen they are on. | render |
| UX-009 | The effort timer keeps running across app backgrounding and device sleep, and is resumable after a kill. | Effort is data; a screen-off pause must not corrupt it. | test |
| UX-010 | Evidence capture is ≤ 1 tap from the Detection it belongs to. | A sighting is a fleeting moment. | render |
| UX-011 | Numeric and covariate fields default to the last used value or the protocol default, and manual entry is always available when a sensor is absent. | Many low-end phones lack sensors; manual entry is the fallback. | test |
| UX-012 | All primary field controls sit within the lower two-thirds of the screen. | One-handed reach with the other hand occupied. | render |
| UX-013 | No data loss on crash or kill: every change persists to the local store immediately, and a relaunch restores the in-progress Visit. | Top quality attribute: offline reliability and data integrity. | test |
| UX-014 | When sensitive-taxa coordinates are hidden, the UI states that they are hidden. | Obfuscation must not look like a bug. | render |
| UX-015 | Creating a Project and capturing a Visit require no sign-in; the sign-in/up surface is offered, never enforced before field work. | A creator must be able to start a survey immediately; signing in is never a precondition (INV-016). | test |
| UX-016 | An unlinked Project and its Visits persist indefinitely; signing in, signing out, or a failed link never deletes, hides, or blocks them. | Local-only work is real work and must never be held hostage to an account. | test |
| UX-017 | Linking local data shows progress and, on failure, keeps all local data and offers a retry; a completed link is resumable without duplicating a Project or a Membership. | Linking may span a dead network; it must be idempotent and recoverable (INV-014). | test |
| UX-019 | Every Site and Visit is reached only inside its Project; no screen lists Sites or Visits across Projects. | The domain scopes both to one Project (INV-012); a cross-project list hides that. | test |
| UX-020 | While working inside a Project, its name is always visible. | The collector must never be unsure which Project a Visit belongs to. | render |
| UX-021 | An in-progress Visit is resumable in ≤ 1 tap from the Projects list after a relaunch. | A field day is interrupted; the running Visit must be one tap away (UX-013). | test |
| UX-022 | A Project card shows its basic info — its name, its authored description and its pinned Taxonomic reference version when one is set — and states plainly when no reference is pinned yet; an empty Project's hub shows a first-run prompt to add a Site or define a Protocol. | The list must let each Project be told apart, and must never imply a reference the Project does not have. | test |
| UX-023 | A streamlined in-app manual is reachable from the Projects list and explains the core journey. | Users learn IBIS in the field, without external documentation. | inspect |
| UX-024 | With no Project, the Projects list shows an empty state: a one-line explanation of what a Project is, a primary action to create one, and a secondary link to the in-app manual. | A newcomer must be able to start a survey with no Project yet. | test |
| UX-025 | The Project creation form and the Project settings surface validate each field inline, under that field, and report invalid input before any request leaves the device. | On-device errors read faster and avoid a wasted round-trip from the field. | test |
| UX-026 | The create form's only field, the Project name, carries no helper text; the non-obvious settings fields (the pinned Taxonomic reference id and version) carry helper text stating what the field is and why the Project needs it. | Helper text on every field is noise; on a domain field it is the difference between guessing and knowing. | test |
| UX-027 | While a Project selects an Analysis spec, the Protocol-design surface shows that spec's hard structural requirements and its context-dependent warnings; a warning is dismissed only with a recorded reason that reaches the export methods paragraph. | The design decisions that decide analysability are made before fieldwork, when they can still change. | test |
| UX-028 | Before generating an analysis bundle, a readiness check reports whether the Project's data satisfies the selected spec; a failed hard gate blocks only the bundle, never capture or submission, and names the unmet requirement. | A design that cannot support the model must not pass silently, and field data collection must never be blocked. | test |
| UX-029 | The analysis bundle states, in the bundle and in the UI, that the readiness check confirms the data can support the model — not that the resulting estimate is valid. | Asymmetric confidence: a polished bundle must not read as a warrant of validity. | test |
| UX-030 | The selected Analysis spec is always visible on the Project hub. | The analysis intent must never be hidden behind a distant setting. | render |
| UX-031 | A single-period analysis is labelled "occupancy" only when an explicit closure claim is recorded; otherwise its output is labelled "use". | When closure fails and change is assumed random, the estimand becomes use, and calling it occupancy is misleading. | test |
| UX-032 | Capture, ending and submission are never blocked by a missing pinned Taxonomic reference or Protocol version: a Visit starts and is submitted with only a Site, and its Detections may hold provisional taxa (INV-019, INV-020). | A student may not yet know the reference; blocking capture or submission strands real field work (UX-007). | test |
| UX-033 | A provisional taxon carries a visible "unresolved" marker everywhere it appears and is never styled like a resolved taxon. | An unresolved name must not be mistaken for a resolved one, or it pollutes the record silently (UX-014). | render |
| UX-034 | When a Project has no pinned reference or a taxon does not resolve, a non-blocking banner (visit and hub) and a Project-card badge state it and offer the pin/download action; capture and submission are never interrupted by a blocking modal. | The user must be prompted to fix the gap without losing the field moment. | test |
| UX-035 | A Visit that is not analysis-ready is submitted and queued like any other; a needs-attention surface names each unmet requirement (no Protocol version, no pinned reference, unresolved taxa, unrecorded targets) with an action, and the Visit is held out of every export until it clears. | Rigor is enforced at export, not by blocking the field user; the fix must be actionable (INV-022, UX-028). | test |

## System states

| State | Trigger | The user sees | The user can still | Rules |
|---|---|---|---|---|
| No Project | the Projects list has no Project | an empty state: a one-line explanation, a create action, and a link to the manual | create a Project; open the manual | UX-024 |
| Empty Project | a Project with no Sites or Visits | on the hub, a first-run prompt to add a Site or define a Protocol | add Sites and config; start a Visit | UX-022 |
| Taxa unresolved | the Project has no pinned reference, or its pinned reference's artifact is not on the device | a non-blocking banner naming the gap, the pin/download action, and provisional taxa marked as unresolved | capture, end and submit Visits; pin/download the reference; edit config; the Visit is held out of exports until resolved | UX-032, UX-033, UX-034, UX-035 |
| Visit provisional | a submitted Visit is not analysis-ready (no Protocol version, no pinned reference, unresolved taxa, or unrecorded targets) | a needs-attention list on the Visit and the Project hub, and a Project-card badge | keep working and capturing; resolve the reference, Protocol version, names and targets; the Visit is excluded from every export | UX-034, UX-035 |
| Analysis not ready | the selected spec's readiness check fails | a notice naming the unmet requirement; the analysis bundle is unavailable | keep capturing and exporting data; adjust the Protocol next time | UX-028 |
| Offline | no connection | a persistent offline indicator in the shell | capture everything; submission queued | UX-007, UX-008 |
| Unlinked | a Project/Visit created with no account | a persistent "local only — sign up to sync" indicator | create, capture and edit everything offline | UX-008, UX-015, UX-016 |
| Linking | a link/upload in flight | a progress indicator | keep working; nothing is blocked | UX-017 |
| Link failed | link rejected or network error | a retryable notice; local data intact | retry; keep working offline | UX-016, UX-017 |
| Syncing | a submission in flight | a progress indicator in the shell | continue other work | UX-008 |
| Sync failed | upload rejected or network error | a retryable failure notice with the reason | keep editing (submitted data unchanged); retry | UX-006, UX-013 |
| Effort timer in background | app backgrounded | a notification/ongoing-timer indicator | return and continue | UX-009 |
| Missing sensor | phone has no such sensor | the field is manual, labelled as such | enter the value manually | UX-011 |
| Sensor not calibrated | calibration unknown/expired | the value is marked low-confidence | accept with provenance or enter manually | UX-011 |
| GPS accuracy poor | low accuracy fix | an accuracy warning on the coordinate | record anyway (accuracy stored), or adjust | UX-011 |
| Low battery | battery threshold | a low-battery notice | everything, with evidence capture warned | UX-013 |
| Storage full | local store full | a blocking notice naming Evidence as the cause | end and submit; delete Evidence | UX-006 |
| Error | unexpected failure | a non-destructive error with a next step | retry; no data lost | UX-013 |

## Data safety

Continuous autosave: every change is written to the local SQLite store
immediately. A crash, kill or battery death restores the in-progress Visit on
relaunch. Data is "safe" only once the server has accepted the submission;
retries are idempotent, so a re-submission never duplicates a Visit. Local data
created with no account is never deleted by signing in, signing out, or a
failed link; linking is idempotent and resumable. Submission is never
refused: a Visit is submitted as it stands, and a provisional taxon is
submitted with it and resolved later by an append-only Correction; nothing
provisional enters an export until it is resolved (INV-021, INV-022).

## Accessibility & localization

- WCAG 2.2 AA baseline (4.5:1 text, 3:1 large/non-text, 24 px target minimum); critical field text pushed to 7:1 for glare.
- Dynamic type supported; layouts reflow rather than clip.
- Languages: English and Italian in v1, via Flutter localization.
- Units: metric by default, manual override for instruments; dates ISO; coordinates shown as decimal degrees and DMS.

## Open questions

- Whether a distinct "large field mode" is ever needed beyond dynamic type.
- Italian translation source and reviewer.
- Copy for the sensor-fallback and low-confidence states.
- Camera/microphone permission timing (pre-grant vs on first use).
- Copy for the unlinked and link-failed affordances, and whether linking is offered from the Projects list as well as the Account screen.
- The in-app manual's copy and source.
- The built-in Analysis spec's warning thresholds (closure window, minimum repeats).
- How a person joins an existing Project: invitations surfaced in a notification centre (explored later).
- Copy for the provisional-taxon marker, the "no reference pinned" banner, and the needs-attention (submission-readiness) list.
