import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// The label `DESIGN.md` § Component conventions gives a provisional taxon's
/// marker — the single spelling "unresolved", so it reads the same everywhere a
/// provisional taxon appears (UX-033).
const String kProvisionalTaxonLabel = 'unresolved';

/// The shared provisional (unresolved) taxon chip (`DESIGN.md` § Component
/// conventions, UX-033): a dashed-outline chip drawn in the `outline` token,
/// carrying the "unresolved" marker. An unresolved name must never be mistaken
/// for a resolved one, so the chip has no filled/resolved form — it reads the
/// one `outline` colour and never the `detected` state (UX-014, UX-033).
class ProvisionalTaxonChip extends StatelessWidget {
  const ProvisionalTaxonChip({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outline =
        theme.extension<IbisTokens>()?.outline ?? theme.colorScheme.outline;
    return CustomPaint(
      key: const Key('provisional_taxon_chip'),
      painter: _DashedOutlinePainter(color: outline),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          kProvisionalTaxonLabel,
          style: theme.textTheme.labelMedium?.copyWith(color: outline),
        ),
      ),
    );
  }
}

/// Paints a dashed rounded outline in [color] around its child — the same
/// `outline`-token marker the provisional Visit and hidden coordinates share,
/// so "not resolved" reads the same everywhere (`DESIGN.md` § Component
/// conventions).
class _DashedOutlinePainter extends CustomPainter {
  const _DashedOutlinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      );
    canvas.drawPath(
      _dash(path, dash: 6, gap: 4),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_DashedOutlinePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Breaks [source] into a dashed path: [dash] on, [gap] off, per contour.
Path _dash(Path source, {required double dash, required double gap}) {
  final result = Path();
  for (final metric in source.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final next = math.min(distance + dash, metric.length);
      result.addPath(metric.extractPath(distance, next), Offset.zero);
      distance = next + gap;
    }
  }
  return result;
}
