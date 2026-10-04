# ADR-0018: Declarative Analysis spec catalogue, analysis run externally

Status: Accepted
Date: 2026-10-04
Doc: ARCHITECTURE.md

## Decision
The app models analyses as a catalogue of declarative `AnalysisSpec` values rather than as an analysis engine. A spec defines the question it answers, the data shape it requires (repeat Visits, closure, required effort and covariates, completeness), the target tool, and the bundle it emits. A Project records an optional objective and selects one spec; v1 ships a closed, single-species occupancy/detection spec targeting `unmarked`. The spec gates and warns on the Protocol design and on export readiness, and export emits a bundle — detection-history matrix, occasion-covariate table, a data dictionary, a generated methods paragraph and a runnable R recipe — that the researcher runs externally. No analysis executes in-app and no author-supplied code ever runs (INV-018).

## Context
The earlier framing — "exports load cleanly into an occupancy model" — confuses a formatting property (clean loading) with a validity property (a design that identifies the model). A ready-to-run bundle can read as a warrant of validity over a design that cannot support it; that asymmetric confidence is the capability's main risk. The design-time contract is where the value is: naming the model forces closure, repeat structure and effort decisions before fieldwork, when they can still change. Supporting a catalogue rather than a single hardcoded analysis lets the research question choose the analysis — the product's differentiator — without building a statistical engine, which would break the non-devops/self-host constraint and multiply the cookbook risk.

## Alternatives considered
- A single hardcoded occupancy analysis — rejected: forces a rewrite when a second analysis lands; the catalogue costs little more now.
- An in-app analysis engine (fit and display results) — rejected for v1: statistics, compute, reproducibility and sandboxing are a platform-sized commitment that contradicts self-host-by-a-non-devops-operator and the "export to `unmarked`" positioning; a spec format is the seam an engine could attach to later.
- Researcher-authored executable code — rejected: arbitrary code execution is the over-reach the literature warns against; authoring, when added, stays declarative data.
- Treating analysis as a second bounded context — rejected: analysis intent is Project configuration; one context still suffices.

## Consequences
Locks in: a new client `analyses` module and a shared `packages/analysis` spec format with Dart/TS codegen; `project` gains a nullable `objective` and selected `analysis_spec_id`/`analysis_spec_version` (server-schema migration) resolved against a built-in catalogue; the server `exports` module emits the bundle; hard structural gates block the bundle but never capture, and context-dependent warnings are overridable with a recorded justification that reaches the methods paragraph. INV-018 forbids executing specs or running author-supplied code. To revisit and add an engine, supersede this ADR and coordinate the spec format, the client module and the server exports module.
