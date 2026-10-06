/**
 * Configuration for the `taxonomic-references` module (ARCHITECTURE.md): where
 * the reference volume is mounted, read from the environment so the Compose
 * deployment can mount it without a code change (ADR-0020). The default matches
 * the media module's `/data/<name>` convention.
 */

/** Injection token for the resolved `TaxonomicReferencesConfig`. */
export const TAXONOMIC_REFERENCES_CONFIG = 'TAXONOMIC_REFERENCES_CONFIG';

/** Default mount point of the reference volume. */
export const DEFAULT_REFERENCE_ROOT = '/data/references';

export interface TaxonomicReferencesConfig {
  /** Root directory holding `<id>/<version>.json` reference artifacts. */
  root: string;
}

export function loadTaxonomicReferencesConfig(
  env: NodeJS.ProcessEnv = process.env,
): TaxonomicReferencesConfig {
  const root =
    env.REFERENCE_ROOT === undefined || env.REFERENCE_ROOT === ''
      ? DEFAULT_REFERENCE_ROOT
      : env.REFERENCE_ROOT;
  return { root };
}
