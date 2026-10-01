import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ibis/auth/auth_client.dart';
import 'package:ibis/features/visits/evidence.dart';
import 'package:ibis/outbox/media_client.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/evidence_dao.dart';
import 'package:ibis/store/visit_dao.dart';

/// Fakes the HTTP layer: no request ever leaves the process. It drains the
/// request body so a handler can inspect the exact bytes a PUT sent.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this._handle);

  final Future<ResponseBody> Function(RequestOptions options, Uint8List body)
  _handle;
  final List<RequestOptions> requests = <RequestOptions>[];
  final List<Uint8List> bodies = <Uint8List>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final builder = BytesBuilder(copy: false);
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        builder.add(chunk);
      }
    }
    final body = builder.takeBytes();
    requests.add(options);
    bodies.add(body);
    return _handle(options, body);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(
  Object body, {
  int statusCode = 200,
  Map<String, List<String>> headers = const <String, List<String>>{},
}) => ResponseBody.fromString(
  jsonEncode(body),
  statusCode,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    ...headers,
  },
);

// The Better Auth cookie identifies the request; it is not the domain Visit.
const String authCookie = 'better-auth.session_token=auth-token-123'; // glossary:allow Better Auth session cookie, not the domain Visit

const String mediaPath = '/api/v1/media';

/// The fake media API: sign-in sets the auth cookie; an upload answers with the
/// stored key and the SHA-256 the server computed from the received bytes
/// (overridable via [sha256] to simulate a mismatch), plus a presigned
/// [uploadUrl]/[uploadHeaders] when the backend stores out of band.
class FakeMediaApi {
  FakeMediaApi({
    this.storageKey = 'media/abc',
    this.sha256,
    this.uploadUrl,
    this.uploadHeaders,
    this.failUpload = false,
    this.failStatus = 503,
    this.failPut = false,
    this.failPutStatus = 500,
    this.malformedResponse = false,
  });

  final String storageKey;
  final String? sha256;
  final String? uploadUrl;
  final Map<String, String>? uploadHeaders;
  bool failUpload;
  int failStatus;
  bool failPut;
  int failPutStatus;
  bool malformedResponse;
  late final FakeHttpAdapter adapter = FakeHttpAdapter((
    options,
    body,
  ) async {
    if (options.path == '/api/auth/sign-in/email') {
      return jsonResponse(
        <String, dynamic>{
          'user': <String, dynamic>{
            'id': 'u1',
            'email': 'ada@example.com',
            'name': 'Ada Lovelace',
          },
        },
        headers: <String, List<String>>{
          'set-cookie': <String>['$authCookie; Path=/; HttpOnly'],
        },
      );
    }
    if (options.path == mediaPath && options.method == 'POST') {
      if (failUpload) {
        return jsonResponse(<String, dynamic>{
          'message': 'storage unavailable',
        }, statusCode: failStatus);
      }
      if (malformedResponse) {
        return jsonResponse(<String, dynamic>{});
      }
      return jsonResponse(<String, dynamic>{
        'storageKey': storageKey,
        'sha256': sha256 ?? sha256Hex(body),
        if (uploadUrl != null) 'uploadUrl': uploadUrl,
        if (uploadHeaders != null) 'uploadHeaders': uploadHeaders,
      });
    }
    if (options.method == 'PUT') {
      if (failPut) {
        return jsonResponse(<String, dynamic>{
          'message': 'put failed',
        }, statusCode: failPutStatus);
      }
      return ResponseBody.fromString('', 200);
    }
    return jsonResponse(<String, dynamic>{
      'message': 'not found',
    }, statusCode: 404);
  });
}

String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

Future<AuthClient> signedInAuth(FakeHttpAdapter adapter) async {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
  dio.httpClientAdapter = adapter;
  final auth = AuthClient(baseUrl: 'http://test.local', dio: dio);
  await auth.signIn(email: 'ada@example.com', password: 'correct');
  return auth;
}

MediaClient mediaClientWith(FakeHttpAdapter adapter, AuthClient auth) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
  dio.httpClientAdapter = adapter;
  return MediaClient(baseUrl: 'http://test.local', auth: auth, dio: dio);
}

void main() {
  const String visitId = 'visit-1';
  const String taxonRef = 'Aves|Turdus|merula';

  group('MediaClient', () {
    late Directory directory;
    late AppDatabase database;
    late EvidenceDao dao;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('ibis_evidence_upload');
      database = AppDatabase(NativeDatabase.memory());
      dao = EvidenceDao(database);
    });

    tearDown(() async {
      await database.close();
      directory.deleteSync(recursive: true);
    });

    File writeMedia(List<int> bytes, [String name = 'photo.jpg']) =>
        File('${directory.path}/$name')..writeAsBytesSync(bytes);


    test(
      'uploads Evidence through POST /api/v1/media and persists the returned storageKey',
      () async {
        final bytes = <int>[1, 2, 3, 4, 5];
        final file = writeMedia(bytes);
        final contentHash = sha256.convert(bytes).toString();
        final api = FakeMediaApi(storageKey: 'media/abc', sha256: contentHash);
        final auth = await signedInAuth(api.adapter);
        final client = mediaClientWith(api.adapter, auth);

        final evidence = await dao.attach(
          visitId: visitId,
          taxonRef: taxonRef,
          kind: EvidenceKind.photo,
          filePath: file.path,
          contentHash: contentHash,
          capturedAt: DateTime.utc(2026, 5, 1, 8, 0),
        );

        await client.uploadEvidence(evidence, dao);

        final request = api.adapter.requests.firstWhere(
          (request) => request.path == mediaPath,
        );
        expect(request.method, 'POST');
        expect(request.headers['cookie'], contains('auth-token-123'));
        expect(
          request.headers[Headers.contentTypeHeader],
          'application/octet-stream',
        );

        final stored = await dao.findById(evidence.id);
        expect(stored, isNotNull);
        expect(stored!.storageKey, 'media/abc');
      },
    );

    test(
      "the manifest carries the uploaded file's content hash as its sha256",
      () async {
        final bytes = <int>[9, 8, 7];
        final file = writeMedia(bytes);
        final contentHash = sha256.convert(bytes).toString();
        // The server computes the hash from the bytes it received; the fake is
        // not told it, so a match proves the bytes actually travelled.
        final api = FakeMediaApi(storageKey: 'media/xyz');
        final auth = await signedInAuth(api.adapter);
        final client = mediaClientWith(api.adapter, auth);

        final evidence = await dao.attach(
          visitId: visitId,
          taxonRef: taxonRef,
          kind: EvidenceKind.audio,
          filePath: file.path,
          contentHash: contentHash,
          capturedAt: DateTime.utc(2026, 5, 1, 8, 0),
        );

        await client.uploadEvidence(evidence, dao);

        final manifest = evidenceManifest(await dao.forVisit(visitId));
        expect(manifest, hasLength(1));
        expect(manifest.single.storageKey, 'media/xyz');
        expect(manifest.single.sha256, contentHash);
      },
    );

    test('a failed upload keeps the local file and can be retried', () async {
      final bytes = <int>[4, 4, 4];
      final file = writeMedia(bytes);
      final contentHash = sha256.convert(bytes).toString();
      final api = FakeMediaApi(storageKey: 'media/retry', sha256: contentHash);
      final auth = await signedInAuth(api.adapter);
      final client = mediaClientWith(api.adapter, auth);

      final evidence = await dao.attach(
        visitId: visitId,
        taxonRef: taxonRef,
        kind: EvidenceKind.photo,
        filePath: file.path,
        contentHash: contentHash,
        capturedAt: DateTime.utc(2026, 5, 1, 8, 0),
      );

      api.failUpload = true;
      await expectLater(
        client.uploadEvidence(evidence, dao),
        throwsA(isA<MediaUnavailable>()),
      );

      expect(file.existsSync(), isTrue);
      expect((await dao.findById(evidence.id))!.storageKey, isNull);
      expect(evidenceManifest(await dao.forVisit(visitId)), isEmpty);

      api.failUpload = false;
      await client.uploadEvidence(evidence, dao);

      expect(file.existsSync(), isTrue);
      expect((await dao.findById(evidence.id))!.storageKey, 'media/retry');
    });

    test(
      'Evidence that has never been uploaded has no storageKey and is excluded from the manifest',
      () async {
        final uploadFile = writeMedia(<int>[1], 'a.jpg');
        final pendingFile = writeMedia(<int>[2], 'b.jpg');
        final uploadHash = sha256.convert(<int>[1]).toString();
        final api = FakeMediaApi(storageKey: 'media/one', sha256: uploadHash);
        final auth = await signedInAuth(api.adapter);
        final client = mediaClientWith(api.adapter, auth);

        final uploaded = await dao.attach(
          visitId: visitId,
          taxonRef: taxonRef,
          kind: EvidenceKind.photo,
          filePath: uploadFile.path,
          contentHash: uploadHash,
          capturedAt: DateTime.utc(2026, 5, 1, 8, 0),
        );
        final neverUploaded = await dao.attach(
          visitId: visitId,
          taxonRef: 'Aves|Erithacus|rubecula',
          kind: EvidenceKind.photo,
          filePath: pendingFile.path,
          contentHash: 'pending-hash',
          capturedAt: DateTime.utc(2026, 5, 1, 8, 5),
        );

        await client.uploadEvidence(uploaded, dao);

        expect((await dao.findById(neverUploaded.id))!.storageKey, isNull);
        final manifest = evidenceManifest(await dao.forVisit(visitId));
        expect(manifest, hasLength(1));
        expect(manifest.single.storageKey, 'media/one');
        expect(
          manifest.any((entry) => entry.sha256 == 'pending-hash'),
          isFalse,
          reason: 'the never-uploaded Evidence must not be referenced',
        );
      },
    );

    test(
      'PUTs the bytes to the presigned uploadUrl with the signed headers, then persists the key',
      () async {
        final bytes = <int>[10, 20, 30, 40];
        final file = writeMedia(bytes);
        final contentHash = sha256.convert(bytes).toString();
        const String uploadUrl = 'https://s3.test.local/bucket/object';
        const Map<String, String> uploadHeaders = <String, String>{
          'If-None-Match': '*',
          'x-amz-checksum-sha256': 'c29tZS1jaGVja3N1bQ==',
        };
        final api = FakeMediaApi(
          storageKey: contentHash,
          uploadUrl: uploadUrl,
          uploadHeaders: uploadHeaders,
        );
        final auth = await signedInAuth(api.adapter);
        final client = mediaClientWith(api.adapter, auth);

        final evidence = await dao.attach(
          visitId: visitId,
          taxonRef: taxonRef,
          kind: EvidenceKind.photo,
          filePath: file.path,
          contentHash: contentHash,
          capturedAt: DateTime.utc(2026, 5, 1, 8, 0),
        );

        await client.uploadEvidence(evidence, dao);

        final putIndex = api.adapter.requests.indexWhere(
          (request) => request.method == 'PUT',
        );
        expect(putIndex, isNot(-1), reason: 'expected a presigned PUT');
        final put = api.adapter.requests[putIndex];
        expect(put.uri.toString(), uploadUrl);
        expect(put.headers['If-None-Match'], '*');
        expect(put.headers['x-amz-checksum-sha256'], 'c29tZS1jaGVja3N1bQ==');
        expect(api.adapter.bodies[putIndex], orderedEquals(bytes));
        expect((await dao.findById(evidence.id))!.storageKey, contentHash);
      },
    );

    test(
      'does not PUT when the server stored the bytes itself (no uploadUrl)',
      () async {
        final bytes = <int>[3, 1, 4, 1, 5];
        final file = writeMedia(bytes);
        final contentHash = sha256.convert(bytes).toString();
        final api = FakeMediaApi(storageKey: 'media/volume');
        final auth = await signedInAuth(api.adapter);
        final client = mediaClientWith(api.adapter, auth);

        final evidence = await dao.attach(
          visitId: visitId,
          taxonRef: taxonRef,
          kind: EvidenceKind.photo,
          filePath: file.path,
          contentHash: contentHash,
          capturedAt: DateTime.utc(2026, 5, 1, 8, 0),
        );

        await client.uploadEvidence(evidence, dao);

        expect(
          api.adapter.requests.where((request) => request.method == 'PUT'),
          isEmpty,
        );
        expect((await dao.findById(evidence.id))!.storageKey, 'media/volume');
      },
    );

    test(
      'rejects the upload when the server sha256 does not match the local content hash',
      () async {
        final bytes = <int>[5, 5, 5];
        final file = writeMedia(bytes);
        final contentHash = sha256.convert(bytes).toString();
        final api = FakeMediaApi(storageKey: 'media/bad', sha256: 'deadbeef');
        final auth = await signedInAuth(api.adapter);
        final client = mediaClientWith(api.adapter, auth);

        final evidence = await dao.attach(
          visitId: visitId,
          taxonRef: taxonRef,
          kind: EvidenceKind.photo,
          filePath: file.path,
          contentHash: contentHash,
          capturedAt: DateTime.utc(2026, 5, 1, 8, 0),
        );

        await expectLater(
          client.uploadEvidence(evidence, dao),
          throwsA(isA<MediaRejected>()),
        );

        expect((await dao.findById(evidence.id))!.storageKey, isNull);
        expect(evidenceManifest(await dao.forVisit(visitId)), isEmpty);
      },
    );

    test(
      'a failed presigned PUT is retryable and does not persist the key',
      () async {
        final bytes = <int>[7, 7, 7];
        final file = writeMedia(bytes);
        final contentHash = sha256.convert(bytes).toString();
        final api = FakeMediaApi(
          storageKey: contentHash,
          uploadUrl: 'https://s3.test.local/fail',
          uploadHeaders: <String, String>{'If-None-Match': '*'},
          failPut: true,
        );
        final auth = await signedInAuth(api.adapter);
        final client = mediaClientWith(api.adapter, auth);

        final evidence = await dao.attach(
          visitId: visitId,
          taxonRef: taxonRef,
          kind: EvidenceKind.photo,
          filePath: file.path,
          contentHash: contentHash,
          capturedAt: DateTime.utc(2026, 5, 1, 8, 0),
        );

        await expectLater(
          client.uploadEvidence(evidence, dao),
          throwsA(isA<MediaUnavailable>()),
        );

        expect(file.existsSync(), isTrue);
        expect((await dao.findById(evidence.id))!.storageKey, isNull);

        api.failPut = false;
        await client.uploadEvidence(evidence, dao);

        expect((await dao.findById(evidence.id))!.storageKey, contentHash);
      },
    );

    test(
      'a 412 presigned PUT means the object already exists and the Evidence is persisted',
      () async {
        final bytes = <int>[8, 8, 8];
        final file = writeMedia(bytes);
        final contentHash = sha256.convert(bytes).toString();
        final api = FakeMediaApi(
          storageKey: contentHash,
          uploadUrl: 'https://s3.test.local/already-stored',
          uploadHeaders: <String, String>{'If-None-Match': '*'},
          failPut: true,
          failPutStatus: 412,
        );
        final auth = await signedInAuth(api.adapter);
        final client = mediaClientWith(api.adapter, auth);

        final evidence = await dao.attach(
          visitId: visitId,
          taxonRef: taxonRef,
          kind: EvidenceKind.photo,
          filePath: file.path,
          contentHash: contentHash,
          capturedAt: DateTime.utc(2026, 5, 1, 8, 0),
        );

        await client.uploadEvidence(evidence, dao);

        expect((await dao.findById(evidence.id))!.storageKey, contentHash);
      },
    );

    test(
      'a 403 presigned PUT is retryable, persists no key, and a full retry succeeds',
      () async {
        final bytes = <int>[11, 11, 11];
        final file = writeMedia(bytes);
        final contentHash = sha256.convert(bytes).toString();
        final api = FakeMediaApi(
          storageKey: contentHash,
          uploadUrl: 'https://s3.test.local/expired',
          uploadHeaders: <String, String>{'If-None-Match': '*'},
          failPut: true,
          failPutStatus: 403,
        );
        final auth = await signedInAuth(api.adapter);
        final client = mediaClientWith(api.adapter, auth);

        final evidence = await dao.attach(
          visitId: visitId,
          taxonRef: taxonRef,
          kind: EvidenceKind.photo,
          filePath: file.path,
          contentHash: contentHash,
          capturedAt: DateTime.utc(2026, 5, 1, 8, 0),
        );

        await expectLater(
          client.uploadEvidence(evidence, dao),
          throwsA(
            allOf(
              isA<MediaUnavailable>(),
              isNot(isA<MediaNotAuthenticated>()),
            ),
          ),
        );

        expect(file.existsSync(), isTrue);
        expect((await dao.findById(evidence.id))!.storageKey, isNull);

        api.failPut = false;
        await client.uploadEvidence(evidence, dao);

        expect((await dao.findById(evidence.id))!.storageKey, contentHash);
      },
    );

    test(
      'a 401 upload raises MediaNotAuthenticated and persists nothing',
      () async {
        final bytes = <int>[2, 2, 2];
        final file = writeMedia(bytes);
        final contentHash = sha256.convert(bytes).toString();
        final api = FakeMediaApi()
          ..failUpload = true
          ..failStatus = 401;
        final auth = await signedInAuth(api.adapter);
        final client = mediaClientWith(api.adapter, auth);

        final evidence = await dao.attach(
          visitId: visitId,
          taxonRef: taxonRef,
          kind: EvidenceKind.photo,
          filePath: file.path,
          contentHash: contentHash,
          capturedAt: DateTime.utc(2026, 5, 1, 8, 0),
        );

        await expectLater(
          client.uploadEvidence(evidence, dao),
          throwsA(isA<MediaNotAuthenticated>()),
        );
        expect((await dao.findById(evidence.id))!.storageKey, isNull);
      },
    );

    test('a non-auth 4xx upload is a non-retryable rejection', () async {
      final bytes = <int>[6, 6, 6];
      final file = writeMedia(bytes);
      final contentHash = sha256.convert(bytes).toString();
      final api = FakeMediaApi()
        ..failUpload = true
        ..failStatus = 422;
      final auth = await signedInAuth(api.adapter);
      final client = mediaClientWith(api.adapter, auth);

      final evidence = await dao.attach(
        visitId: visitId,
        taxonRef: taxonRef,
        kind: EvidenceKind.photo,
        filePath: file.path,
        contentHash: contentHash,
        capturedAt: DateTime.utc(2026, 5, 1, 8, 0),
      );

      await expectLater(
        client.uploadEvidence(evidence, dao),
        throwsA(isA<MediaRejected>()),
      );
      expect((await dao.findById(evidence.id))!.storageKey, isNull);
    });

    test(
      'a missing local file surfaces as retryable MediaUnavailable',
      () async {
        final api = FakeMediaApi();
        final auth = await signedInAuth(api.adapter);
        final client = mediaClientWith(api.adapter, auth);

        final evidence = await dao.attach(
          visitId: visitId,
          taxonRef: taxonRef,
          kind: EvidenceKind.photo,
          filePath: '${directory.path}/missing.jpg',
          contentHash: 'missing-hash',
          capturedAt: DateTime.utc(2026, 5, 1, 8, 0),
        );

        await expectLater(
          client.uploadEvidence(evidence, dao),
          throwsA(isA<MediaUnavailable>()),
        );
        expect((await dao.findById(evidence.id))!.storageKey, isNull);
      },
    );

    test(
      'a malformed upload response surfaces as retryable MediaUnavailable',
      () async {
        final file = writeMedia(<int>[1]);
        final api = FakeMediaApi(malformedResponse: true);
        final auth = await signedInAuth(api.adapter);
        final client = mediaClientWith(api.adapter, auth);

        final evidence = await dao.attach(
          visitId: visitId,
          taxonRef: taxonRef,
          kind: EvidenceKind.photo,
          filePath: file.path,
          contentHash: 'anything',
          capturedAt: DateTime.utc(2026, 5, 1, 8, 0),
        );

        await expectLater(
          client.uploadEvidence(evidence, dao),
          throwsA(isA<MediaUnavailable>()),
        );
        expect((await dao.findById(evidence.id))!.storageKey, isNull);
      },
    );

    test(
      'a second markUploaded does not overwrite an existing storageKey',
      () async {
        final evidence = await dao.attach(
          visitId: visitId,
          taxonRef: taxonRef,
          kind: EvidenceKind.photo,
          filePath: '${directory.path}/photo.jpg',
          contentHash: 'hash',
          capturedAt: DateTime.utc(2026, 5, 1, 8, 0),
        );

        await dao.markUploaded(evidence.id, 'media/first');
        await dao.markUploaded(evidence.id, 'media/second');

        expect((await dao.findById(evidence.id))!.storageKey, 'media/first');
      },
    );

    test(
      'markUploaded refuses to mutate Evidence whose Visit is submitted (INV-001)',
      () async {
        final visits = VisitDao(database);
        final visit = await visits.startVisit(
          siteId: 'site-1',
          surveyPeriodId: 'survey-1',
          protocolVersionId: 'protocol-1',
          id: visitId,
        );
        await visits.endVisit(visit);
        await visits.markSubmitted(visitId);

        final evidence = await dao.attach(
          visitId: visitId,
          taxonRef: taxonRef,
          kind: EvidenceKind.photo,
          filePath: '${directory.path}/photo.jpg',
          contentHash: 'hash',
          capturedAt: DateTime.utc(2026, 5, 1, 8, 0),
        );

        await expectLater(
          dao.markUploaded(evidence.id, 'media/late'),
          throwsA(isA<StateError>()),
        );

        expect((await dao.findById(evidence.id))!.storageKey, isNull);
      },
    );
  });

  group('migration', () {
    test(
      'migrates a version 12 client schema to version 13 adding storageKey',
      () async {
        final legacy = AppDatabase(
          NativeDatabase.memory(
            setup: (raw) {
              // A v12 client already carries the Visit table (added in v4);
              // the guard added to markUploaded reads it.
              raw.execute('''
CREATE TABLE visits (
  id TEXT NOT NULL,
  site_id TEXT NOT NULL,
  survey_period_id TEXT NOT NULL,
  protocol_version_id TEXT NOT NULL,
  state TEXT NOT NULL,
  effort_started_at INTEGER NOT NULL,
  effort_ended_at INTEGER NULL,
  PRIMARY KEY (id)
);
''');
              raw.execute('''
CREATE TABLE evidences (
  id TEXT NOT NULL,
  visit_id TEXT NOT NULL,
  taxon_ref TEXT NOT NULL,
  kind TEXT NOT NULL,
  file_path TEXT NOT NULL,
  captured_at INTEGER NOT NULL,
  content_hash TEXT NOT NULL,
  PRIMARY KEY (id)
);
''');
              raw.execute(
                "INSERT INTO evidences (id, visit_id, taxon_ref, kind, file_path, captured_at, content_hash) "
                "VALUES ('evidence-1', 'visit-1', 'Aves|Turdus|merula', 'photo', '/data/evidence/photo.jpg', 1767225600, 'deadbeef');",
              );
              raw.execute('PRAGMA user_version = 12');
            },
          ),
        );
        addTearDown(legacy.close);

        final version = await legacy
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(version.data['user_version'], 13);

        final columns = await legacy
            .customSelect('PRAGMA table_info(evidences)')
            .get();
        expect(
          columns.map((row) => row.data['name']),
          contains('storage_key'),
        );

        final legacyDao = EvidenceDao(legacy);
        final existing = await legacyDao.findById('evidence-1');
        expect(existing, isNotNull);
        expect(existing!.storageKey, isNull);

        await legacyDao.markUploaded('evidence-1', 'media/migrated');
        expect(
          (await legacyDao.findById('evidence-1'))!.storageKey,
          'media/migrated',
        );
      },
    );
  });
}
