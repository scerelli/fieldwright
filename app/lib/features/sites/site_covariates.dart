import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../protocol/protocol.dart';
import 'site.dart';

/// The Site covariate fields a Protocol version offers: exactly its
/// site-covariate definitions, never its visit-covariate ones.
List<CovariateDefinition> siteCovariateFields(ProtocolDocument document) =>
    List<CovariateDefinition>.unmodifiable(
      document.siteCovariates ?? const <CovariateDefinition>[],
    );

/// Builds a Site covariate value from an entered [value] and its provenance.
/// A value without a method is invalid (INV-010) and is rejected.
SiteCovariate? buildSiteCovariate({
  required CovariateDefinition field,
  required String value,
  required CovariateMethod? method,
}) {
  if (method == null) return null;
  return SiteCovariate(
    name: field.name,
    value: value,
    unit: field.unit,
    provenance: CovariateProvenance(method: method),
  );
}

class SiteCovariatesSheet extends StatefulWidget {
  const SiteCovariatesSheet({
    super.key,
    required this.fields,
    required this.initialValues,
    required this.onSave,
  });

  final List<CovariateDefinition> fields;
  final List<SiteCovariate> initialValues;
  final ValueChanged<List<SiteCovariate>> onSave;

  @override
  State<SiteCovariatesSheet> createState() => _SiteCovariatesSheetState();
}

class _SiteCovariatesSheetState extends State<SiteCovariatesSheet> {
  late final Map<String, TextEditingController> _values;
  late final Map<String, CovariateMethod?> _methods;
  String? _error;

  @override
  void initState() {
    super.initState();
    _values = {
      for (final field in widget.fields)
        field.name: TextEditingController(
          text: _initialValue(field.name)?.value ?? '',
        ),
    };
    _methods = {
      for (final field in widget.fields)
        field.name: _initialValue(field.name)?.provenance.method,
    };
  }

  SiteCovariate? _initialValue(String name) {
    for (final covariate in widget.initialValues) {
      if (covariate.name == name) return covariate;
    }
    return null;
  }

  @override
  void dispose() {
    for (final controller in _values.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    final result = <SiteCovariate>[];
    for (final field in widget.fields) {
      final value = _values[field.name]!.text.trim();
      if (value.isEmpty) continue;
      final covariate = buildSiteCovariate(
        field: field,
        value: value,
        method: _methods[field.name],
      );
      if (covariate == null) {
        setState(
          () =>
              _error = AppLocalizations.of(context).siteCovariatesMissingMethod,
        );
        return;
      }
      result.add(covariate);
    }
    widget.onSave(result);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.siteCovariatesTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (widget.fields.isEmpty)
                Text(l10n.siteCovariatesNone)
              else
                for (final field in widget.fields) _buildField(field, l10n),
              if (_error != null)
                Padding(
                  key: const Key('covariates_error'),
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('covariates_save'),
                onPressed: _save,
                child: Text(l10n.siteCovariatesSave),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(CovariateDefinition field, AppLocalizations l10n) {
    final label = field.unit == null
        ? field.name
        : '${field.name} (${field.unit})';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: Key('covariate_value_${field.name}'),
            controller: _values[field.name],
            decoration: InputDecoration(labelText: label),
          ),
          const SizedBox(height: 8),
          DropdownButton<CovariateMethod>(
            key: Key('covariate_method_${field.name}'),
            value: _methods[field.name],
            hint: Text(l10n.siteCovariatesMethod),
            onChanged: (method) =>
                setState(() => _methods[field.name] = method),
            items: [
              for (final method in CovariateMethod.values)
                DropdownMenuItem(
                  value: method,
                  child: Text(_methodLabel(l10n, method)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _methodLabel(AppLocalizations l10n, CovariateMethod method) =>
      switch (method) {
        CovariateMethod.phoneSensor => l10n.covariateMethodPhoneSensor,
        CovariateMethod.fieldInstrument => l10n.covariateMethodFieldInstrument,
        CovariateMethod.visualEstimate => l10n.covariateMethodVisualEstimate,
      };
}
