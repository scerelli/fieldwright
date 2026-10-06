import 'package:material_ui/material_ui.dart';

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
    return Scaffold(body: child);
  }
}
