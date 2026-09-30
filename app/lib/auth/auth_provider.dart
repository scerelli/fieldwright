import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_client.dart';

/// The self-hosted server root. Better Auth is mounted at `/api/auth/*`, so
/// the client appends that path; override at build time with
/// `--dart-define=IBIS_API_BASE_URL=https://host`.
const String authBaseUrl = String.fromEnvironment(
  'IBIS_API_BASE_URL',
  defaultValue: 'http://localhost:3000',
);

final authClientProvider = Provider<AuthClient>(
  (ref) => AuthClient(baseUrl: authBaseUrl),
);

/// Holds the current person for the lifetime of the auth session. // glossary:allow Better Auth auth session, not the domain Visit
///
/// `null` when signed out, the person when a session is active, and an error // glossary:allow Better Auth auth session, not the domain Visit
/// after a failed sign-in so the form can show the failure and no session // glossary:allow Better Auth auth session, not the domain Visit
/// starts.
class AuthController extends AsyncNotifier<Person?> {
  @override
  Person? build() => null;

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue<Person?>.loading();
    state = await AsyncValue.guard(
      () =>
          ref.read(authClientProvider).signIn(email: email, password: password),
    );
  }

  Future<void> signOut() async {
    state = const AsyncValue<Person?>.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authClientProvider).signOut();
      return null;
    });
  }
}

final authProvider = AsyncNotifierProvider<AuthController, Person?>(
  AuthController.new,
);
