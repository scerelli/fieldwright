import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../outbox/outbox.dart';
import 'app_database.dart';
import 'outbox_dao.dart';
import 'site_dao.dart';
import 'visit_dao.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'databaseProvider must be overridden with an AppDatabase instance',
  );
});

final siteDaoProvider = Provider<SiteDao>(
  (ref) => SiteDao(ref.watch(databaseProvider)),
);

final visitDaoProvider = Provider<VisitDao>(
  (ref) => VisitDao(ref.watch(databaseProvider)),
);

final outboxDaoProvider = Provider<OutboxDao>(
  (ref) => OutboxDao(ref.watch(databaseProvider)),
);

final outboxProvider = Provider<Outbox>(
  (ref) => Outbox(ref.watch(outboxDaoProvider)),
);
