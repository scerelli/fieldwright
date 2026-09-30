import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../projects/survey_periods_client.dart';

/// The Survey periods surface: lists a Project's Survey periods and, for the
/// Project's creator, lets one be defined with a name and a date range
/// (`DOMAIN.md`, `GLOSSARY.md` SurveyPeriod).
///
/// A non-creator sees the same list without the add action. The add form
/// rejects an empty name or date, an unparseable date, and an end date that
/// precedes the start date before any request leaves the device.
class SurveyPeriodsScreen extends StatefulWidget {
  const SurveyPeriodsScreen({
    super.key,
    required this.client,
    required this.projectId,
    required this.isCreator,
  });

  final SurveyPeriodsClient client;
  final String projectId;

  /// Whether the signed-in person is the Project's creator. Only a creator may
  /// define a Survey period, so only they see the add action.
  final bool isCreator;

  @override
  State<SurveyPeriodsScreen> createState() => _SurveyPeriodsScreenState();
}

class _SurveyPeriodsScreenState extends State<SurveyPeriodsScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _start = TextEditingController();
  final TextEditingController _end = TextEditingController();

  List<SurveyPeriod> _periods = const <SurveyPeriod>[];
  bool _loading = true;
  String? _loadError;
  String? _formError;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final periods = await widget.client.list(widget.projectId);
      if (!mounted) return;
      setState(() {
        _periods = periods;
        _loading = false;
      });
    } on SurveyPeriodsException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = AppLocalizations.of(context).surveyPeriodsLoadFailed;
      });
    }
  }

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _formError = l10n.surveyPeriodNameRequired);
      return;
    }
    final start = _start.text.trim();
    if (start.isEmpty) {
      setState(() => _formError = l10n.surveyPeriodStartRequired);
      return;
    }
    final end = _end.text.trim();
    if (end.isEmpty) {
      setState(() => _formError = l10n.surveyPeriodEndRequired);
      return;
    }
    final startDate = DateTime.tryParse(start);
    final endDate = DateTime.tryParse(end);
    if (startDate == null || endDate == null) {
      setState(() => _formError = l10n.surveyPeriodInvalidDate);
      return;
    }
    if (endDate.isBefore(startDate)) {
      setState(() => _formError = l10n.surveyPeriodEndBeforeStart);
      return;
    }

    setState(() {
      _formError = null;
      _adding = true;
    });

    try {
      final period = await widget.client.create(
        projectId: widget.projectId,
        name: name,
        startDate: start,
        endDate: end,
      );
      if (!mounted) return;
      setState(() {
        _adding = false;
        _periods = <SurveyPeriod>[..._periods, period];
        _name.clear();
        _start.clear();
        _end.clear();
      });
    } on SurveyPeriodsException {
      if (!mounted) return;
      setState(() {
        _adding = false;
        _formError = l10n.surveyPeriodsAddFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.surveyPeriodsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              key: const Key('survey_periods_list'),
              padding: const EdgeInsets.all(16),
              children: [
                if (widget.isCreator) _buildAddForm(l10n),
                if (_loadError != null)
                  Padding(
                    key: const Key('survey_periods_error'),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _loadError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (_periods.isEmpty)
                  Text(l10n.surveyPeriodsEmpty)
                else
                  for (final period in _periods)
                    ListTile(
                      key: Key('survey_period_${period.id}'),
                      leading: const Icon(Icons.date_range_outlined),
                      title: Text(period.name),
                      subtitle: Text('${period.startDate} – ${period.endDate}'),
                    ),
              ],
            ),
    );
  }

  Widget _buildAddForm(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.surveyPeriodsAddHeading,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('survey_period_add_name'),
          controller: _name,
          decoration: InputDecoration(labelText: l10n.surveyPeriodName),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('survey_period_add_start'),
          controller: _start,
          keyboardType: TextInputType.datetime,
          decoration: InputDecoration(labelText: l10n.surveyPeriodStartDate),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('survey_period_add_end'),
          controller: _end,
          keyboardType: TextInputType.datetime,
          decoration: InputDecoration(labelText: l10n.surveyPeriodEndDate),
        ),
        if (_formError != null)
          Padding(
            key: const Key('survey_period_add_error'),
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _formError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('survey_period_add_submit'),
          onPressed: _adding ? null : _add,
          child: Text(l10n.surveyPeriodsAdd),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
