import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One taxon of a [TaxonReference]: its scientific name and the field
/// abbreviation used to search for it. The name is the [Detection.taxonRef]
/// stored with an opportunistic Detection.
class Taxon {
  const Taxon({required this.name, required this.abbreviation});

  final String name;
  final String abbreviation;
}

/// The versioned external checklist taxon names resolve against
/// (GLOSSARY.md › Taxonomic reference). A Project pins one version; this
/// abstraction stands in for that pinned reference until project wiring
/// exists. Taxa are matched by their abbreviation (UX-005).
abstract class TaxonReference {
  /// The taxa whose abbreviation contains [abbreviation], case-insensitively.
  /// An empty query lists every taxon, so a list is always a valid way to
  /// pick a taxon and free text is never the only path (UX-005).
  List<Taxon> search(String abbreviation);
}

/// A [TaxonReference] backed by an in-memory list, for the stand-in reference
/// and for tests.
class InMemoryTaxonReference implements TaxonReference {
  const InMemoryTaxonReference(this.taxa);

  final List<Taxon> taxa;

  @override
  List<Taxon> search(String abbreviation) {
    final query = abbreviation.trim().toLowerCase();
    if (query.isEmpty) return taxa;
    return <Taxon>[
      for (final taxon in taxa)
        if (taxon.abbreviation.toLowerCase().contains(query)) taxon,
    ];
  }
}

/// The stand-in pinned Taxonomic reference used until the Projects module
/// pulls a real one. Abbreviations follow the field convention of the first
/// letters of the genus and species epithet.
const standInTaxa = <Taxon>[
  Taxon(name: 'Turdus merula', abbreviation: 'TURMER'),
  Taxon(name: 'Erithacus rubecula', abbreviation: 'ERRUB'),
  Taxon(name: 'Fringilla coelebs', abbreviation: 'FRCOE'),
  Taxon(name: 'Parus major', abbreviation: 'PARMAJ'),
  Taxon(name: 'Apus apus', abbreviation: 'APUAPU'),
];

final taxonReferenceProvider = Provider<TaxonReference>(
  (ref) => const InMemoryTaxonReference(standInTaxa),
);
