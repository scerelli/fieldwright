import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/features/visits/capture_screen.dart';
import 'package:ibis/features/visits/detection.dart';
import 'package:ibis/features/visits/evidence.dart';
import 'package:ibis/features/visits/evidence_capture.dart';
import 'package:ibis/features/visits/visit.dart';
import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/protocol/protocol.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/database_provider.dart';
import 'package:ibis/store/detection_dao.dart';
import 'package:ibis/store/evidence_dao.dart';
import 'package:ibis/store/visit_dao.dart';

void main() {
  group('Evidence', () {
    test('holds its kind, local file path, capture time and content hash', () {
      final capturedAt = DateTime.utc(2026, 5, 1, 8, 0);
      final evidence = Evidence(
        id: 'evidence-1',
        visitId: 'visit-1',
        taxonRef: 'Aves|Turdus|merula',
        kind: EvidenceKind.photo,
        filePath: '/data/evidence/evidence-1.jpg',
        capturedAt: capturedAt,
        contentHash: 'deadbeef',
      );

      expect(evidence.id, 'evidence-1');
      expect(evidence.visitId, 'visit-1');
      expect(evidence.taxonRef, 'Aves|Turdus|merula');
      expect(evidence.kind, EvidenceKind.photo);
      expect(evidence.filePath, '/data/evidence/evidence-1.jpg');
      expect(evidence.capturedAt, capturedAt);
      expect(evidence.contentHash, 'deadbeef');
    });

    test('two Evidence with the same fields are equal', () {
      final capturedAt = DateTime.utc(2026, 5, 1, 8, 0);
      Evidence build() => Evidence(
        id: 'evidence-1',
        visitId: 'visit-1',
        taxonRef: 'Aves|Turdus|merula',
        kind: EvidenceKind.audio,
        filePath: '/data/evidence/evidence-1.m4a',
        capturedAt: capturedAt,
        contentHash: 'deadbeef',
      );

      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });
  });

  group('local media store', () {
    test(
      'copies a captured file into the local directory and hashes its bytes',
      () async {
        final source = Directory.systemTemp.createTempSync('ibis_evidence_src');
        addTearDown(() => source.deleteSync(recursive: true));
        final destination = Directory.systemTemp.createTempSync(
          'ibis_evidence_dst',
        );
        addTearDown(() => destination.deleteSync(recursive: true));
        final bytes = <int>[1, 2, 3, 4, 5];
        final file = File('${source.path}/capture.jpg')
          ..writeAsBytesSync(bytes);
        final capturedAt = DateTime.utc(2026, 5, 1, 8, 0);

        final media = await persistEvidenceFile(
          kind: EvidenceKind.photo,
          sourcePath: file.path,
          directory: destination,
          capturedAt: capturedAt,
        );

        expect(media.kind, EvidenceKind.photo);
        expect(media.capturedAt, capturedAt);
        expect(media.contentHash, sha256.convert(bytes).toString());
        expect(media.filePath.startsWith(destination.path), isTrue);
        final stored = File(media.filePath);
        expect(stored.existsSync(), isTrue);
        expect(stored.readAsBytesSync(), bytes);
      },
    );

    test(
      'stores audio with an audio extension and a fresh file name',
      () async {
        final source = Directory.systemTemp.createTempSync('ibis_evidence_src');
        addTearDown(() => source.deleteSync(recursive: true));
        final destination = Directory.systemTemp.createTempSync(
          'ibis_evidence_dst',
        );
        addTearDown(() => destination.deleteSync(recursive: true));
        final file = File('${source.path}/recording.m4a')
          ..writeAsBytesSync([9]);

        final media = await persistEvidenceFile(
          kind: EvidenceKind.audio,
          sourcePath: file.path,
          directory: destination,
        );

        expect(media.kind, EvidenceKind.audio);
        expect(media.filePath.endsWith('.m4a'), isTrue);
        expect(File(media.filePath).existsSync(), isTrue);
      },
    );
  });

  group('EvidenceDao', () {
    test(
      'attaches an Evidence to a Detection identically to the local store',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final dao = EvidenceDao(database);
        final capturedAt = DateTime.utc(2026, 5, 1, 8, 0);

        final attached = await dao.attach(
          visitId: 'visit-1',
          taxonRef: 'Aves|Turdus|merula',
          kind: EvidenceKind.photo,
          filePath: '/data/evidence/photo.jpg',
          contentHash: 'deadbeef',
          capturedAt: capturedAt,
        );

        expect(attached.id, isNotEmpty);
        final stored = await dao.forDetection('visit-1', 'Aves|Turdus|merula');
        expect(stored, hasLength(1));
        expect(stored.single, equals(attached));
        expect(stored.single.kind, EvidenceKind.photo);
        expect(stored.single.contentHash, 'deadbeef');
        expect(stored.single.capturedAt, capturedAt);
      },
    );

    test(
      'an attached Evidence is stored locally and outlives a store reopen',
      () async {
        final directory = Directory.systemTemp.createTempSync(
          'ibis_evidence_db',
        );
        addTearDown(() => directory.deleteSync(recursive: true));
        final path = '${directory.path}/ibis.sqlite';

        var database = AppDatabase.open(path);
        final attached = await EvidenceDao(database).attach(
          visitId: 'visit-1',
          taxonRef: 'Aves|Turdus|merula',
          kind: EvidenceKind.audio,
          filePath: '${directory.path}/audio.m4a',
          contentHash: 'deadbeef',
          capturedAt: DateTime.utc(2026, 5, 1, 8, 0),
        );
        await database.close();

        database = AppDatabase.open(path);
        final loaded = await EvidenceDao(database).findById(attached.id);
        await database.close();

        expect(loaded, isNotNull);
        expect(loaded!.kind, EvidenceKind.audio);
        expect(loaded.filePath, '${directory.path}/audio.m4a');
        expect(loaded.contentHash, 'deadbeef');
      },
    );

    test('the append-only store rejects a duplicate Evidence id', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final dao = EvidenceDao(database);

      await dao.attach(
        id: 'evidence-1',
        visitId: 'visit-1',
        taxonRef: 'Aves|Turdus|merula',
        kind: EvidenceKind.photo,
        filePath: '/a.jpg',
        contentHash: 'a',
        capturedAt: DateTime.utc(2026, 1, 1),
      );

      await expectLater(
        () => dao.attach(
          id: 'evidence-1',
          visitId: 'visit-1',
          taxonRef: 'Aves|Turdus|merula',
          kind: EvidenceKind.photo,
          filePath: '/b.jpg',
          contentHash: 'b',
          capturedAt: DateTime.utc(2026, 1, 2),
        ),
        throwsA(
          predicate(
            (error) => error.toString().toUpperCase().contains('UNIQUE'),
            'a unique-constraint violation',
          ),
        ),
      );

      final stored = await dao.findById('evidence-1');
      expect(stored!.filePath, '/a.jpg');
      expect(stored.contentHash, 'a');
    });
  });

  group('migration', () {
    test(
      'migrates a version 6 client schema to version 10 forward-only',
      () async {
        final database = AppDatabase(
          NativeDatabase.memory(
            setup: (raw) {
              raw.execute('''
CREATE TABLE sites (
  id TEXT NOT NULL,
  project_id TEXT NOT NULL,
  geometry TEXT NOT NULL,
  origin TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  location_provenance TEXT,
  covariates TEXT,
  PRIMARY KEY (id)
);
''');
              raw.execute('''
CREATE TABLE visits (
  id TEXT NOT NULL,
  site_id TEXT NOT NULL,
  survey_period_id TEXT NOT NULL,
  protocol_version_id TEXT NOT NULL,
  state TEXT NOT NULL,
  effort_started_at INTEGER NOT NULL,
  effort_ended_at INTEGER,
  PRIMARY KEY (id)
);
''');
              raw.execute('''
CREATE TABLE detections (
  visit_id TEXT NOT NULL,
  taxon_ref TEXT NOT NULL,
  detected INTEGER NOT NULL,
  opportunistic INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (visit_id, taxon_ref)
);
''');
              raw.execute(
                "INSERT INTO visits (id, site_id, survey_period_id, protocol_version_id, state, effort_started_at) "
                "VALUES ('visit-1', 'site-1', 'survey-period-1', 'protocol-version-1', 'inProgress', 1767225600);",
              );
              raw.execute('PRAGMA user_version = 6');
            },
          ),
        );
        addTearDown(database.close);

        final version = await database
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(version.data['user_version'], 17);

        final tables = await database
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'evidences'",
            )
            .get();
        expect(tables, hasLength(1));

        final dao = EvidenceDao(database);
        final attached = await dao.attach(
          visitId: 'visit-1',
          taxonRef: 'Aves|Turdus|merula',
          kind: EvidenceKind.photo,
          filePath: '/data/evidence/photo.jpg',
          contentHash: 'deadbeef',
          capturedAt: DateTime.utc(2026, 1, 1),
        );
        expect((await dao.findById(attached.id))!.kind, EvidenceKind.photo);
      },
    );
  });

  group('capture affordance', () {
    const taxonRef = 'Aves|Turdus|merula';

    ProtocolDocument document() => ProtocolDocument(
      protocolId: 'alpine-birds',
      version: 1,
      taxonomicScope: const TaxonomicScope(taxa: ['Aves']),
      detectionMethods: const [DetectionMethod(id: 'visual', label: 'Visual')],
      requiredEffortFields: const [SamplingEffortField.start],
      targetList: const [
        TargetTaxon(taxonRef: taxonRef, label: 'Common blackbird'),
      ],
    );

    Future<Visit> startVisit(AppDatabase database) => VisitDao(database)
        .startVisit(
          siteId: 'site-1',
          surveyPeriodId: 'survey-period-1',
          protocolVersionId: 'protocol-version-1',
        );

    Future<void> recordDetection(AppDatabase database, Visit visit) =>
        DetectionDao(database).record(
          Detection(
            visitId: visit.id,
            taxonRef: taxonRef,
            detected: true,
            method: 'visual',
          ),
        );

    Future<void> pumpCapture(
      WidgetTester tester, {
      required AppDatabase database,
      required Visit visit,
      required EvidenceCaptureService service,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
            evidenceCaptureServiceProvider.overrideWithValue(service),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CaptureScreen(visit: visit, protocol: document()),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'attaches a photo Evidence to a Detection in three taps or fewer (UX-010)',
      (tester) async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final visit = await startVisit(database);
        await recordDetection(database, visit);
        final media = CapturedMedia(
          kind: EvidenceKind.photo,
          filePath: '/data/evidence/photo.jpg',
          contentHash: 'photo-hash',
          capturedAt: DateTime.utc(2026, 5, 1, 8, 0),
        );
        final service = _FakeEvidenceCaptureService(photo: media);

        await pumpCapture(
          tester,
          database: database,
          visit: visit,
          service: service,
        );

        var taps = 0;
        await tester.tap(find.byKey(const Key('capture_photo_$taxonRef')));
        taps++;
        await tester.pumpAndSettle();

        expect(taps, lessThanOrEqualTo(3));
        expect(service.photoCalls, 1);
        final stored = await EvidenceDao(database)
            .forDetection(visit.id, taxonRef);
        expect(stored, hasLength(1));
        expect(stored.single.kind, EvidenceKind.photo);
        expect(stored.single.contentHash, 'photo-hash');
        expect(stored.single.filePath, '/data/evidence/photo.jpg');
        expect(find.byKey(Key('evidence_${stored.single.id}')), findsOneWidget);
      },
    );

    testWidgets(
      'attaches an audio Evidence to a Detection in three taps or fewer (UX-010)',
      (tester) async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final visit = await startVisit(database);
        await recordDetection(database, visit);
        final media = CapturedMedia(
          kind: EvidenceKind.audio,
          filePath: '/data/evidence/audio.m4a',
          contentHash: 'audio-hash',
          capturedAt: DateTime.utc(2026, 5, 1, 8, 0),
        );
        final service = _FakeEvidenceCaptureService(audio: media);

        await pumpCapture(
          tester,
          database: database,
          visit: visit,
          service: service,
        );

        var taps = 0;
        await tester.tap(find.byKey(const Key('capture_audio_$taxonRef')));
        taps++;
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('evidence_audio_stop_$taxonRef')),
        );
        taps++;
        await tester.pumpAndSettle();

        expect(taps, lessThanOrEqualTo(3));
        expect(service.audioStarts, 1);
        expect(service.audioStops, 1);
        final stored = await EvidenceDao(database)
            .forDetection(visit.id, taxonRef);
        expect(stored, hasLength(1));
        expect(stored.single.kind, EvidenceKind.audio);
        expect(stored.single.contentHash, 'audio-hash');
      },
    );

    testWidgets('a cancelled capture attaches no Evidence', (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final visit = await startVisit(database);
      await recordDetection(database, visit);
      final service = _FakeEvidenceCaptureService();

      await pumpCapture(
        tester,
        database: database,
        visit: visit,
        service: service,
      );

      await tester.tap(find.byKey(const Key('capture_photo_$taxonRef')));
      await tester.pumpAndSettle();

      expect(service.photoCalls, 1);
      expect(
        await EvidenceDao(database).forDetection(visit.id, taxonRef),
        isEmpty,
      );
    });

    testWidgets('reports a failed capture without attaching any Evidence', (
      tester,
    ) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final visit = await startVisit(database);
      await recordDetection(database, visit);
      final service = _FakeEvidenceCaptureService(failPhoto: true);

      await pumpCapture(
        tester,
        database: database,
        visit: visit,
        service: service,
      );

      await tester.tap(find.byKey(const Key('capture_photo_$taxonRef')));
      await tester.pumpAndSettle();

      expect(
        find.text('Could not capture evidence. Try again.'),
        findsOneWidget,
      );
      expect(
        await EvidenceDao(database).forDetection(visit.id, taxonRef),
        isEmpty,
      );
    });
  });
}

class _FakeEvidenceCaptureService implements EvidenceCaptureService {
  _FakeEvidenceCaptureService({this.photo, this.audio, this.failPhoto = false});

  final CapturedMedia? photo;
  final CapturedMedia? audio;
  final bool failPhoto;
  int photoCalls = 0;
  int audioStarts = 0;
  int audioStops = 0;

  @override
  Future<CapturedMedia?> capturePhoto() async {
    photoCalls++;
    if (failPhoto) {
      throw const EvidenceCaptureException('no camera');
    }
    return photo;
  }

  @override
  Future<void> startAudioRecording() async {
    audioStarts++;
  }

  @override
  Future<CapturedMedia?> stopAudioRecording() async {
    audioStops++;
    return audio;
  }
}
