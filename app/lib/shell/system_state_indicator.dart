import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../auth/auth_provider.dart';
import '../l10n/app_localizations.dart';
import '../store/database_provider.dart';
import '../store/outbox_dao.dart';
import '../theme/app_theme.dart';
import '../widgets/sync_indicator.dart';
import 'connectivity.dart';

/// The system states the one persistent shell indicator can report, in the
/// order the shell resolves them (`UX.md` UX-008). Offline outranks a failed
/// submission, which outranks an in-flight one, which outranks the unlinked
/// state; a queued Visit waiting on sign-in is not reported while unlinked.
enum SystemState { offline, failed, syncing, unlinked }

/// The one persistent, non-modal shell indicator (`UX.md` UX-008). It lives in
/// the shell so it paints on every route, and reads connectivity (ADR-0022),
/// the person's link state, and the aggregate outbox sync state. It renders
/// nothing when there is nothing to report.
class SystemStateIndicator extends ConsumerWidget {
  const SystemStateIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(offlineProvider).value ?? false;
    final summary =
        ref.watch(outboxSyncSummaryProvider).value ?? OutboxSummary.none;
    final signedIn = ref.watch(authProvider).value != null;

    final SystemState? state;
    if (offline) {
      state = SystemState.offline;
    } else if (summary.hasFailed) {
      state = SystemState.failed;
    } else if (summary.hasSyncing) {
      state = SystemState.syncing;
    } else if (!signedIn) {
      state = SystemState.unlinked;
    } else if (summary.hasQueued) {
      state = SystemState.syncing;
    } else {
      state = null;
    }

    if (state == null) {
      return const SizedBox.shrink();
    }
    return SystemStateIndicatorView(
      state: state,
      onRetry: state == SystemState.failed ? () => _retry(ref) : null,
    );
  }

  /// Re-queues every pending submission after a failure (`UX.md` UX-008). The
  /// flush is non-blocking and swallows its own failure, so a still-dead
  /// connection never throws at the shell.
  void _retry(WidgetRef ref) {
    try {
      unawaited(ref.read(outboxProvider).flush().catchError((Object _) {}));
    } catch (_) {
      // No outbox configured in this scope; nothing to retry.
    }
  }
}

/// The rendered system-state indicator for a known [state]. Split from
/// [SystemStateIndicator] so it can be rendered directly against a named theme
/// in a golden (`DESIGN.md` § Color, which draws the shell indicator in
/// `outline` with on-surface text).
class SystemStateIndicatorView extends StatelessWidget {
  const SystemStateIndicatorView({
    super.key,
    required this.state,
    this.onRetry,
  });

  final SystemState state;

  /// Re-queues pending submissions after a failure; the affordance is shown
  /// only for [SystemState.failed].
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final outline =
        theme.extension<IbisTokens>()?.outline ?? theme.colorScheme.outline;
    final onSurface = theme.colorScheme.onSurface;
    final (icon, label) = switch (state) {
      SystemState.offline => (
        Icons.cloud_off_outlined,
        l10n.systemStateOffline,
      ),
      SystemState.unlinked => (
        Icons.person_off_outlined,
        l10n.systemStateUnlinked,
      ),
      SystemState.syncing => (
        Icons.cloud_sync_outlined,
        l10n.syncIndicatorSyncing,
      ),
      SystemState.failed => (
        Icons.sync_problem_outlined,
        l10n.syncIndicatorFailed,
      ),
    };

    return Material(
      color: theme.colorScheme.surface,
      child: Container(
        key: Key('shell_indicator_${state.name}'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: outline)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: onSurface),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(color: onSurface),
              ),
            ),
            if (state == SystemState.failed && onRetry != null)
              TextButton(
                key: const Key('shell_indicator_retry'),
                onPressed: onRetry,
                child: Text(l10n.syncIndicatorRetry),
              ),
          ],
        ),
      ),
    );
  }
}
