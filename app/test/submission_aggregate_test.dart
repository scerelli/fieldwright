import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:ibis/auth/auth_client.dart';
import 'package:ibis/features/sites/site.dart';
import 'package:ibis/features/visits/detection.dart';
import 'package:ibis/features/visits/determination.dart';
import 'package:ibis/features/visits/evidence.dart';
import 'package:ibis/features/visits/measurement.dart';
import 'package:ibis/features/visits/visit.dart';
import 'package:ibis/outbox/config_sync_client.dart';
import 'package:ibis/outbox/outbox.dart';
import 'package:ibis/outbox/sync_client.dart';
import 'package:ibis/projects/projects_client.dart';
import 'package:ibis/protocol/protocol.dart';
import 'package:ibis/protocol_versions/protocol_versions_client.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/config_dao.dart';
import 'package:ibis/store/detection_dao.dart';
import 'package:ibis/store/determination_dao.dart';
import 'package:ibis/store/evidence_dao.dart';
import 'package:ibis/store/measurement_dao.dart';
import 'package:ibis/store/outbox_dao.dart';
import 'package:ibis/store/project_dao.dart';
import 'package:ibis/store/site_dao.dart';
import 'package:ibis/store/visit_dao.dart';

/// Fakes the HTTP layer: no request ever leaves the process.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this._handle);

  final Future<ResponseBody> Function(RequestOptions options) _handle;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return _handle(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object body, {int statusCode = 201}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );

Dio _dioWith(FakeHttpAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
  dio.httpClientAdapter = adapter;
  return dio;
}

AuthClient _authWith(FakeHttpAdapter adapter) =>
    AuthClient(baseUrl: 'http://test.local', dio: _dioWith(adapter));

/// Accepts every submission after storing the request body.
FakeHttpAdapter acceptingAdapter() {
  final adapter = FakeHttpAdapter(
    (options) async => jsonResponse(<String, dynamic>{'id': 'visit-1'}),
  );
  return adapter;
}

SyncClient _syncClient(FakeHttpAdapter adapter) => SyncClient(
  baseUrl: 'http://test.local',
  auth: _authWith(adapter),
  dio: _dioWith(adapter),
);

Map<String, dynamic> _submission(FakeHttpAdapter adapter) =>
    (adapter.requests
                .firstWhere((request) => request.path == SyncClient.submitPath)
                .data!
            as Map)
        .cast<String, dynamic>();

int _submitCalls(FakeHttpAdapter adapter) => adapter.requests
    .where((request) => request.path == SyncClient.submitPath)
    .length;

Site _site() => Site(
  id: 'site-1',
  projectId: 'project-1',
  geometry: const PointGeometry(LatLng(45.0, 9.0)),
  origin: SiteOrigin.planned,
  createdAt: DateTime.utc(2026, 1, 1),
);

Future<Visit> _endedVisit(AppDatabase database) async {
  final dao = VisitDao(database);
  final visit = await dao.startVisit(
    siteId: 'site-1',
    surveyPeriodId: 'survey-period-1',
    protocolVersionId: 'pv1',
    now: DateTime.utc(2026, 5, 1, 7),
  );
  return dao.endVisit(visit, now: DateTime.utc(2026, 5, 1, 8));
}

/// A Protocol version whose target list is the two taxa the C2 test records.
const ProtocolDocument _protocolDocument = ProtocolDocument(
  protocolId: 'alpine-birds',
  version: 1,
  taxonomicScope: TaxonomicScope(taxa: <String>['Aves']),
  detectionMethods: <DetectionMethod>[
    DetectionMethod(id: 'visual', label: 'Visual'),
  ],
  requiredEffortFields: <SamplingEffortField>[SamplingEffortField.start],
  targetList: <TargetTaxon>[
    TargetTaxon(taxonRef: 'Aves|Turdus|merula'),
    TargetTaxon(taxonRef: 'Aves|Parus|major'),
  ],
);

/// Pins a Taxonomic reference on `project-1`, so its stored taxon keys resolve
/// and submit as `taxon` rather than as a `provisionalName` (INV-021).
Future<void> _seedPinnedProject(AppDatabase database) =>
    ProjectDao(database).save(
      const Project(
        id: 'project-1',
        name: 'Alpine Birds',
        validationEnabled: false,
        sensitiveTaxaObfuscation: true,
        taxonomicReferenceId: 'it-flora',
        taxonomicReferenceVersion: '2024.1',
      ),
    );

Future<void> _seedProtocolVersion(AppDatabase database) =>
    ConfigDao(database).apply(
      const ConfigPull(
        versionToken: 'token-1',
        protocolVersion: ProtocolVersion(
          id: 'pv1',
          projectId: 'project-1',
          document: _protocolDocument,
        ),
      ),
      projectId: 'project-1',
    );

Outbox _wiredOutbox(AppDatabase database, SyncClient client) => Outbox(
  OutboxDao(database),
  client: client,
  visits: VisitDao(database),
  sites: SiteDao(database),
  config: ConfigDao(database),
  detections: DetectionDao(database),
  determinations: DeterminationDao(database),
  evidence: EvidenceDao(database),
  measurements: MeasurementDao(database),
);

void main() {
  test('the built submission payload carries every Detection with its '
      'Determinations, every Measurement with its Provenance, and the Evidence '
      'manifest, matching the server contract exactly', () {
    final visit = Visit(
      id: 'visit-1',
      siteId: 'site-1',
      surveyPeriodId: 'survey-period-1',
      protocolVersionId: 'pv1',
      state: VisitState.ended,
      effort: SamplingEffort(
        startedAt: DateTime.utc(2026, 5, 1, 7),
        endedAt: DateTime.utc(2026, 5, 1, 8),
      ),
    );
    final aggregate = SubmissionAggregate(
      visit: visit,
      detections: <SubmittedDetection>[
        SubmittedDetection(
          detection: const Detection(
            visitId: 'visit-1',
            taxonRef: 'Aves|Turdus|merula',
            detected: true,
            method: 'visual',
            count: 3,
          ),
          determinations: <Determination>[
            Determination(
              id: 'determination-1',
              taxon: 'Turdus merula',
              qualifier: DeterminationQualifier.cf,
              specimenCode: 'SP-1',
              determiner: 'A. Determiner',
              date: DateTime.utc(2026, 4, 1),
            ),
          ],
        ),
        const SubmittedDetection(
          detection: Detection(
            visitId: 'visit-1',
            taxonRef: 'Aves|Parus|major',
            detected: false,
            method: 'visual',
          ),
        ),
        const SubmittedDetection(
          detection: Detection.opportunistic(
            visitId: 'visit-1',
            taxonRef: 'Aves|Corvus|corax',
            method: 'acoustic',
          ),
        ),
      ],
      measurements: <Measurement>[
        Measurement(
          name: 'temperature',
          value: '12.5',
          unit: '°C',
          provenance: Provenance(
            method: ProvenanceMethod.visualEstimate,
            calibration: CalibrationState.calibrated,
            instrument: 'thermo-1',
            uncertainty: 0.1,
            observer: 'A. Observer',
            recordedAt: DateTime.utc(2026, 5, 1, 7, 30),
          ),
        ),
      ],
      evidence: <Evidence>[
        Evidence(
          id: 'evidence-1',
          visitId: 'visit-1',
          taxonRef: 'Aves|Turdus|merula',
          kind: EvidenceKind.photo,
          filePath: '/data/evidence/photo.jpg',
          capturedAt: DateTime.utc(2026, 5, 1, 7, 15),
          contentHash: 'hash-photo',
          storageKey: 'media/key-1',
        ),
        Evidence(
          id: 'evidence-2',
          visitId: 'visit-1',
          taxonRef: 'Aves|Parus|major',
          kind: EvidenceKind.audio,
          filePath: '/data/evidence/audio.m4a',
          capturedAt: DateTime.utc(2026, 5, 1, 7, 16),
          contentHash: 'hash-audio',
        ),
      ],
    );

    final payload = buildSubmitPayload(
      aggregate,
      projectId: 'project-1',
      requiredEffortFields: SamplingEffortField.values,
      detectionMethods: const <String>['visual', 'acoustic'],
      submittedAt: DateTime.utc(2026, 5, 1, 9),
    );

    expect(payload, <String, dynamic>{
      'id': 'visit-1',
      'projectId': 'project-1',
      'siteId': 'site-1',
      'surveyPeriodId': 'survey-period-1',
      'protocolVersionId': 'pv1',
      'effort': <String, dynamic>{
        'start': '2026-05-01T07:00:00.000Z',
        'duration': 3600,
        'observers': <String>[],
        'detectionMethods': <String>['visual', 'acoustic'],
      },
      'startedAt': '2026-05-01T07:00:00.000Z',
      'endedAt': '2026-05-01T08:00:00.000Z',
      'submittedAt': '2026-05-01T09:00:00.000Z',
      'detections': <Map<String, dynamic>>[
        <String, dynamic>{
          'taxon': 'Aves|Turdus|merula',
          'detected': true,
          'method': 'visual',
          'count': 3,
          'determinations': <Map<String, dynamic>>[
            <String, dynamic>{
              'taxon': 'Turdus merula',
              'qualifier': 'cf.',
              'specimenCode': 'SP-1',
              'determiner': 'A. Determiner',
              'date': '2026-04-01T00:00:00.000Z',
            },
          ],
        },
        <String, dynamic>{
          'taxon': 'Aves|Parus|major',
          'detected': false,
          'method': 'visual',
        },
        <String, dynamic>{
          'taxon': 'Aves|Corvus|corax',
          'detected': true,
          'method': 'acoustic',
          'opportunistic': true,
        },
      ],
      'measurements': <Map<String, dynamic>>[
        <String, dynamic>{
          'value': '12.5',
          'unit': '°C',
          'provenance': <String, dynamic>{
            'method': 'visualEstimate',
            'calibration': 'calibrated',
            'instrument': 'thermo-1',
            'uncertainty': 0.1,
            'observer': 'A. Observer',
            'recordedAt': '2026-05-01T07:30:00.000Z',
          },
        },
      ],
      'evidence': <Map<String, dynamic>>[
        <String, dynamic>{
          'detectionIndex': 0,
          'kind': 'photo',
          'storageKey': 'media/key-1',
          'sha256': 'hash-photo',
        },
      ],
    });
  });

  test(
    "a Detection with a revised Determination emits the revision's "
    'replacesIndex in the POST body, keeping the append-only chain (INV-009)',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await SiteDao(database).save(_site());
      await _seedPinnedProject(database);
      final visit = await _endedVisit(database);
      const turdus = 'Aves|Turdus|merula';

      await DetectionDao(database).record(
        Detection(
          visitId: visit.id,
          taxonRef: turdus,
          detected: true,
          method: 'visual',
        ),
      );
      final determinations = DeterminationDao(database);
      await determinations.append(
        visitId: visit.id,
        taxonRef: turdus,
        determination: Determination(
          id: 'determination-1',
          taxon: 'Turdus merula',
          determiner: 'First Determiner',
          date: DateTime.utc(2026, 4, 1),
        ),
      );
      await determinations.append(
        visitId: visit.id,
        taxonRef: turdus,
        determination: Determination(
          id: 'determination-2',
          taxon: 'Turdus merula',
          determiner: 'Second Determiner',
          date: DateTime.utc(2026, 5, 1),
          replacesId: 'determination-1',
        ),
      );

      expect(
        (await determinations.forDetection(
          visit.id,
          turdus,
        )).map((determination) => determination.id),
        <String>['determination-1', 'determination-2'],
        reason: 'a revision follows the Determination it replaces (INV-009)',
      );

      final adapter = acceptingAdapter();
      final outbox = _wiredOutbox(database, _syncClient(adapter));

      final result = await outbox.deliver(
        visit,
        clock: () => DateTime.utc(2026, 5, 1, 9),
      );

      expect(result, SyncState.synced);
      final turdusEntry = (_submission(adapter)['detections'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((entry) => entry['taxon'] == turdus);
      final posted = (turdusEntry['determinations'] as List)
          .cast<Map<String, dynamic>>();
      expect(posted, hasLength(2));
      expect(posted[0]['determiner'], 'First Determiner');
      expect(
        posted[0].containsKey('replacesIndex'),
        isFalse,
        reason: 'a first Determination replaces nothing',
      );
      expect(posted[1]['determiner'], 'Second Determiner');
      expect(posted[1]['replacesIndex'], 0);
    },
  );

  test('a revision whose replaced Determination is absent from the submission '
      'emits no replacesIndex rather than a dangling index', () {
    final visit = Visit(
      id: 'visit-1',
      siteId: 'site-1',
      surveyPeriodId: 'survey-period-1',
      protocolVersionId: 'pv1',
      state: VisitState.ended,
      effort: SamplingEffort(
        startedAt: DateTime.utc(2026, 5, 1, 7),
        endedAt: DateTime.utc(2026, 5, 1, 8),
      ),
    );
    final payload = buildSubmitPayload(
      SubmissionAggregate(
        visit: visit,
        detections: <SubmittedDetection>[
          SubmittedDetection(
            detection: const Detection(
              visitId: 'visit-1',
              taxonRef: 'Aves|Turdus|merula',
              detected: true,
              method: 'visual',
            ),
            determinations: <Determination>[
              Determination(
                id: 'determination-2',
                taxon: 'Turdus merula',
                determiner: 'Second Determiner',
                date: DateTime.utc(2026, 5, 1),
                replacesId: 'determination-absent',
              ),
            ],
          ),
        ],
      ),
      projectId: 'project-1',
    );

    final posted =
        ((payload['detections'] as List).single
                as Map<String, dynamic>)['determinations']
            as List;
    expect(
      (posted.single as Map<String, dynamic>).containsKey('replacesIndex'),
      isFalse,
    );
  });

  test(
    'delivering a Visit POSTs its full aggregate loaded from the store',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await SiteDao(database).save(_site());
      await _seedPinnedProject(database);
      final visit = await _endedVisit(database);
      const turdus = 'Aves|Turdus|merula';
      const parus = 'Aves|Parus|major';
      const corvus = 'Aves|Corvus|corax';

      final detections = DetectionDao(database);
      await detections.record(
        Detection(
          visitId: visit.id,
          taxonRef: turdus,
          detected: true,
          method: 'visual',
          count: 3,
        ),
      );
      await detections.record(
        Detection(
          visitId: visit.id,
          taxonRef: parus,
          detected: false,
          method: 'visual',
        ),
      );
      await detections.record(
        Detection.opportunistic(
          visitId: visit.id,
          taxonRef: corvus,
          method: 'acoustic',
        ),
      );
      await DeterminationDao(database).append(
        visitId: visit.id,
        taxonRef: turdus,
        determination: Determination(
          id: 'determination-1',
          taxon: 'Turdus merula',
          qualifier: DeterminationQualifier.cf,
          specimenCode: 'SP-1',
          determiner: 'A. Determiner',
          date: DateTime.utc(2026, 4, 1),
        ),
      );
      await MeasurementDao(database).record(
        visitId: visit.id,
        measurement: Measurement(
          name: 'temperature',
          value: '12.5',
          unit: '°C',
          provenance: Provenance(
            method: ProvenanceMethod.visualEstimate,
            instrument: 'thermo-1',
            recordedAt: DateTime.utc(2026, 5, 1, 7, 30),
          ),
        ),
      );
      final evidence = EvidenceDao(database);
      final uploaded = await evidence.attach(
        visitId: visit.id,
        taxonRef: turdus,
        kind: EvidenceKind.photo,
        filePath: '/data/evidence/photo.jpg',
        contentHash: 'hash-photo',
        capturedAt: DateTime.utc(2026, 5, 1, 7, 15),
      );
      await evidence.markUploaded(uploaded.id, 'media/key-1');
      await evidence.attach(
        visitId: visit.id,
        taxonRef: parus,
        kind: EvidenceKind.audio,
        filePath: '/data/evidence/audio.m4a',
        contentHash: 'hash-audio',
        capturedAt: DateTime.utc(2026, 5, 1, 7, 16),
      );

      final adapter = acceptingAdapter();
      final outbox = _wiredOutbox(database, _syncClient(adapter));

      final result = await outbox.deliver(
        visit,
        clock: () => DateTime.utc(2026, 5, 1, 9),
      );

      expect(result, SyncState.synced);
      final payload = _submission(adapter);
      final payloadDetections = (payload['detections'] as List)
          .cast<Map<String, dynamic>>();
      expect(payloadDetections, hasLength(3));

      final turdusIndex = payloadDetections.indexWhere(
        (entry) => entry['taxon'] == turdus,
      );
      final turdusEntry = payloadDetections[turdusIndex];
      expect(turdusEntry['detected'], isTrue);
      expect(turdusEntry['method'], 'visual');
      expect(turdusEntry['count'], 3);
      final determinations = (turdusEntry['determinations'] as List)
          .cast<Map<String, dynamic>>();
      expect(determinations, hasLength(1));
      expect(determinations.single, <String, dynamic>{
        'taxon': 'Turdus merula',
        'qualifier': 'cf.',
        'specimenCode': 'SP-1',
        'determiner': 'A. Determiner',
        'date': '2026-04-01T00:00:00.000Z',
      });

      final parusEntry = payloadDetections.firstWhere(
        (entry) => entry['taxon'] == parus,
      );
      expect(
        parusEntry,
        containsPair('detected', false),
        reason: 'a non-detection is a Detection with detected = false',
      );
      expect(
        payloadDetections.firstWhere(
          (entry) => entry['taxon'] == corvus,
        )['opportunistic'],
        isTrue,
      );

      final measurements = (payload['measurements'] as List)
          .cast<Map<String, dynamic>>();
      expect(measurements, hasLength(1));
      expect(measurements.single['value'], '12.5');
      expect(measurements.single['unit'], '°C');
      expect(
        (measurements.single['provenance'] as Map)['method'],
        'visualEstimate',
      );

      final manifest = (payload['evidence'] as List)
          .cast<Map<String, dynamic>>();
      expect(manifest, hasLength(1));
      expect(manifest.single, <String, dynamic>{
        'detectionIndex': turdusIndex,
        'kind': 'photo',
        'storageKey': 'media/key-1',
        'sha256': 'hash-photo',
      });
    },
  );

  test('a Visit with an unrecorded target taxon is submitted as it stands and '
      'marked submitted, not blocked (INV-019, INV-022, ADR-0021)', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await SiteDao(database).save(_site());
    await _seedProtocolVersion(database);
    final visit = await _endedVisit(database);
    const turdus = 'Aves|Turdus|merula';
    await DetectionDao(database).record(
      Detection(
        visitId: visit.id,
        taxonRef: turdus,
        detected: true,
        method: 'visual',
      ),
    );

    final adapter = acceptingAdapter();
    final outbox = _wiredOutbox(database, _syncClient(adapter));
    final dao = OutboxDao(database);

    final delivered = await outbox.deliver(
      visit,
      clock: () => DateTime.utc(2026, 5, 1, 9),
    );

    expect(delivered, SyncState.synced);
    expect(_submitCalls(adapter), 1);
    expect(
      (await VisitDao(database).findById(visit.id))!.state,
      VisitState.submitted,
    );
    expect(await dao.syncStateOf(visit.id), SyncState.synced);
  });

  test(
    'a Visit whose Detection has no method is not delivered and stays '
    'retryable, because the sync API rejects a null or blank method',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await SiteDao(database).save(_site());
      final visit = await _endedVisit(database);
      const turdus = 'Aves|Turdus|merula';
      await DetectionDao(database).record(
        Detection(
          visitId: visit.id,
          taxonRef: turdus,
          detected: true,
          method: 'visual',
        ),
      );
      // Simulate a Detection persisted before the client schema recorded
      // methods: the column is nullable with no backfill, so a pre-v12 row
      // reaches the outbox with a null method.
      await database.customStatement(
        'UPDATE detections SET method = NULL WHERE visit_id = ? '
        'AND taxon_ref = ?',
        <Object?>[visit.id, turdus],
      );

      final adapter = acceptingAdapter();
      final outbox = _wiredOutbox(database, _syncClient(adapter));
      final dao = OutboxDao(database);

      final result = await outbox.deliver(
        visit,
        clock: () => DateTime.utc(2026, 5, 1, 9),
      );

      expect(result, SyncState.failed);
      expect(_submitCalls(adapter), 0);
      expect(
        (await VisitDao(database).findById(visit.id))!.state,
        VisitState.ended,
      );
      expect(await dao.syncStateOf(visit.id), SyncState.failed);
      expect(await dao.pendingVisitIds(), contains(visit.id));
    },
  );

  test('a Visit whose Detection has a blank method is likewise refused, since '
      'the sync API rejects an empty method as well as a null one', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await SiteDao(database).save(_site());
    final visit = await _endedVisit(database);
    const turdus = 'Aves|Turdus|merula';
    await DetectionDao(database).record(
      Detection(
        visitId: visit.id,
        taxonRef: turdus,
        detected: true,
        method: 'visual',
      ),
    );
    await database.customStatement(
      'UPDATE detections SET method = ? WHERE visit_id = ? AND taxon_ref = ?',
      <Object?>['   ', visit.id, turdus],
    );

    final adapter = acceptingAdapter();
    final outbox = _wiredOutbox(database, _syncClient(adapter));

    final result = await outbox.deliver(
      visit,
      clock: () => DateTime.utc(2026, 5, 1, 9),
    );

    expect(result, SyncState.failed);
    expect(_submitCalls(adapter), 0);
    expect(
      (await VisitDao(database).findById(visit.id))!.state,
      VisitState.ended,
    );
  });

  test('a unitless Measurement submits an empty unit string, delivering the '
      'Visit and marking it submitted', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await SiteDao(database).save(_site());
    final visit = await _endedVisit(database);
    await MeasurementDao(database).record(
      visitId: visit.id,
      measurement: Measurement(
        name: 'cloudCover',
        value: '30',
        unit: null,
        provenance: Provenance(
          method: ProvenanceMethod.visualEstimate,
          recordedAt: DateTime.utc(2026, 5, 1, 7, 30),
        ),
      ),
    );

    final adapter = acceptingAdapter();
    final outbox = _wiredOutbox(database, _syncClient(adapter));

    final result = await outbox.deliver(
      visit,
      clock: () => DateTime.utc(2026, 5, 1, 9),
    );

    expect(result, SyncState.synced);
    final measurements = (_submission(adapter)['measurements'] as List)
        .cast<Map<String, dynamic>>();
    expect(measurements, hasLength(1));
    expect(measurements.single['unit'], '');
    expect(
      (await VisitDao(database).findById(visit.id))!.state,
      VisitState.submitted,
    );
  });
}
