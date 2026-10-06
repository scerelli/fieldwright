import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// The non-blocking "no pinned reference" prompt (`DESIGN.md` § Component
/// conventions, UX-034): rendered inline wherever a Project's missing pin is
/// shown — never as a blocking modal, so capture and submission are never
/// interrupted. Drawn in the `outline` token so it reads as the same
/// "not resolved" state the provisional taxon chip does (UX-014, UX-034).
class ReferenceBanner extends StatelessWidget {
  const ReferenceBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outline =
        theme.extension<IbisTokens>()?.outline ?? theme.colorScheme.outline;
    return Container(
      key: const Key('reference_banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.link_off_outlined, size: 20, color: outline),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context).needsAttentionPinnedReference,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The compact Project-card variant of the "no pinned reference" prompt
/// (`DESIGN.md` § Component conventions, UX-034): the same `outline`-token
/// state in an intrinsic-width badge that fits a Project card's subtitle, and
/// never a modal (UX-034).
class ReferenceCardBadge extends StatelessWidget {
  const ReferenceCardBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outline =
        theme.extension<IbisTokens>()?.outline ?? theme.colorScheme.outline;
    return Container(
      key: const Key('reference_card_badge'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link_off_outlined, size: 14, color: outline),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.of(context).projectCardNoReference,
            style: theme.textTheme.labelSmall?.copyWith(color: outline),
          ),
        ],
      ),
    );
  }
}
