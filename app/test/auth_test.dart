import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ibis/auth/auth_client.dart';
import 'package:ibis/auth/auth_provider.dart';
import 'package:ibis/features/account/account_screen.dart';
import 'package:ibis/l10n/app_localizations.dart';

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

AuthClient clientWith(FakeHttpAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
  dio.httpClientAdapter = adapter;
  return AuthClient(baseUrl: 'http://test.local', dio: dio);
}

FakeHttpAdapter signingIn({
  String name = 'Ada Lovelace',
  String email = 'ada@example.com',
}) => FakeHttpAdapter(
  (options) async => jsonResponse(<String, dynamic>{
    'user': <String, dynamic>{'id': 'u1', 'email': email, 'name': name},
  }),
);

// Better Auth sets its auth cookie on sign-up (autoSignIn); the fake returns
// one so the client can capture it.
Map<String, List<String>> signUpHeaders() => <String, List<String>>{
  'set-cookie': <String>[
    'better-auth.session_token=abc; Path=/; HttpOnly', // glossary:allow Better Auth session cookie, not the domain Visit
  ],
};

FakeHttpAdapter signingUp({
  String name = 'Ada Lovelace',
  String email = 'ada@example.com',
}) => FakeHttpAdapter(
  (options) async => jsonResponse(<String, dynamic>{
    'token': 'token',
    'user': <String, dynamic>{'id': 'u1', 'email': email, 'name': name},
  }, headers: signUpHeaders()),
);

void main() {
  group('AuthClient', () {
    test(
      'sign-in posts the credentials and returns the current person',
      () async {
        final adapter = FakeHttpAdapter((options) async {
          expect(options.path, '/api/auth/sign-in/email');
          expect(options.data, <String, String>{
            'email': 'ada@example.com',
            'password': 'correct',
          });
          return jsonResponse(<String, dynamic>{
            'user': <String, dynamic>{
              'id': 'u1',
              'email': 'ada@example.com',
              'name': 'Ada Lovelace',
            },
          });
        });

        final person = await clientWith(adapter)
            .signIn(email: 'ada@example.com', password: 'correct');

        expect(person.id, 'u1');
        expect(person.email, 'ada@example.com');
        expect(person.name, 'Ada Lovelace');
      },
    );

    test(
      'sign-in throws an AuthException when the credentials are wrong',
      () async {
        final adapter = FakeHttpAdapter(
          (options) async => jsonResponse(<String, dynamic>{
            'message': 'Invalid email or password',
          }, statusCode: 401),
        );

        await expectLater(
          clientWith(adapter)
              .signIn(email: 'ada@example.com', password: 'wrong'),
          throwsA(isA<AuthException>()),
        );
      },
    );

    test('sign-up posts name, email and password, captures the auth cookie, returns the person', () async {
      final adapter = FakeHttpAdapter((options) async {
        expect(options.path, '/api/auth/sign-up/email');
        expect(options.data, <String, String>{
          'name': 'Ada Lovelace',
          'email': 'ada@example.com',
          'password': 'correct-horse',
        });
        return jsonResponse(<String, dynamic>{
          'token': 'token',
          'user': <String, dynamic>{
            'id': 'u1',
            'email': 'ada@example.com',
            'name': 'Ada Lovelace',
          },
        }, headers: signUpHeaders());
      });

      final client = clientWith(adapter);
      final person = await client.signUp(
        name: 'Ada Lovelace',
        email: 'ada@example.com',
        password: 'correct-horse',
      );

      expect(person.name, 'Ada Lovelace');
      expect(
        client.sessionCookie, // glossary:allow auth session
        contains('better-auth.session_token=abc'), // glossary:allow
      );
    });

    test(
      'sign-up throws an AuthException when the email is already registered',
      () async {
        final adapter = FakeHttpAdapter(
          (options) async => jsonResponse(<String, dynamic>{
            'message': 'User already exists',
          }, statusCode: 422),
        );

        await expectLater(
          clientWith(adapter).signUp(
            name: 'Ada Lovelace',
            email: 'ada@example.com',
            password: 'correct-horse',
          ),
          throwsA(isA<AuthException>()),
        );
      },
    );

    test('sign-out posts to the sign-out endpoint', () async {
      final adapter = FakeHttpAdapter((options) async {
        expect(options.path, '/api/auth/sign-out');
        return jsonResponse(<String, dynamic>{'success': true});
      });

      await clientWith(adapter).signOut();
    });
  });

  group('authProvider', () {
    test(
      'a valid sign-in starts a session holding the current person', // glossary:allow Better Auth auth session, not the domain Visit
      () async {
        final container = ProviderContainer.test(
          overrides: [
            authClientProvider.overrideWithValue(clientWith(signingIn())),
          ],
        );

        await container
            .read(authProvider.notifier)
            .signIn(email: 'ada@example.com', password: 'correct');

        expect(container.read(authProvider).value?.name, 'Ada Lovelace');
      },
    );

    test(
      'wrong credentials surface an error and leave the user signed out',
      () async {
        final container = ProviderContainer.test(
          overrides: [
            authClientProvider.overrideWithValue(
              clientWith(
                FakeHttpAdapter(
                  (options) async => jsonResponse(<String, dynamic>{
                    'message': 'Invalid email or password',
                  }, statusCode: 401),
                ),
              ),
            ),
          ],
        );

        await container
            .read(authProvider.notifier)
            .signIn(email: 'ada@example.com', password: 'wrong');

        expect(container.read(authProvider).hasError, isTrue);
        expect(container.read(authProvider).value, isNull);
      },
    );

    test(
      'a valid sign-up starts a session holding the current person', // glossary:allow Better Auth auth session, not the domain Visit
      () async {
        final container = ProviderContainer.test(
          overrides: [
            authClientProvider.overrideWithValue(clientWith(signingUp())),
          ],
        );

        await container
            .read(authProvider.notifier)
            .signUp(
              name: 'Ada Lovelace',
              email: 'ada@example.com',
              password: 'correct-horse',
            );

        expect(container.read(authProvider).value?.name, 'Ada Lovelace');
      },
    );

    test('signing out clears the signed-in person', () async {
      final adapter = FakeHttpAdapter((options) async {
        if (options.path == '/api/auth/sign-out') {
          return jsonResponse(<String, dynamic>{'success': true});
        }
        return jsonResponse(<String, dynamic>{
          'user': <String, dynamic>{
            'id': 'u1',
            'email': 'ada@example.com',
            'name': 'Ada Lovelace',
          },
        });
      });
      final container = ProviderContainer.test(
        overrides: [authClientProvider.overrideWithValue(clientWith(adapter))],
      );
      final auth = container.read(authProvider.notifier);

      await auth.signIn(email: 'ada@example.com', password: 'correct');
      await auth.signOut();

      expect(container.read(authProvider).value, isNull);
      expect(container.read(authProvider).hasError, isFalse);
    });
  });

  group('AccountScreen', () {
    Future<void> pumpAccount(WidgetTester tester, AuthClient client) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authClientProvider.overrideWithValue(client)],
          child: MaterialApp(
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AccountScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> submitCredentials(
      WidgetTester tester, {
      required String email,
      required String password,
    }) async {
      await tester.enterText(find.byKey(const Key('auth_email')), email);
      await tester.enterText(find.byKey(const Key('auth_password')), password);
      await tester.tap(find.byKey(const Key('auth_sign_in')));
      await tester.pumpAndSettle();
    }

    Future<void> switchToSignUp(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('auth_switch_to_sign_up')));
      await tester.pumpAndSettle();
    }

    Future<void> submitSignUp(
      WidgetTester tester, {
      required String name,
      required String email,
      required String password,
    }) async {
      await tester.enterText(find.byKey(const Key('auth_name')), name);
      await tester.enterText(find.byKey(const Key('auth_email')), email);
      await tester.enterText(find.byKey(const Key('auth_password')), password);
      await tester.tap(find.byKey(const Key('auth_sign_up')));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the current person after a valid sign-in', (
      tester,
    ) async {
      await pumpAccount(tester, clientWith(signingIn()));

      await submitCredentials(
        tester,
        email: 'ada@example.com',
        password: 'correct',
      );

      expect(find.textContaining('Ada Lovelace'), findsOneWidget);
    });

    testWidgets('shows an error and stays signed out on wrong credentials', (
      tester,
    ) async {
      await pumpAccount(
        tester,
        clientWith(
          FakeHttpAdapter(
            (options) async => jsonResponse(<String, dynamic>{
              'message': 'Invalid email or password',
            }, statusCode: 401),
          ),
        ),
      );

      await submitCredentials(
        tester,
        email: 'ada@example.com',
        password: 'wrong',
      );

      expect(
        find.text('Sign-in failed. Check your email and password.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('auth_sign_in')), findsOneWidget);
      expect(find.textContaining('Ada Lovelace'), findsNothing);
    });

    testWidgets('signing out returns to the sign-in form', (tester) async {
      final adapter = FakeHttpAdapter((options) async {
        if (options.path == '/api/auth/sign-out') {
          return jsonResponse(<String, dynamic>{'success': true});
        }
        return jsonResponse(<String, dynamic>{
          'user': <String, dynamic>{
            'id': 'u1',
            'email': 'ada@example.com',
            'name': 'Ada Lovelace',
          },
        });
      });
      await pumpAccount(tester, clientWith(adapter));

      await submitCredentials(
        tester,
        email: 'ada@example.com',
        password: 'correct',
      );
      expect(find.textContaining('Ada Lovelace'), findsOneWidget);

      await tester.tap(find.byKey(const Key('auth_sign_out')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_sign_in')), findsOneWidget);
      expect(find.textContaining('Ada Lovelace'), findsNothing);
    });

    testWidgets('switches to a sign-up form with name, email and password', (
      tester,
    ) async {
      await pumpAccount(tester, clientWith(signingUp()));

      await switchToSignUp(tester);

      expect(find.byKey(const Key('auth_name')), findsOneWidget);
      expect(find.byKey(const Key('auth_email')), findsOneWidget);
      expect(find.byKey(const Key('auth_password')), findsOneWidget);
      expect(find.byKey(const Key('auth_sign_up')), findsOneWidget);
    });

    testWidgets(
      'a valid sign-up creates the account, signs in, shows the name',
      (tester) async {
        await pumpAccount(tester, clientWith(signingUp()));

        await switchToSignUp(tester);
        await submitSignUp(
          tester,
          name: 'Ada Lovelace',
          email: 'ada@example.com',
          password: 'correct-horse',
        );

        expect(find.byKey(const Key('auth_sign_out')), findsOneWidget);
        expect(find.byKey(const Key('auth_sign_in')), findsNothing);
        expect(find.textContaining('Ada Lovelace'), findsOneWidget);
      },
    );

    testWidgets('switches back to the sign-in form from the sign-up form', (
      tester,
    ) async {
      await pumpAccount(tester, clientWith(signingUp()));

      await switchToSignUp(tester);
      expect(find.byKey(const Key('auth_sign_up')), findsOneWidget);

      await tester.tap(find.byKey(const Key('auth_switch_to_sign_in')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_sign_in')), findsOneWidget);
      expect(find.byKey(const Key('auth_name')), findsNothing);
    });

    testWidgets('an already-registered email shows an error, no new account', (
      tester,
    ) async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(<String, dynamic>{
          'message': 'User already exists',
        }, statusCode: 422),
      );
      await pumpAccount(tester, clientWith(adapter));

      await switchToSignUp(tester);
      await submitSignUp(
        tester,
        name: 'Ada Lovelace',
        email: 'ada@example.com',
        password: 'correct-horse',
      );

      expect(find.byKey(const Key('auth_error')), findsOneWidget);
      expect(find.byKey(const Key('auth_sign_up')), findsOneWidget);
      expect(find.byKey(const Key('auth_sign_out')), findsNothing);
      expect(adapter.requests, hasLength(1));
    });

    testWidgets('an invalid email shows an error and sends no request', (
      tester,
    ) async {
      final adapter = signingUp();
      await pumpAccount(tester, clientWith(adapter));

      await switchToSignUp(tester);
      await submitSignUp(
        tester,
        name: 'Ada Lovelace',
        email: 'not-an-email',
        password: 'correct-horse',
      );

      expect(find.text('Enter a valid email.'), findsOneWidget);
      expect(find.byKey(const Key('auth_sign_up')), findsOneWidget);
      expect(adapter.requests, isEmpty);
    });

    testWidgets('a too-short password shows an error and sends no request', (
      tester,
    ) async {
      final adapter = signingUp();
      await pumpAccount(tester, clientWith(adapter));

      await switchToSignUp(tester);
      await submitSignUp(
        tester,
        name: 'Ada Lovelace',
        email: 'ada@example.com',
        password: 'short',
      );

      expect(find.text('Use at least 8 characters.'), findsOneWidget);
      expect(find.byKey(const Key('auth_sign_up')), findsOneWidget);
      expect(adapter.requests, isEmpty);
    });

    testWidgets('an empty name shows an error and sends no request', (
      tester,
    ) async {
      final adapter = signingUp();
      await pumpAccount(tester, clientWith(adapter));

      await switchToSignUp(tester);
      await submitSignUp(
        tester,
        name: '',
        email: 'ada@example.com',
        password: 'correct-horse',
      );

      expect(find.text('Enter your name.'), findsOneWidget);
      expect(find.byKey(const Key('auth_sign_up')), findsOneWidget);
      expect(adapter.requests, isEmpty);
    });

    testWidgets('signing out after a sign-up returns to the sign-in form', (
      tester,
    ) async {
      final adapter = FakeHttpAdapter((options) async {
        if (options.path == '/api/auth/sign-out') {
          return jsonResponse(<String, dynamic>{'success': true});
        }
        return jsonResponse(<String, dynamic>{
          'token': 'token',
          'user': <String, dynamic>{
            'id': 'u1',
            'email': 'ada@example.com',
            'name': 'Ada Lovelace',
          },
        }, headers: signUpHeaders());
      });
      await pumpAccount(tester, clientWith(adapter));

      await switchToSignUp(tester);
      await submitSignUp(
        tester,
        name: 'Ada Lovelace',
        email: 'ada@example.com',
        password: 'correct-horse',
      );
      expect(find.byKey(const Key('auth_sign_out')), findsOneWidget);

      await tester.tap(find.byKey(const Key('auth_sign_out')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_sign_in')), findsOneWidget);
      expect(find.byKey(const Key('auth_sign_up')), findsNothing);
    });
  });
}
