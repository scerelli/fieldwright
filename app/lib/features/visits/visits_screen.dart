import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../store/database_provider.dart';
import '../../widgets/empty_state.dart';
import '../sites/site.dart';
import '../sites/site_detail.dart';
import '../sites/sites_map.dart';
import 'capture_screen.dart';
import 'visit.dart';

class VisitsScreen extends ConsumerStatefulWidget {
  const VisitsScreen({
    super.key,
    this.projectId,
    this.surveyPeriodId,
    this.protocolVersionId,
  });

  final String? projectId;
  final String? surveyPeriodId;
  final String? protocolVersionId;

  @override
  ConsumerState<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends ConsumerState<VisitsScreen> {
  List<Visit> _visits = const <Visit>[];

  bool get _configured =>
      widget.projectId != null &&
      widget.surveyPeriodId != null &&
      widget.protocolVersionId != null;

  @override
  void initState() {
    super.initState();
    if (_configured) _load();
  }

  Future<void> _load() async {
    final visits = await ref.read(visitDaoProvider).all();
    if (!mounted) return;
    setState(() => _visits = visits);
  }

  Future<void> _startVisit(Site site) async {
    final visit = await ref
        .read(visitDaoProvider)
        .startVisit(
          siteId: site.id,
          surveyPeriodId: widget.surveyPeriodId!,
          protocolVersionId: widget.protocolVersionId!,
        );
    if (!mounted) return;
    setState(() => _visits = <Visit>[..._visits, visit]);
    await _openCapture(visit);
  }

  Future<void> _openCapture(Visit visit) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => CaptureScreen(visit: visit)),
    );
  }

  Future<void> _confirmEndVisit(Visit visit) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.visitsEndVisitTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            key: const Key('end_visit_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.visitsEndVisit),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ended = await ref.read(visitDaoProvider).endVisit(visit);
    if (!mounted) return;
    setState(() {
      final index = _visits.indexWhere((candidate) => candidate.id == visit.id);
      if (index != -1) _visits[index] = ended;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (!_configured) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.navVisits)),
        body: EmptyState(
          title: l10n.visitsEmptyTitle,
          message: l10n.visitsEmptyMessage,
        ),
      );
    }

    final sites =
        ref.watch(projectSitesProvider(widget.projectId!)).value ??
        const <Site>[];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navVisits)),
      body: ListView(
        children: [
          _heading(l10n.visitsSitesHeading),
          if (sites.isEmpty)
            ListTile(title: Text(l10n.sitesEmptyMessage))
          else
            for (final site in sites)
              ListTile(
                leading: const Icon(Icons.place_outlined),
                title: Text(siteGeometryLabel(l10n, site.geometry)),
                trailing: IconButton(
                  key: Key('start_visit_${site.id}'),
                  tooltip: l10n.visitsStartVisit,
                  onPressed: () => _startVisit(site),
                  icon: const Icon(Icons.play_arrow),
                ),
              ),
          _heading(l10n.visitsListHeading),
          if (_visits.isEmpty)
            ListTile(title: Text(l10n.visitsEmptyMessage))
          else
            for (final visit in _visits)
              ListTile(
                key: Key('visit_${visit.id}'),
                leading: Icon(
                  visit.isEnded
                      ? Icons.check_circle_outline
                      : Icons.timelapse_outlined,
                ),
                title: Text(
                  visit.isEnded
                      ? l10n.visitStateEnded
                      : l10n.visitStateInProgress,
                ),
                subtitle: Text(visit.effort.startedAt.toIso8601String()),
                onTap: () => _openCapture(visit),
                trailing: visit.isEnded
                    ? null
                    : TextButton(
                        key: Key('end_visit_${visit.id}'),
                        onPressed: () => _confirmEndVisit(visit),
                        child: Text(l10n.visitsEndVisit),
                      ),
              ),
        ],
      ),
    );
  }

  Widget _heading(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );
}
