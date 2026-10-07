import 'package:material_ui/material_ui.dart';

import 'system_state_indicator.dart';

/// The persistent app shell: it wraps every top-level route so a single
/// system-state indicator (`UX.md` UX-008) can live here and paint on every
/// screen (`ARCHITECTURE.md`'s `shell` module). The top-level destination is
/// the Projects list, reached without bottom navigation (ADR-0015); Account is
/// opened from the Projects list's app bar.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The shell owns the top inset for its whole body: [SafeArea] lifts the
    // indicator clear of the status bar (edge-to-edge Android, notched iOS) and
    // removes that top padding from its subtree, so a routed screen's own
    // `Scaffold`/`AppBar` does not inset a second time below the indicator.
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SystemStateIndicator(),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
