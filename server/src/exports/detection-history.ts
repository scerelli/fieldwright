/**
 * The detection-history matrix builder for the `exports` module
 * (ARCHITECTURE.md): a pure function over a Project's Visits, their Detections
 * and the target taxa each Visit's Protocol version declares — its Target list,
 * or, in complete-list mode, the taxa in its declared taxonomic scope. It
 * produces the occupancy-ready matrix — one row per Visit, one column per
 * target taxon — ready for {@link serializeCsv}.
 *
 * The two states INV-019 keeps apart are kept apart here: a target taxon
 * with a recorded Detection is `1` (detected) or `0` (a non-detection, i.e. a
 * Detection with `detected = false`); a taxon with no recorded Detection is
 * left blank, never `0`, because "not recorded" is not "not detected". An
 * opportunistic Detection fills no cell and adds no column (INV-003).
 */

/** One Detection's contribution to the matrix (DOMAIN.md, INV-019, INV-003). */
export interface DetectionHistoryDetection {
  /** The Detection's taxon, matched against a declared target taxon. */
  taxon: string;
  /** True when detected, false for a non-detection. */
  detected: boolean;
  /** True when the Detection is outside the Target list (INV-003). */
  opportunistic: boolean;
}

/**
 * One Visit's matrix input: its identity columns, the target taxa its Protocol
 * version declares (in declared order) — its Target list `taxonRef`s, or, in
 * complete-list mode, its declared taxonomic scope's taxa — and its Detections.
 */
export interface DetectionHistoryVisit {
  visitId: string;
  siteId: string;
  surveyPeriodId: string;
  startedAt: Date;
  targetTaxonRefs: readonly string[];
  detections: readonly DetectionHistoryDetection[];
}

/** The matrix: the header row and one row per Visit, both ready for CSV. */
export interface DetectionHistoryMatrix {
  header: string[];
  rows: string[][];
}

const SITE_COLUMN = 'site_id';
const SURVEY_PERIOD_COLUMN = 'survey_period_id';
const VISIT_COLUMN = 'visit_id';
const STARTED_AT_COLUMN = 'started_at';

/**
 * Builds the detection-history matrix for `visits`. Rows are ordered by Site
 * id, then Visit `startedAt`, then Visit id (so two Visits that agree on both
 * still order deterministically); taxon columns are the distinct declared
 * target taxa in first-seen order over the ordered Visits. Identical input
 * therefore produces identical output.
 */
export function buildDetectionHistoryMatrix(
  visits: readonly DetectionHistoryVisit[],
): DetectionHistoryMatrix {
  const ordered = [...visits].sort(compareVisits);
  const taxonRefs = collectTaxonRefs(ordered);

  const header = [
    SITE_COLUMN,
    SURVEY_PERIOD_COLUMN,
    VISIT_COLUMN,
    STARTED_AT_COLUMN,
    ...taxonRefs,
  ];

  const rows = ordered.map((visit) => [
    visit.siteId,
    visit.surveyPeriodId,
    visit.visitId,
    visit.startedAt.toISOString(),
    ...taxonRefs.map((taxonRef) => cellFor(visit, taxonRef)),
  ]);

  return { header, rows };
}

/** Site id → Visit `startedAt` → Visit id, each an ascending comparison. */
function compareVisits(
  left: DetectionHistoryVisit,
  right: DetectionHistoryVisit,
): number {
  if (left.siteId !== right.siteId) {
    return left.siteId < right.siteId ? -1 : 1;
  }
  const byTime = left.startedAt.getTime() - right.startedAt.getTime();
  if (byTime !== 0) {
    return byTime < 0 ? -1 : 1;
  }
  if (left.visitId !== right.visitId) {
    return left.visitId < right.visitId ? -1 : 1;
  }
  return 0;
}

/** The distinct declared target taxa, in first-seen order. */
function collectTaxonRefs(visits: readonly DetectionHistoryVisit[]): string[] {
  const seen = new Set<string>();
  const refs: string[] = [];
  for (const visit of visits) {
    for (const taxonRef of visit.targetTaxonRefs) {
      if (!seen.has(taxonRef)) {
        seen.add(taxonRef);
        refs.push(taxonRef);
      }
    }
  }
  return refs;
}

/**
 * The cell for a declared target taxon: `1` or `0` from the Visit's
 * non-opportunistic Detection for that taxon, or blank when none is recorded
 * (INV-019). Opportunistic Detections never fill a cell (INV-003).
 */
function cellFor(visit: DetectionHistoryVisit, taxonRef: string): string {
  const detection = visit.detections.find(
    (candidate) => !candidate.opportunistic && candidate.taxon === taxonRef,
  );
  if (detection === undefined) {
    return '';
  }
  return detection.detected ? '1' : '0';
}
