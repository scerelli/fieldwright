import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_config.dart';
import '../store/database_provider.dart';
import 'auth_client.dart';

/// The self-hosted server root every client is built from, resolved from the
/// single compile-time value `IBIS_API_BASE_URL` (`app_config.dart`). Better
/// Auth is mounted at `/api/auth/*`, so the client appends that path.
final String authBaseUrl = apiBaseUrl;

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
    state = await AsyncValue.guard(() async {
      final client = ref.read(authClientProvider);
      final person = await client.signIn(email: email, password: password);
      await _persist(client, person);
      return person;
    });
  }

  /// Creates the account and holds the resulting person, so a just-signed-up
  /// person is authenticated on later requests. // glossary:allow Better Auth auth session, not the domain Visit
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue<Person?>.loading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(authClientProvider);
      final person = await client.signUp(
        name: name,
        email: email,
        password: password,
      );
      await _persist(client, person);
      return person;
    });
  }

  /// Restores a sign-in persisted on a previous launch: reads the stored person
  /// and Better Auth auth cookie, validates the cookie against the server, and
  /// holds the person so the UI shows their name without credentials.
  ///
  /// Clears the store when the server rejects the cookie (signed out). Keeps it
  /// — signed in, cookie attached — when the server is unreachable, so a Visit
  /// queued offline is still delivered once connectivity returns (UX-007).
  /// // glossary:allow Better Auth auth session, not the domain Visit
  Future<void> restore() async {
    final dao = ref.read(authSessionDaoProvider); // glossary:allow auth session
    final persisted = await dao.read();
    if (persisted == null) {
      state = const AsyncValue<Person?>.data(null);
      return;
    }
    try {
      final person = await ref
          .read(authClientProvider)
          .restoreSession( // glossary:allow Better Auth session restore, not the domain Visit
            persisted.cookie,
          );
      if (person == null) {
        await dao.clear();
        state = const AsyncValue<Person?>.data(null);
      } else {
        // Refresh the stored person from what the server now reports, so a
        // renamed or re-emailed account is current on the next offline launch.
        await dao.save(person: person, cookie: persisted.cookie);
        state = AsyncValue<Person?>.data(person);
      }
    } on AuthException {
      await dao.clear();
      state = const AsyncValue<Person?>.data(null);
    } on AuthTransportException {
      state = AsyncValue<Person?>.data(persisted.person);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue<Person?>.loading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(authClientProvider).signOut();
      } finally {
        await ref
            .read(authSessionDaoProvider) // glossary:allow auth session
            .clear();
      }
      return null;
    });
  }

  /// Stores [person] and the Better Auth cookie [client] captured at sign-in. // glossary:allow Better Auth auth session, not the domain Visit
  Future<void> _persist(AuthClient client, Person person) async {
    final cookie = client.sessionCookie; // glossary:allow Better Auth session cookie, not the Visit
    if (cookie == null) return;
    await ref
        .read(authSessionDaoProvider) // glossary:allow auth session
        .save(person: person, cookie: cookie);
  }
}

final authProvider = AsyncNotifierProvider<AuthController, Person?>(
  AuthController.new,
);
