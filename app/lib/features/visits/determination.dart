/// The uncertainty qualifier a [Determination] may carry (DOMAIN.md ›
/// Determination): `cf.`, `aff.`, or `sp.`. The [wireValue] is the value the
/// server's `determination_qualifier` enum stores.
enum DeterminationQualifier {
  cf('cf.'),
  aff('aff.'),
  sp('sp.');

  const DeterminationQualifier(this.wireValue);

  final String wireValue;
}

/// A taxon assignment for a Detection (DOMAIN.md › Determination): the taxon,
/// its qualifier, specimen code, determiner, and date, plus a link to the
/// Determination it replaces.
///
/// Append-only (INV-009): every field is final and there is no copy or mutator
/// path, so a stored Determination is never overwritten. A revision is a new
/// Determination whose [replacesId] is the id of the one it replaces.
class Determination {
  const Determination({
    required this.id,
    required this.taxon,
    required this.determiner,
    required this.date,
    this.qualifier,
    this.specimenCode,
    this.replacesId,
  }) : assert(
         replacesId != id,
         'A Determination is never replaced by itself (INV-009)',
       );

  /// Client-generated identity of the Determination.
  final String id;

  /// The taxon assigned to the Detection.
  final String taxon;

  /// The uncertainty qualifier, when the assignment carries one.
  final DeterminationQualifier? qualifier;

  /// The specimen code, when a specimen was collected.
  final String? specimenCode;

  /// The person who made the determination.
  final String determiner;

  /// When the determination was made.
  final DateTime date;

  /// The id of the Determination this one replaces, or null for a first
  /// Determination (INV-009).
  final String? replacesId;

  @override
  bool operator ==(Object other) =>
      other is Determination &&
      other.id == id &&
      other.taxon == taxon &&
      other.qualifier == qualifier &&
      other.specimenCode == specimenCode &&
      other.determiner == determiner &&
      other.date == date &&
      other.replacesId == replacesId;

  @override
  int get hashCode => Object.hash(
    id,
    taxon,
    qualifier,
    specimenCode,
    determiner,
    date,
    replacesId,
  );
}
