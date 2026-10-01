import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'app_config.dart';
import 'store/app_database.dart';
import 'store/database_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Resolve the server root now: a release build built without
  // IBIS_API_BASE_URL throws here, loudly, instead of shipping the localhost
  // default.
  resolveApiBaseUrl();
  final database = await openAppDatabase();
  final container = ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(database)],
  );
  // Deliver any submission queued or failed on a previous launch, without
  // blocking the UI: the flush retries with backoff and never throws (UX-007).
  unawaited(container.read(outboxStartupProvider.future));
  runApp(
    UncontrolledProviderScope(container: container, child: const IbisApp()),
  );
}
