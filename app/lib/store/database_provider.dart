import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'site_dao.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'databaseProvider must be overridden with an AppDatabase instance',
  );
});

final siteDaoProvider = Provider<SiteDao>(
  (ref) => SiteDao(ref.watch(databaseProvider)),
);
