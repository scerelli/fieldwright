# UX: IBIS — Integrated Biodiversity Inventory Survey

How the product has to work for a real person in a real place: gloves on, sun
on the screen, one hand holding binoculars, no signal, a cheap phone at 15%
battery. Visual decisions belong to `DESIGN.md`; this document is rules that
can fail, numbered so criteria can cite them.

## Context of use

- **Where**: outdoors in alpine, forest and wetland terrain. Direct sun, rain, cold, wind; gloves are common.
- **Posture**: frequently one-handed — the other hand holds binoculars or an instrument; eyes are on the animal, not the screen.
- **Connectivity**: none for whole days; the app is offline-first and submission waits for a connection.
- **Sessions**: long field days on one battery; Visits last minutes to hours.
- **Devices**: the low end of what students and researchers actually carry — modest Android phones (many without a barometer) and iOS. Every sensor-backed field has a manual fallback.

## Users

Trained researchers and students. Domain-skilled (they know their taxa and
protocol) but not necessarily phone-skilled, and often interrupted mid-task.
They work either alone or as a collector following someone else's protocol. A
creator may start with no account at all and adopt one later, so nothing may
assume a person is signed in.

## Critical tasks

| Task | Frequency | Budget | Rules |
|---|---|---|---|
| Create a Project and start a Visit with no account | once per project | ≤ 5 taps to start, no sign-in wall | UX-015 |
| Sign up and link local data to the account | once | ≤ 5 taps, resumable | UX-016, UX-017 |
| Start a Visit at a Site (starts the effort timer) | 1–5/day | ≤ 4 taps, ≤ 20 s, one-handed | UX-009, UX-011 |
| Mark a target taxon detected / not detected | dozens–hundreds/session | ≤ 2 taps, no typing, one-handed | UX-003, UX-004, UX-012 |
| Add an opportunistic taxon by abbreviation search | 0–20/session | ≤ 5 taps, ≤ 15 s, one-handed | UX-005 |
| Attach Evidence (photo/audio) to a Detection | 0–20/session | ≤ 3 taps | UX-010 |
| Record visit covariates | 1/visit | ≤ 1 tap each with defaults, ≤ 30 s total | UX-011 |
| End and submit a Visit | 1–5/day | ≤ 3 taps; blocked while any target is unrecorded | UX-003, UX-006 |

Budgets reference the paper field sheet this replaces: no task may be slower
than writing it on paper.

## Interaction rules

| ID | Rule (falsifiable) | Why | Proof hint |
|---|---|---|---|
| UX-001 | Touch targets are ≥ 48 dp (Android) / ≥ 44 pt (iOS), with ≥ 8 dp between adjacent targets. | Gloves and motion; platform minimums (Material 48 dp, HIG 44 pt). | render |
| UX-002 | Body text is ≥ 16 sp/pt; critical field text (effort, detection state, target names) has contrast ≥ 7:1, other text ≥ 4.5:1, non-text and large text ≥ 3:1. | Direct sun destroys low contrast; WCAG 2.2 AA baseline, critical text to AAA. | inspect |
| UX-003 | Detection marking is a two-state control (detected / not detected); "not yet recorded" is a visibly distinct third state; submission is disabled while any target is unrecorded. | Non-detection is only data if the search is recorded; the domain makes "not recorded" and "not detected" different. | test |
| UX-004 | The next unrecorded target is reachable in ≤ 1 tap from the visit screen, without scrolling to find it. | The core loop must beat the paper sheet. | test |
| UX-005 | Taxa are entered by picking from a list or by abbreviation search; free text is never the only path. | Typing outdoors in gloves is slow and error-prone. | test |
| UX-006 | Every destructive action (end Visit, discard an in-progress Visit, delete Evidence) requires confirmation and offers undo where feasible. | A mis-tap must not lose field work. | test |
| UX-007 | Offline never blocks capture: recording detections, capturing Evidence and ending a Visit all work with no network; only submission waits. | Connectivity is absent for whole days. | test |
| UX-008 | Sync and save state are always visible on the visit screen as a persistent, non-modal indicator. | The user must always know whether work is safe. | render |
| UX-009 | The effort timer keeps running across app backgrounding and device sleep, and is resumable after a kill. | Effort is data; a screen-off pause must not corrupt it. | test |
| UX-010 | Evidence capture is ≤ 1 tap from the Detection it belongs to. | A sighting is a fleeting moment. | render |
| UX-011 | Numeric and covariate fields default to the last used value or the protocol default, and manual entry is always available when a sensor is absent. | Many low-end phones lack sensors; manual entry is the fallback. | test |
| UX-012 | All primary field controls sit within the lower two-thirds of the screen. | One-handed reach with the other hand occupied. | render |
| UX-013 | No data loss on crash or kill: every change persists to the local store immediately, and a relaunch restores the in-progress Visit. | Top quality attribute: offline reliability and data integrity. | test |
| UX-014 | When sensitive-taxa coordinates are hidden, the UI states that they are hidden. | Obfuscation must not look like a bug. | render |
| UX-015 | Creating a Project and capturing a Visit require no sign-in; the sign-in/up surface is offered, never enforced before field work. | A creator must be able to start a survey immediately; signing in is never a precondition (INV-016). | test |
| UX-016 | An unlinked Project and its Visits persist indefinitely; signing in, signing out, or a failed link never deletes, hides, or blocks them. | Local-only work is real work and must never be held hostage to an account. | test |
| UX-017 | Linking local data shows progress and, on failure, keeps all local data and offers a retry; a completed link is resumable without duplicating a Project or a Membership. | Linking may span a dead network; it must be idempotent and recoverable (INV-014). | test |

## System states

| State | Trigger | The user sees | The user can still | Rules |
|---|---|---|---|---|
| Offline | no connection | a persistent offline indicator | capture everything; submission queued | UX-007, UX-008 |
| Unlinked | a Project/Visit created with no account | a persistent "local only — sign up to sync" indicator | create, capture and edit everything offline | UX-008, UX-015, UX-016 |
| Linking | a link/upload in flight | a progress indicator | keep working; nothing is blocked | UX-017 |
| Link failed | link rejected or network error | a retryable notice; local data intact | retry; keep working offline | UX-016, UX-017 |
| Syncing | a submission in flight | a progress indicator on the visit screen | continue other work | UX-008 |
| Sync failed | upload rejected or network error | a retryable failure notice with the reason | keep editing (submitted data unchanged); retry | UX-006, UX-013 |
| Effort timer in background | app backgrounded | a notification/ongoing-timer indicator | return and continue | UX-009 |
| Missing sensor | phone has no such sensor | the field is manual, labelled as such | enter the value manually | UX-011 |
| Sensor not calibrated | calibration unknown/expired | the value is marked low-confidence | accept with provenance or enter manually | UX-011 |
| GPS accuracy poor | low accuracy fix | an accuracy warning on the coordinate | record anyway (accuracy stored), or adjust | UX-011 |
| Low battery | battery threshold | a low-battery notice | everything, with evidence capture warned | UX-013 |
| Storage full | local store full | a blocking notice naming Evidence as the cause | end and submit; delete Evidence | UX-006 |
| Empty | no project/sites yet | an empty state pointing to setup or a join code | create a project with no account, or join | UX-015 |
| Error | unexpected failure | a non-destructive error with a next step | retry; no data lost | UX-013 |

## Data safety

Continuous autosave: every change is written to the local SQLite store
immediately. A crash, kill or battery death restores the in-progress Visit on
relaunch. Data is "safe" only once the server has accepted the submission;
retries are idempotent, so a re-submission never duplicates a Visit. Local data
created with no account is never deleted by signing in, signing out, or a
failed link; linking is idempotent and resumable.

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
- Copy for the unlinked and link-failed affordances, and whether linking is offered from the project list as well as the account screen.
