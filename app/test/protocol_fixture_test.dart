import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ibis/protocol/protocol.dart';

const _fixturePath = '../packages/protocol/fixtures/protocol.example.json';
const _generatorPath = '../packages/protocol/scripts/gen-dart.mjs';
const _committedTypesPath = 'lib/protocol/protocol.dart';

Map<String, dynamic> loadFixture() {
  final file = File(_fixturePath);
  if (!file.existsSync()) {
    throw StateError('Protocol fixture missing at ${file.absolute.path}');
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  test('the golden fixture parses through the generated Dart types', () {
    final fixture = loadFixture();

    final document = ProtocolDocument.fromJson(fixture);

    expect(document.protocolId, 'alpine-birds-2026');
    expect(document.version, 1);
    expect(document.taxonomicScope.taxa, ['Aves']);
    expect(document.targetList, hasLength(2));
    expect(document.targetList!.first.taxonRef, 'Aves|Turdus|merula');
    expect(document.targetList!.first.label, 'Common blackbird');
    expect(document.targetList!.last.label, 'European robin');
    expect(document.detectionMethods, hasLength(2));
    expect(document.detectionMethods.first.id, 'visual');
    expect(
      document.requiredEffortFields,
      contains(SamplingEffortField.detectionMethods),
    );

    final weather = document.visitCovariates!.firstWhere(
      (covariate) => covariate.options != null,
    );
    expect(weather.type, CovariateDefinitionType.enumValue);
    expect(weather.options, ['clear', 'cloudy', 'rain']);
    expect(document.siteCovariates!.single.name, 'habitat');
  });

  test('the generated Dart types parse and re-emit the fixture unchanged', () {
    final fixture = loadFixture();

    final document = ProtocolDocument.fromJson(fixture);

    expect(document.toJson(), fixture);
  });

  test('the committed Dart types are exactly what the generator emits', () {
    final temporary = Directory.systemTemp.createTempSync('gen-dart-');
    addTearDown(() => temporary.deleteSync(recursive: true));
    final output = '${temporary.path}/protocol.dart';

    final result = Process.runSync('node', [_generatorPath, '--out', output]);

    expect(result.exitCode, 0, reason: 'gen-dart.mjs failed: ${result.stderr}');
    expect(
      File(output).readAsStringSync(),
      File(_committedTypesPath).readAsStringSync(),
    );
  });
}
