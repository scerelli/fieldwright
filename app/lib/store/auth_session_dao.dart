import '../auth/auth_client.dart';
import 'app_database.dart';

/// Keeps the signed-in person and their Better Auth auth cookie in the local
/// store so a relaunch does not sign them out (`ARCHITECTURE.md` store
/// module). The cookie is opaque here: it is persisted and read back exactly
/// as Better Auth set it.
class AuthSessionDao /* glossary:allow auth session */ {
  AuthSessionDao(this._database); // glossary:allow auth session

  final AppDatabase _database;

  /// The fixed key of the single persisted sign-in.
  static const String _singletonId = 'current';

  /// Persists [person] and their [cookie], replacing any sign-in already
  /// stored.
  Future<void> save({required Person person, required String cookie}) async {
    await _database
        .into(
          _database.authSessions, // glossary:allow auth session
        )
        .insertOnConflictUpdate(
          AuthSessionsCompanion /* glossary:allow auth session */ .insert(
            id: _singletonId,
            personId: person.id,
            email: person.email,
            name: person.name,
            cookie: cookie,
          ),
        );
  }

  /// The persisted sign-in, or null when none is stored.
  Future<({Person person, String cookie})?> read() async {
    final row = await (_database.select(
      _database.authSessions, // glossary:allow auth session
    )..where((table) => table.id.equals(_singletonId))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    return (
      person: Person(id: row.personId, email: row.email, name: row.name),
      cookie: row.cookie,
    );
  }

  /// Removes the persisted sign-in.
  Future<void> clear() async {
    await _database
        .delete(
          _database.authSessions, // glossary:allow auth session
        )
        .go();
  }
}
