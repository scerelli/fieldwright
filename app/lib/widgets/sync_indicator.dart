import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../outbox/outbox.dart';
import '../store/database_provider.dart';

/// The sync state recorded for [visitId], read from the outbox in the local
/// store so the indicator reflects the Visit's delivery state rather than an
/// in-memory copy (UX-008). Callers invalidate it after an action that moves
/// the state — submitting or retrying — so the indicator refreshes in place.
final visitSyncStateProvider = FutureProvider.family<SyncState?, String>(
  (ref, visitId) => ref.watch(outboxDaoProvider).syncStateOf(visitId),
);

/// A persistent, non-modal indicator of a Visit's sync state, shown inline on
/// the visit screen rather than as a dialog or transient toast, so the collector
/// always knows whether the work is safe (UX-008). Renders nothing for a Visit
/// that has not entered the outbox.
class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key, required this.visitId, this.onRetry});

  final String visitId;

  /// Re-queues the Visit after a failed delivery. The retry affordance is
  /// shown only for [SyncState.failed].
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visitSyncStateProvider(visitId)).value;
    if (state == null) {
      return const SizedBox.shrink();
    }
    return SyncIndicatorView(state: state, onRetry: onRetry);
  }
}

/// The rendered sync indicator for a known [state]. Split from [SyncIndicator]
/// so it can be rendered directly against a named theme in a golden (UX-008).
class SyncIndicatorView extends StatelessWidget {
  const SyncIndicatorView({super.key, required this.state, this.onRetry});

  final SyncState state;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = switch (state) {
      SyncState.queued => (l10n.syncIndicatorQueued, colorScheme.onSurfaceVariant),
      SyncState.syncing => (l10n.syncIndicatorSyncing, colorScheme.onSurfaceVariant),
      SyncState.synced => (l10n.syncIndicatorSynced, colorScheme.primary),
      SyncState.failed => (l10n.syncIndicatorFailed, colorScheme.error),
    };
    final leading = switch (state) {
      SyncState.queued => Icon(
        Icons.cloud_queue_outlined,
        size: 20,
        color: color,
      ),
      SyncState.syncing => SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      ),
      SyncState.synced => Icon(
        Icons.cloud_done_outlined,
        size: 20,
        color: color,
      ),
      SyncState.failed => Icon(
        Icons.cloud_off_outlined,
        size: 20,
        color: color,
      ),
    };

    return Padding(
      key: Key('sync_indicator_${state.name}'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(color: color))),
          if (state == SyncState.failed && onRetry != null)
            TextButton(
              key: const Key('sync_indicator_retry'),
              onPressed: onRetry,
              child: Text(l10n.syncIndicatorRetry),
            ),
        ],
      ),
    );
  }
}
