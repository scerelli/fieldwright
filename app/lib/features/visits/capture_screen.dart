import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import 'effort_timer.dart';
import 'visit.dart';

class CaptureScreen extends StatelessWidget {
  const CaptureScreen({super.key, required this.visit, this.clock});

  final Visit visit;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stateLabel = visit.isEnded
        ? l10n.visitStateEnded
        : l10n.visitStateInProgress;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.captureTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.captureState(stateLabel),
              key: const Key('capture_state'),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.captureEffortStarted(
                visit.effort.startedAt.toIso8601String(),
              ),
              key: const Key('capture_effort_started'),
            ),
            const SizedBox(height: 8),
            EffortTimer(
              startedAt: visit.effort.startedAt,
              endedAt: visit.effort.endedAt,
              clock: clock,
            ),
          ],
        ),
      ),
    );
  }
}
