import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'store/app_database.dart';
import 'store/database_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await openAppDatabase();
  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database)],
      child: const IbisApp(),
    ),
  );
}
