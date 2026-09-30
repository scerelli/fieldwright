export type SamplingEffortField =
  'start' | 'duration' | 'observers' | 'detectionMethods';

export type CovariateType = 'number' | 'text' | 'boolean' | 'date' | 'enum';

export interface CovariateDefinition {
  name: string;
  type: CovariateType;
  unit?: string;
  options?: string[];
}

export interface DetectionMethod {
  id: string;
  label: string;
}

export interface TargetTaxon {
  taxonRef: string;
  label?: string;
}

export interface TaxonomicScope {
  taxa: string[];
}

export interface ProtocolDocument {
  protocolId: string;
  version: number;
  taxonomicScope: TaxonomicScope;
  targetList?: TargetTaxon[];
  detectionMethods: DetectionMethod[];
  requiredEffortFields: SamplingEffortField[];
  visitCovariates?: CovariateDefinition[];
  siteCovariates?: CovariateDefinition[];
}
