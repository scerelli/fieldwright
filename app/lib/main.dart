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
  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database)],
      child: const IbisApp(),
    ),
  );
}
