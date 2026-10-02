import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import '../outbox/outbox.dart';
import '../outbox/sync_client.dart';
import 'app_database.dart';
import 'auth_session_dao.dart'; // glossary:allow auth session
import 'config_dao.dart';
import 'detection_dao.dart';
import 'determination_dao.dart';
import 'evidence_dao.dart';
import 'measurement_dao.dart';
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

final authSessionDaoProvider = // glossary:allow auth session
    Provider<AuthSessionDao /* glossary:allow auth session */>(
      (ref) => AuthSessionDao( // glossary:allow auth session
        ref.watch(databaseProvider),
      ),
    );

final visitDaoProvider = Provider<VisitDao>(
  (ref) => VisitDao(ref.watch(databaseProvider)),
);

final configDaoProvider = Provider<ConfigDao>(
  (ref) => ConfigDao(ref.watch(databaseProvider)),
);

final outboxDaoProvider = Provider<OutboxDao>(
  (ref) => OutboxDao(ref.watch(databaseProvider)),
);

/// The outbox wired for production: the real [SyncClient] over dio and the
/// DAOs delivery writes through, so a caller only has to queue (UX-007).
final outboxProvider = Provider<Outbox>(
  (ref) => Outbox(
    ref.watch(outboxDaoProvider),
    client: ref.watch(syncClientProvider),
    visits: ref.watch(visitDaoProvider),
    sites: ref.watch(siteDaoProvider),
    config: ref.watch(configDaoProvider),
    detections: ref.watch(detectionDaoProvider),
    determinations: ref.watch(determinationDaoProvider),
    evidence: ref.watch(evidenceDaoProvider),
    measurements: ref.watch(measurementDaoProvider),
  ),
);

/// Delivers the pending outbox once, at app start: a Visit queued or failed on
/// a previous launch reaches the server without any caller invoking the engine
/// (UX-007). Error-safe — a failed flush leaves the Visit queued/failed for the
/// next attempt and never surfaces as an app error (UX-013).
final outboxStartupProvider = FutureProvider<void>((ref) async {
  try {
    await ref.watch(outboxProvider).flush();
  } catch (_) {
    // Retried on the next flush; startup must not fail because delivery did.
  }
});

/// Flushes the outbox whenever the app becomes authenticated. The sync API is
/// auth-guarded, so the app-start flush parks pending Visits as `queued`; this
/// listener delivers them as soon as sign-in succeeds, without a manual call
/// (UX-007). The flush is non-blocking and swallows its own failure.
final outboxAuthFlushProvider = Provider<void>((ref) {
  ref.listen(authProvider, (previous, next) {
    final wasSignedIn = previous?.value != null;
    final isSignedIn = next.value != null;
    if (isSignedIn && !wasSignedIn) {
      try {
        unawaited(ref.read(outboxProvider).flush().catchError((Object _) {}));
      } catch (_) {
        // No outbox configured in this scope; nothing to deliver.
      }
    }
  });
});
