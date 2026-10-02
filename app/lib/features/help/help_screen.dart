import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';

/// The in-app manual: a streamlined explanation of the core field journey,
/// reachable from the Projects list (UX-023). Owns no aggregate — the `help`
/// module in `ARCHITECTURE.md`'s module map.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      key: const Key('help_screen'),
      appBar: AppBar(title: Text(l10n.helpTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HelpSection(
            title: l10n.helpCreateProjectTitle,
            body: l10n.helpCreateProjectBody,
          ),
          _HelpSection(
            title: l10n.helpCaptureVisitTitle,
            body: l10n.helpCaptureVisitBody,
          ),
          _HelpSection(
            title: l10n.helpSubmitVisitTitle,
            body: l10n.helpSubmitVisitBody,
          ),
        ],
      ),
    );
  }
}

/// One titled block of manual copy. Body text stays at the theme's `bodyLarge`
/// (16 sp) for the direct-sun contrast floor (UX-002).
class _HelpSection extends StatelessWidget {
  const _HelpSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(body, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
