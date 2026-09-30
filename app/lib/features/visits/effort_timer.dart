import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// Elapsed effort is the difference between the persisted Visit start time and
/// the current time — never an in-memory counter, so it keeps running across
/// app backgrounding, device sleep and restart (UX-009). Once the Visit has
/// ended, the elapsed effort is fixed at the persisted end.
Duration elapsedEffort(DateTime startedAt, DateTime now, {DateTime? endedAt}) =>
    (endedAt ?? now).difference(startedAt);

/// Formats an elapsed duration as `HH:MM:SS`.
String formatElapsed(Duration elapsed) {
  final seconds = elapsed.inSeconds;
  final hh = (seconds ~/ 3600).toString().padLeft(2, '0');
  final mm = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
  final ss = (seconds % 60).toString().padLeft(2, '0');
  return '$hh:$mm:$ss';
}

/// Displays a Visit's elapsed effort, recomputed from the persisted start on
/// every tick. The periodic ticker only refreshes the display; the elapsed
/// value never depends on it, so a backgrounded or killed app resumes the
/// correct effort on relaunch (UX-009).
class EffortTimer extends StatefulWidget {
  const EffortTimer({
    super.key,
    required this.startedAt,
    this.endedAt,
    this.clock,
    this.tickInterval = const Duration(seconds: 1),
  });

  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime Function()? clock;
  final Duration tickInterval;

  @override
  State<EffortTimer> createState() => _EffortTimerState();
}

class _EffortTimerState extends State<EffortTimer> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    if (widget.endedAt == null) {
      _ticker = Timer.periodic(widget.tickInterval, (_) => setState(() {}));
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = (widget.clock ?? DateTime.now)();
    final elapsed = elapsedEffort(
      widget.startedAt,
      now,
      endedAt: widget.endedAt,
    );
    return Text(formatElapsed(elapsed), key: const Key('effort_elapsed'));
  }
}
