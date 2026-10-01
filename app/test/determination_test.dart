import 'package:flutter_test/flutter_test.dart';

import 'package:ibis/features/visits/determination.dart';

Determination _first({String id = 'determination-1'}) => Determination(
  id: id,
  taxon: 'Anthus trivialis',
  qualifier: DeterminationQualifier.cf,
  specimenCode: 'SP-1',
  determiner: 'A. Determiner',
  date: DateTime.utc(2026, 4, 1),
);

Determination _withoutQualifier() => Determination(
  id: 'determination-1',
  taxon: 'Anthus trivialis',
  determiner: 'A. Determiner',
  date: DateTime.utc(2026, 4, 1),
);

/// A fully-populated Determination — every field set to a non-default value —
/// so each field can be varied in isolation by the equality tests.
Determination _baseline({
  String id = 'determination-1',
  String taxon = 'Anthus trivialis',
  DeterminationQualifier? qualifier = DeterminationQualifier.cf,
  String? specimenCode = 'SP-1',
  String determiner = 'A. Determiner',
  DateTime? date,
  String? replacesId = 'determination-0',
}) => Determination(
  id: id,
  taxon: taxon,
  qualifier: qualifier,
  specimenCode: specimenCode,
  determiner: determiner,
  date: date ?? DateTime.utc(2026, 4, 1),
  replacesId: replacesId,
);

void main() {
  group('Determination', () {
    test('declares its id, taxon, qualifier, specimen code, determiner, date and nullable replaces link', () {
      final determination = _first();

      expect(determination.id, 'determination-1');
      expect(determination.taxon, 'Anthus trivialis');
      expect(determination.qualifier, DeterminationQualifier.cf);
      expect(determination.specimenCode, 'SP-1');
      expect(determination.determiner, 'A. Determiner');
      expect(determination.date, DateTime.utc(2026, 4, 1));
      expect(determination.replacesId, isNull);
    });

    test('a first Determination has no replaced link', () {
      expect(_first().replacesId, isNull);
    });

    test(
      'a revision links to the replaced Determination and leaves it unchanged',
      () {
        final original = _first();
        final originalFields = (
          id: original.id,
          taxon: original.taxon,
          qualifier: original.qualifier,
          specimenCode: original.specimenCode,
          determiner: original.determiner,
          date: original.date,
          replacesId: original.replacesId,
        );

        final revision = Determination(
          id: 'determination-2',
          taxon: 'Anthus pratensis',
          qualifier: DeterminationQualifier.aff,
          determiner: 'B. Determiner',
          date: DateTime.utc(2026, 4, 2),
          replacesId: original.id,
        );

        expect(revision.replacesId, original.id);
        expect(revision.id, isNot(original.id));
        expect(original.id, originalFields.id);
        expect(original.taxon, originalFields.taxon);
        expect(original.qualifier, originalFields.qualifier);
        expect(original.specimenCode, originalFields.specimenCode);
        expect(original.determiner, originalFields.determiner);
        expect(original.date, originalFields.date);
        expect(original.replacesId, originalFields.replacesId);
        expect(original.replacesId, isNull);
      },
    );

    test('maps each qualifier to its server wire value', () {
      expect(DeterminationQualifier.cf.wireValue, 'cf.');
      expect(DeterminationQualifier.aff.wireValue, 'aff.');
      expect(DeterminationQualifier.sp.wireValue, 'sp.');
    });

    test('allows a Determination with no qualifier', () {
      expect(_withoutQualifier().qualifier, isNull);
    });

    test('two Determinations with the same fields are equal', () {
      final first = _baseline();
      final second = _baseline();

      expect(first, equals(second));
      expect(first.hashCode, equals(second.hashCode));
    });

    group('equality considers every field', () {
      test('a differing id makes two Determinations unequal', () {
        final base = _baseline();
        final changed = _baseline(id: 'determination-9');

        expect(changed, isNot(equals(base)));
        expect(changed.hashCode, isNot(base.hashCode));
      });

      test('a differing taxon makes two Determinations unequal', () {
        final base = _baseline();
        final changed = _baseline(taxon: 'Anthus pratensis');

        expect(changed, isNot(equals(base)));
        expect(changed.hashCode, isNot(base.hashCode));
      });

      test('a differing qualifier makes two Determinations unequal', () {
        final base = _baseline();
        final changed = _baseline(qualifier: DeterminationQualifier.aff);

        expect(changed, isNot(equals(base)));
        expect(changed.hashCode, isNot(base.hashCode));
      });

      test('a differing specimen code makes two Determinations unequal', () {
        final base = _baseline();
        final changed = _baseline(specimenCode: 'SP-2');

        expect(changed, isNot(equals(base)));
        expect(changed.hashCode, isNot(base.hashCode));
      });

      test('a differing determiner makes two Determinations unequal', () {
        final base = _baseline();
        final changed = _baseline(determiner: 'B. Determiner');

        expect(changed, isNot(equals(base)));
        expect(changed.hashCode, isNot(base.hashCode));
      });

      test('a differing date makes two Determinations unequal', () {
        final base = _baseline();
        final changed = _baseline(date: DateTime.utc(2026, 4, 2));

        expect(changed, isNot(equals(base)));
        expect(changed.hashCode, isNot(base.hashCode));
      });

      test('a differing replaced link makes two Determinations unequal', () {
        final base = _baseline();
        final changed = _baseline(replacesId: 'determination-7');

        expect(changed, isNot(equals(base)));
        expect(changed.hashCode, isNot(base.hashCode));
      });
    });

    test('rejects a Determination whose replaced link names its own id', () {
      expect(
        () => Determination(
          id: 'determination-1',
          taxon: 'Anthus trivialis',
          determiner: 'A. Determiner',
          date: DateTime.utc(2026, 4, 1),
          replacesId: 'determination-1',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
