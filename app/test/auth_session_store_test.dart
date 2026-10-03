import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ibis/auth/auth_client.dart';
import 'package:ibis/store/app_database.dart';
import 'package:ibis/store/auth_session_dao.dart'; // glossary:allow auth session

const Person _person = Person(
  id: 'person-1',
  email: 'ada@example.org',
  name: 'Ada Lovelace',
);

const String _cookie = 'ibis.auth.token=abc123';

void main() {
  test('persists the signed-in person and their auth cookie and reads them back after the database is reopened', () async {
    final directory = Directory.systemTemp.createTempSync('ibis_auth');
    addTearDown(() => directory.deleteSync(recursive: true));
    final path = '${directory.path}/ibis.sqlite';

    var database = AppDatabase.open(path);
    final first = AuthSessionDao(database); // glossary:allow auth session
    await first.save(person: _person, cookie: _cookie);
    await database.close();

    database = AppDatabase.open(path);
    addTearDown(database.close);
    final again = AuthSessionDao(database); // glossary:allow auth session
    final restored = await again.read();

    expect(restored, isNotNull);
    expect(restored!.person.id, 'person-1');
    expect(restored.person.email, 'ada@example.org');
    expect(restored.person.name, 'Ada Lovelace');
    expect(restored.cookie, _cookie);
  });

  test('clearing removes the persisted sign-in and it stays gone after the database is reopened', () async {
    final directory = Directory.systemTemp.createTempSync('ibis_auth');
    addTearDown(() => directory.deleteSync(recursive: true));
    final path = '${directory.path}/ibis.sqlite';

    var database = AppDatabase.open(path);
    final dao = AuthSessionDao(database); // glossary:allow auth session
    await dao.save(person: _person, cookie: _cookie);
    expect(await dao.read(), isNotNull);

    await dao.clear();
    expect(await dao.read(), isNull);
    await database.close();

    database = AppDatabase.open(path);
    addTearDown(database.close);
    final again = AuthSessionDao(database); // glossary:allow auth session
    expect(await again.read(), isNull);
  });

  group('migration', () {
    test('migrates a version 14 client schema to version 15 adding the sign-in store', () async {
      final database = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute('PRAGMA user_version = 14');
          },
        ),
      );
      addTearDown(database.close);

      final version = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.data['user_version'], 18);

      final tables = await database
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name = 'auth_sessions'", // glossary:allow auth session
          )
          .get();
      expect(tables, hasLength(1));

      final dao = AuthSessionDao(database); // glossary:allow auth session
      await dao.save(person: _person, cookie: _cookie);
      final restored = await dao.read();
      expect(restored, isNotNull);
      expect(restored!.person.id, 'person-1');
      expect(restored.cookie, _cookie);
    });
  });
}
