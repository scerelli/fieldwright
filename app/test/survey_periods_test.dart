import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/auth/auth_client.dart';
import 'package:ibis/features/projects/survey_periods_screen.dart';
import 'package:ibis/l10n/app_localizations.dart';
import 'package:ibis/projects/survey_periods_client.dart';

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

Map<String, dynamic> surveyPeriodJson({
  String id = 'sp1',
  String projectId = 'p1',
  String name = 'Spring survey',
  String startDate = '2026-03-01',
  String endDate = '2026-05-31',
}) => <String, dynamic>{
  'id': id,
  'projectId': projectId,
  'name': name,
  'startDate': startDate,
  'endDate': endDate,
};

/// Routes by path: sign-in sets the auth cookie, `GET /survey-periods`
/// answers with the given Survey periods for the requested Project, and
/// `POST /survey-periods` echoes the stored Survey period.
FakeHttpAdapter surveyPeriodsAdapter({
  List<Map<String, dynamic>> periods = const <Map<String, dynamic>>[],
  int listStatus = 200,
  int createStatus = 201,
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
  if (options.path == '/survey-periods' && options.method == 'GET') {
    if (listStatus != 200) {
      return jsonResponse(<String, dynamic>{
        'message': 'project not found',
      }, statusCode: listStatus);
    }
    final projectId = options.queryParameters['projectId'];
    return jsonResponse(
      periods
          .where(
            (period) => projectId == null || period['projectId'] == projectId,
          )
          .toList(),
    );
  }
  if (options.path == '/survey-periods' && options.method == 'POST') {
    if (createStatus != 201) {
      return jsonResponse(<String, dynamic>{
        'message': 'only the project creator can define survey periods',
      }, statusCode: createStatus);
    }
    final body = (options.data! as Map).cast<String, dynamic>();
    return jsonResponse(<String, dynamic>{
      'id': 'sp-new',
      'projectId': body['projectId'],
      'name': body['name'],
      'startDate': body['startDate'],
      'endDate': body['endDate'],
    }, statusCode: 201);
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

SurveyPeriodsClient surveyPeriodsWith(
  FakeHttpAdapter adapter,
  AuthClient auth,
) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
  dio.httpClientAdapter = adapter;
  return SurveyPeriodsClient(
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

RequestOptions surveyPeriodsRequest(FakeHttpAdapter adapter, String method) =>
    adapter.requests.firstWhere(
      (request) =>
          request.path == '/survey-periods' && request.method == method,
    );

Future<void> pumpSurveyPeriods(
  WidgetTester tester, {
  required SurveyPeriodsClient client,
  required bool isCreator,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: SurveyPeriodsScreen(
        client: client,
        projectId: 'p1',
        isCreator: isCreator,
      ),
    ),
  );
  await flush(tester);
}

/// Lets a real (non-fake-async) HTTP future complete without hanging the test.
Future<void> flush(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  group('SurveyPeriodsClient', () {
    test('list gets the project survey periods with the auth cookie', () async {
      final adapter = surveyPeriodsAdapter(
        periods: <Map<String, dynamic>>[
          surveyPeriodJson(id: 'sp1', name: 'Spring survey'),
        ],
      );
      final auth = await signedInAuth(adapter);
      final client = surveyPeriodsWith(adapter, auth);

      final periods = await client.list('p1');

      final request = surveyPeriodsRequest(adapter, 'GET');
      expect(request.headers['cookie'], contains('auth-token-123'));
      expect(request.queryParameters['projectId'], 'p1');
      expect(periods.single.name, 'Spring survey');
      expect(periods.single.startDate, '2026-03-01');
      expect(periods.single.endDate, '2026-05-31');
    });

    test('create posts the name and range with the auth cookie', () async {
      final adapter = surveyPeriodsAdapter();
      final auth = await signedInAuth(adapter);
      final client = surveyPeriodsWith(adapter, auth);

      final period = await client.create(
        projectId: 'p1',
        name: 'Spring survey',
        startDate: '2026-03-01',
        endDate: '2026-05-31',
      );

      final request = surveyPeriodsRequest(adapter, 'POST');
      expect(request.data, <String, dynamic>{
        'projectId': 'p1',
        'name': 'Spring survey',
        'startDate': '2026-03-01',
        'endDate': '2026-05-31',
      });
      expect(request.headers['cookie'], contains('auth-token-123'));
      expect(period.name, 'Spring survey');
    });

    test('a rejected request raises a SurveyPeriodsException', () async {
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
          'message': 'only the project creator can define survey periods',
        }, statusCode: 403);
      });
      final auth = await signedInAuth(adapter);
      final client = surveyPeriodsWith(adapter, auth);

      await expectLater(
        client.create(
          projectId: 'p1',
          name: 'Spring survey',
          startDate: '2026-03-01',
          endDate: '2026-05-31',
        ),
        throwsA(isA<SurveyPeriodsException>()),
      );
    });
  });

  group('survey periods surface', () {
    testWidgets(
      'a creator can add a survey period and it appears in the list',
      (tester) async {
        final adapter = surveyPeriodsAdapter(
          periods: <Map<String, dynamic>>[
            surveyPeriodJson(id: 'sp1', name: 'Spring survey'),
          ],
        );
        late final AuthClient auth;
        await tester.runAsync(() async {
          auth = await signedInAuth(adapter);
        });
        final client = surveyPeriodsWith(adapter, auth);
        await pumpSurveyPeriods(tester, client: client, isCreator: true);

        expect(find.text('Spring survey'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('survey_period_add_name')),
          'Autumn survey',
        );
        await tester.enterText(
          find.byKey(const Key('survey_period_add_start')),
          '2026-09-01',
        );
        await tester.enterText(
          find.byKey(const Key('survey_period_add_end')),
          '2026-11-30',
        );
        await tester.tap(find.byKey(const Key('survey_period_add_submit')));
        await flush(tester);

        final request = surveyPeriodsRequest(adapter, 'POST');
        expect(request.data, <String, dynamic>{
          'projectId': 'p1',
          'name': 'Autumn survey',
          'startDate': '2026-09-01',
          'endDate': '2026-11-30',
        });
        expect(find.text('Autumn survey'), findsOneWidget);
      },
    );

    testWidgets('a survey period whose end precedes its start is rejected '
        'before sending', (tester) async {
      final adapter = surveyPeriodsAdapter();
      late final AuthClient auth;
      await tester.runAsync(() async {
        auth = await signedInAuth(adapter);
      });
      final client = surveyPeriodsWith(adapter, auth);
      await pumpSurveyPeriods(tester, client: client, isCreator: true);

      await tester.enterText(
        find.byKey(const Key('survey_period_add_name')),
        'Backwards survey',
      );
      await tester.enterText(
        find.byKey(const Key('survey_period_add_start')),
        '2026-05-31',
      );
      await tester.enterText(
        find.byKey(const Key('survey_period_add_end')),
        '2026-03-01',
      );
      await tester.tap(find.byKey(const Key('survey_period_add_submit')));
      await tester.pump();

      expect(find.byKey(const Key('survey_period_add_error')), findsOneWidget);
      expect(
        adapter.requests.where(
          (request) =>
              request.path == '/survey-periods' && request.method == 'POST',
        ),
        isEmpty,
      );
    });

    testWidgets('survey periods are shown for the selected project', (
      tester,
    ) async {
      final adapter = surveyPeriodsAdapter(
        periods: <Map<String, dynamic>>[
          surveyPeriodJson(id: 'sp1', name: 'Spring survey'),
          surveyPeriodJson(
            id: 'sp2',
            name: 'Autumn survey',
            startDate: '2026-09-01',
            endDate: '2026-11-30',
          ),
          surveyPeriodJson(id: 'sp-other', projectId: 'p2', name: 'Other'),
        ],
      );
      late final AuthClient auth;
      await tester.runAsync(() async {
        auth = await signedInAuth(adapter);
      });
      final client = surveyPeriodsWith(adapter, auth);
      await pumpSurveyPeriods(tester, client: client, isCreator: false);

      final request = surveyPeriodsRequest(adapter, 'GET');
      expect(request.queryParameters['projectId'], 'p1');
      expect(find.text('Spring survey'), findsOneWidget);
      expect(find.text('Autumn survey'), findsOneWidget);
      expect(find.text('Other'), findsNothing);
    });

    testWidgets('a non-creator sees the list without the add form', (
      tester,
    ) async {
      final adapter = surveyPeriodsAdapter(
        periods: <Map<String, dynamic>>[
          surveyPeriodJson(id: 'sp1', name: 'Spring survey'),
        ],
      );
      late final AuthClient auth;
      await tester.runAsync(() async {
        auth = await signedInAuth(adapter);
      });
      final client = surveyPeriodsWith(adapter, auth);
      await pumpSurveyPeriods(tester, client: client, isCreator: false);

      expect(find.text('Spring survey'), findsOneWidget);
      expect(find.byKey(const Key('survey_period_add_name')), findsNothing);
      expect(find.byKey(const Key('survey_period_add_submit')), findsNothing);
    });

    testWidgets('an unloadable survey-period list shows an error', (
      tester,
    ) async {
      final adapter = surveyPeriodsAdapter(listStatus: 404);
      late final AuthClient auth;
      await tester.runAsync(() async {
        auth = await signedInAuth(adapter);
      });
      final client = surveyPeriodsWith(adapter, auth);
      await pumpSurveyPeriods(tester, client: client, isCreator: true);

      expect(find.byKey(const Key('survey_periods_error')), findsOneWidget);
    });
  });
}
