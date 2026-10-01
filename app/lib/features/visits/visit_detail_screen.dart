import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import 'correction.dart';
import 'visit_status.dart';
import 'visits_client.dart';

/// A stored Visit's history (GLOSSARY.md Visit, Validation, Correction): its
/// Validation status and its Corrections, oldest first, each with its author
/// and time (INV-001, INV-013). The submitted record is never edited; a
/// Correction is the only later change, so this screen reads both from the
/// server through [VisitsClient] rather than the device store.
class VisitDetailScreen extends StatefulWidget {
  const VisitDetailScreen({
    super.key,
    required this.visitId,
    required this.client,
  });

  final String visitId;
  final VisitsClient client;

  @override
  State<VisitDetailScreen> createState() => _VisitDetailScreenState();
}

class _VisitDetailScreenState extends State<VisitDetailScreen> {
  VisitStatus? _status;
  List<Correction> _corrections = const <Correction>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final status = await widget.client.readStatus(widget.visitId);
      final corrections = await widget.client.listCorrections(widget.visitId);
      if (!mounted) return;
      setState(() {
        _status = status;
        _corrections = corrections;
        _loading = false;
      });
    } on VisitsException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context).visitDetailLoadFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.visitDetailTitle)),
      body: _body(l10n),
    );
  }

  Widget _body(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }

    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.visitDetailStatus, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          _statusLabel(l10n, _status!.state),
          key: const Key('visit_status'),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.visitDetailCorrectionsHeading,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        if (_corrections.isEmpty)
          Text(
            l10n.visitDetailCorrectionsEmpty,
            key: const Key('corrections_empty'),
          )
        else
          for (var index = 0; index < _corrections.length; index++)
            ListTile(
              key: Key('correction_$index'),
              title: Text(_corrections[index].authorId),
              subtitle: Text(
                _corrections[index].createdAt?.toIso8601String() ?? '',
              ),
            ),
      ],
    );
  }

  String _statusLabel(AppLocalizations l10n, VisitLifecycleState state) =>
      switch (state) {
        VisitLifecycleState.inProgress => l10n.visitStateInProgress,
        VisitLifecycleState.ended => l10n.visitStateEnded,
        VisitLifecycleState.submitted => l10n.visitStatusSubmitted,
        VisitLifecycleState.validated => l10n.visitStatusValidated,
        VisitLifecycleState.rejected => l10n.visitStatusRejected,
      };
}
