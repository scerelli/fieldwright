import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/auth/auth_client.dart';
import 'package:ibis/features/projects/protocol_version_screen.dart';
import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/protocol/protocol.dart';
import 'package:ibis/protocol_versions/protocol_versions_client.dart';

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

/// The protocol document the server validates against the shared schema.
Map<String, dynamic> protocolDocumentJson({int version = 1}) =>
    <String, dynamic>{
      'protocolId': 'alpine-birds-2026',
      'version': version,
      'taxonomicScope': <String, dynamic>{
        'taxa': <String>['Aves'],
      },
      'targetList': <Map<String, dynamic>>[
        <String, dynamic>{
          'taxonRef': 'Aves|Turdus|merula',
          'label': 'Common blackbird',
        },
      ],
      'detectionMethods': <Map<String, dynamic>>[
        <String, dynamic>{'id': 'visual', 'label': 'Visual detection'},
      ],
      'requiredEffortFields': <String>['start'],
    };

Map<String, dynamic> protocolVersionJson({
  String id = 'v1',
  String projectId = 'p1',
  int version = 1,
  Map<String, dynamic>? document,
  String? frozenAt,
}) => <String, dynamic>{
  'id': id,
  'projectId': projectId,
  'protocolId': 'alpine-birds-2026',
  'version': version,
  'document': document ?? protocolDocumentJson(version: version),
  'frozenAt': frozenAt,
  'createdAt': '2026-09-30T00:00:00.000Z',
};

/// Routes by path: sign-in sets the auth cookie, `POST /protocol-versions`
/// echoes the document back with the server-assigned version and
/// `POST /protocol-versions/:id/freeze` answers with a frozen version.
FakeHttpAdapter protocolAdapter({
  int assignedVersion = 1,
  String? freezeFrozenAt = '2026-09-30T00:00:00.000Z',
}) => FakeHttpAdapter((options) async {
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
  if (options.path == '/protocol-versions' && options.method == 'POST') {
    final data = (options.data! as Map).cast<String, dynamic>();
    final document = (data['document']! as Map).cast<String, dynamic>();
    document['version'] = assignedVersion;
    return jsonResponse(
      protocolVersionJson(
        projectId: data['projectId'] as String,
        version: assignedVersion,
        document: document,
      ),
      statusCode: 201,
    );
  }
  if (options.path.startsWith('/protocol-versions/') &&
      options.path.endsWith('/freeze')) {
    return jsonResponse(protocolVersionJson(frozenAt: freezeFrozenAt));
  }
  return jsonResponse(<String, dynamic>{
    'message': 'not found',
  }, statusCode: 404);
});

AuthClient authWith(FakeHttpAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
  dio.httpClientAdapter = adapter;
  return AuthClient(baseUrl: 'http://test.local', dio: dio);
}

ProtocolVersionsClient protocolVersionsWith(
  FakeHttpAdapter adapter,
  AuthClient auth,
) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
  dio.httpClientAdapter = adapter;
  return ProtocolVersionsClient(
    baseUrl: 'http://test.local',
    auth: auth,
    dio: dio,
  );
}

Future<AuthClient> signedInAuth(FakeHttpAdapter adapter) async {
  final auth = authWith(adapter);
  await auth.signIn(email: 'ada@example.com', password: 'correct');
  return auth;
}

RequestOptions createRequest(FakeHttpAdapter adapter) => adapter.requests
    .firstWhere((request) => request.path == '/protocol-versions');

void main() {
  group('ProtocolVersionsClient', () {
    test(
      'create posts the project and document with the auth cookie',
      () async {
        final adapter = protocolAdapter();
        final auth = await signedInAuth(adapter);
        final client = protocolVersionsWith(adapter, auth);

        final version = await client.create(
          projectId: 'p1',
          document: const ProtocolDocument(
            protocolId: 'alpine-birds-2026',
            version: 1,
            taxonomicScope: TaxonomicScope(taxa: <String>['Aves']),
            detectionMethods: <DetectionMethod>[
              DetectionMethod(id: 'visual', label: 'Visual detection'),
            ],
            requiredEffortFields: <SamplingEffortField>[
              SamplingEffortField.start,
            ],
          ),
        );

        final request = createRequest(adapter);
        expect(request.method, 'POST');
        expect(request.headers['cookie'], contains('auth-token-123'));
        final data = request.data as Map<String, dynamic>;
        expect(data['projectId'], 'p1');
        expect(
          (data['document'] as Map<String, dynamic>)['protocolId'],
          'alpine-birds-2026',
        );
        expect(version.id, 'v1');
        expect(version.projectId, 'p1');
      },
    );

    test('create adopts the server-assigned version', () async {
      final adapter = protocolAdapter(assignedVersion: 2);
      final auth = await signedInAuth(adapter);
      final client = protocolVersionsWith(adapter, auth);

      final version = await client.create(
        projectId: 'p1',
        document: const ProtocolDocument(
          protocolId: 'alpine-birds-2026',
          version: 1,
          taxonomicScope: TaxonomicScope(taxa: <String>['Aves']),
          detectionMethods: <DetectionMethod>[
            DetectionMethod(id: 'visual', label: 'Visual detection'),
          ],
          requiredEffortFields: <SamplingEffortField>[
            SamplingEffortField.start,
          ],
        ),
      );

      expect(version.document.version, 2);
      expect(version.isFrozen, isFalse);
    });

    test('freeze posts to the version and reports it frozen', () async {
      final adapter = protocolAdapter();
      final auth = await signedInAuth(adapter);
      final client = protocolVersionsWith(adapter, auth);

      final version = await client.freeze('v1');

      final request = adapter.requests.last;
      expect(request.method, 'POST');
      expect(request.path, '/protocol-versions/v1/freeze');
      expect(request.headers['cookie'], contains('auth-token-123'));
      expect(version.isFrozen, isTrue);
      expect(version.frozenAt, isNotNull);
    });

    test('a rejected request raises a ProtocolVersionsException', () async {
      final adapter = FakeHttpAdapter((options) async {
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
        return jsonResponse(<String, dynamic>{
          'message': 'protocol document does not match the protocol schema',
        }, statusCode: 400);
      });
      final auth = await signedInAuth(adapter);
      final client = protocolVersionsWith(adapter, auth);

      await expectLater(
        client.create(
          projectId: 'p1',
          document: const ProtocolDocument(
            protocolId: 'alpine-birds-2026',
            version: 1,
            taxonomicScope: TaxonomicScope(taxa: <String>['Aves']),
            detectionMethods: <DetectionMethod>[
              DetectionMethod(id: 'visual', label: 'Visual detection'),
            ],
            requiredEffortFields: <SamplingEffortField>[
              SamplingEffortField.start,
            ],
          ),
        ),
        throwsA(isA<ProtocolVersionsException>()),
      );
    });
  });

  group('protocol-version surface', () {
    testWidgets(
      'a creator can define a protocol version with the required fields',
      (tester) async {
        final adapter = protocolAdapter();
        late final AuthClient auth;
        await tester.runAsync(() async {
          auth = await signedInAuth(adapter);
        });
        final client = protocolVersionsWith(adapter, auth);
        await pumpScreen(tester, client: client);

        await tester.enterText(
          find.byKey(const Key('protocol_id')),
          'alpine-birds-2026',
        );
        await tester.enterText(
          find.byKey(const Key('taxonomic_scope')),
          'Aves',
        );
        await tester.enterText(
          find.byKey(const Key('target_list')),
          'Aves|Turdus|merula = Common blackbird\nAves|Erithacus|rubecula',
        );
        await tester.enterText(
          find.byKey(const Key('detection_methods')),
          'visual = Visual detection\nacoustic = Acoustic detection',
        );
        await tester.enterText(
          find.byKey(const Key('visit_covariates')),
          'windSpeed:number:m/s\nweather:enum:clear,cloudy,rain',
        );
        await tester.enterText(
          find.byKey(const Key('site_covariates')),
          'habitat:text',
        );
        await tester.tap(find.byKey(const Key('effort_start')));
        await tester.pump();
        await save(tester);

        final request = createRequest(adapter);
        expect(request.headers['cookie'], contains('auth-token-123'));
        expect(request.data, <String, dynamic>{
          'projectId': 'p1',
          'document': <String, dynamic>{
            'protocolId': 'alpine-birds-2026',
            'version': 1,
            'taxonomicScope': <String, dynamic>{
              'taxa': <String>['Aves'],
            },
            'targetList': <Map<String, dynamic>>[
              <String, dynamic>{
                'taxonRef': 'Aves|Turdus|merula',
                'label': 'Common blackbird',
              },
              <String, dynamic>{'taxonRef': 'Aves|Erithacus|rubecula'},
            ],
            'detectionMethods': <Map<String, dynamic>>[
              <String, dynamic>{'id': 'visual', 'label': 'Visual detection'},
              <String, dynamic>{
                'id': 'acoustic',
                'label': 'Acoustic detection',
              },
            ],
            'requiredEffortFields': <String>['start'],
            'visitCovariates': <Map<String, dynamic>>[
              <String, dynamic>{
                'name': 'windSpeed',
                'type': 'number',
                'unit': 'm/s',
              },
              <String, dynamic>{
                'name': 'weather',
                'type': 'enum',
                'options': <String>['clear', 'cloudy', 'rain'],
              },
            ],
            'siteCovariates': <Map<String, dynamic>>[
              <String, dynamic>{'name': 'habitat', 'type': 'text'},
            ],
          },
        });
      },
    );

    testWidgets('complete-list mode omits the target list', (tester) async {
      final adapter = protocolAdapter();
      late final AuthClient auth;
      await tester.runAsync(() async {
        auth = await signedInAuth(adapter);
      });
      final client = protocolVersionsWith(adapter, auth);
      await pumpScreen(tester, client: client);

      await tester.enterText(
        find.byKey(const Key('protocol_id')),
        'alpine-birds-2026',
      );
      await tester.enterText(find.byKey(const Key('taxonomic_scope')), 'Aves');
      await tester.tap(find.byKey(const Key('complete_list_mode')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('detection_methods')),
        'visual = Visual detection',
      );
      await tester.tap(find.byKey(const Key('effort_start')));
      await tester.pump();
      await save(tester);

      final data = createRequest(adapter).data as Map<String, dynamic>;
      final document = (data['document']! as Map).cast<String, dynamic>();
      expect(document.containsKey('targetList'), isFalse);
    });

    testWidgets(
      'a frozen version is read-only with an option to create a new version',
      (tester) async {
        final adapter = protocolAdapter();
        late final AuthClient auth;
        await tester.runAsync(() async {
          auth = await signedInAuth(adapter);
        });
        final client = protocolVersionsWith(adapter, auth);
        await pumpScreen(tester, client: client, version: frozenVersion());

        expect(find.byKey(const Key('frozen_badge')), findsOneWidget);
        expect(find.byKey(const Key('protocol_id')), findsNothing);
        expect(find.byKey(const Key('save_protocol_version')), findsNothing);
        expect(
          find.byKey(const Key('protocol_version_readonly')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('create_new_version')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('protocol_id')), findsOneWidget);
        final controller = tester
            .widget<TextField>(find.byKey(const Key('protocol_id')))
            .controller!;
        expect(controller.text, 'alpine-birds-2026');
        expect(find.byKey(const Key('create_new_version')), findsNothing);
      },
    );

    testWidgets('the form validates required fields before sending', (
      tester,
    ) async {
      final adapter = protocolAdapter();
      late final AuthClient auth;
      await tester.runAsync(() async {
        auth = await signedInAuth(adapter);
      });
      final client = protocolVersionsWith(adapter, auth);
      await pumpScreen(tester, client: client);

      await tester.enterText(
        find.byKey(const Key('protocol_id')),
        'alpine-birds-2026',
      );
      await tester.tap(find.byKey(const Key('save_protocol_version')));
      await tester.pump();

      expect(find.byKey(const Key('protocol_version_error')), findsOneWidget);
      expect(
        adapter.requests.where(
          (request) => request.path == '/protocol-versions',
        ),
        isEmpty,
      );
    });

    testWidgets('an invalid covariate is rejected before sending', (
      tester,
    ) async {
      final adapter = protocolAdapter();
      late final AuthClient auth;
      await tester.runAsync(() async {
        auth = await signedInAuth(adapter);
      });
      final client = protocolVersionsWith(adapter, auth);
      await pumpScreen(tester, client: client);

      await tester.enterText(
        find.byKey(const Key('protocol_id')),
        'alpine-birds-2026',
      );
      await tester.enterText(find.byKey(const Key('taxonomic_scope')), 'Aves');
      await tester.enterText(
        find.byKey(const Key('target_list')),
        'Aves|Turdus|merula',
      );
      await tester.enterText(
        find.byKey(const Key('detection_methods')),
        'visual = Visual detection',
      );
      await tester.enterText(
        find.byKey(const Key('visit_covariates')),
        'windSpeed',
      );
      await tester.tap(find.byKey(const Key('effort_start')));
      await tester.pump();
      await save(tester);

      expect(find.byKey(const Key('protocol_version_error')), findsOneWidget);
      expect(
        adapter.requests.where(
          (request) => request.path == '/protocol-versions',
        ),
        isEmpty,
      );
    });
  });
}

ProtocolVersion frozenVersion() => ProtocolVersion(
  id: 'v1',
  projectId: 'p1',
  frozenAt: DateTime.utc(2026, 9, 30),
  document: const ProtocolDocument(
    protocolId: 'alpine-birds-2026',
    version: 1,
    taxonomicScope: TaxonomicScope(taxa: <String>['Aves']),
    detectionMethods: <DetectionMethod>[
      DetectionMethod(id: 'visual', label: 'Visual detection'),
    ],
    requiredEffortFields: <SamplingEffortField>[SamplingEffortField.start],
    targetList: <TargetTaxon>[
      TargetTaxon(taxonRef: 'Aves|Turdus|merula', label: 'Common blackbird'),
    ],
  ),
);

Future<void> pumpScreen(
  WidgetTester tester, {
  required ProtocolVersionsClient client,
  ProtocolVersion? version,
}) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ProtocolVersionScreen(
        client: client,
        projectId: 'p1',
        version: version,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> save(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('save_protocol_version')));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}
