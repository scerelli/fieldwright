import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../protocol/protocol.dart';
import '../../protocol_versions/protocol_versions_client.dart';

/// Defines a Protocol version for a Project, or shows a frozen one read-only
/// with the option to define a new version (`DOMAIN.md`, `ARCHITECTURE.md`).
///
/// A frozen version is immutable (INV-007): a change is submitted as a new
/// version, so the frozen view stays read-only and offers "create a new
/// version". The form validates every required field before any request leaves
/// the device.
class ProtocolVersionScreen extends StatefulWidget {
  const ProtocolVersionScreen({
    super.key,
    required this.client,
    required this.projectId,
    this.version,
    this.onSaved,
  });

  final ProtocolVersionsClient client;
  final String projectId;

  /// The version to show. A frozen one is read-only; a draft or none is
  /// editable.
  final ProtocolVersion? version;
  final ValueChanged<ProtocolVersion>? onSaved;

  @override
  State<ProtocolVersionScreen> createState() => _ProtocolVersionScreenState();
}

class _ProtocolVersionScreenState extends State<ProtocolVersionScreen> {
  late final TextEditingController _protocolId;
  late final TextEditingController _scope;
  late final TextEditingController _targetList;
  late final TextEditingController _detectionMethods;
  late final TextEditingController _visitCovariates;
  late final TextEditingController _siteCovariates;
  final Set<SamplingEffortField> _effortFields = <SamplingEffortField>{};
  bool _completeListMode = false;
  late bool _editing;
  ProtocolVersion? _displayed;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _displayed = widget.version;
    _editing = !(widget.version?.isFrozen ?? false);

    final document = widget.version?.document;
    _protocolId = TextEditingController(text: document?.protocolId ?? '');
    _scope = TextEditingController(
      text: document?.taxonomicScope.taxa.join(', ') ?? '',
    );
    _completeListMode = document != null && document.targetList == null;
    _targetList = TextEditingController(
      text: _targetListText(document?.targetList),
    );
    _detectionMethods = TextEditingController(
      text: _detectionMethodsText(document?.detectionMethods),
    );
    _effortFields.addAll(document?.requiredEffortFields ?? const []);
    _visitCovariates = TextEditingController(
      text: _covariatesText(document?.visitCovariates),
    );
    _siteCovariates = TextEditingController(
      text: _covariatesText(document?.siteCovariates),
    );
  }

  @override
  void dispose() {
    _protocolId.dispose();
    _scope.dispose();
    _targetList.dispose();
    _detectionMethods.dispose();
    _visitCovariates.dispose();
    _siteCovariates.dispose();
    super.dispose();
  }

  List<String> get _scopeTaxa => _scope.text
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();

  List<SamplingEffortField> get _orderedEffortFields =>
      SamplingEffortField.values.where(_effortFields.contains).toList();

  String? _validationError({
    required AppLocalizations l10n,
    required List<String> scope,
    required List<TargetTaxon> targets,
    required List<DetectionMethod> methods,
  }) {
    if (_protocolId.text.trim().isEmpty) {
      return l10n.protocolVersionProtocolIdRequired;
    }
    if (scope.isEmpty) return l10n.protocolVersionScopeRequired;
    if (!_completeListMode && targets.isEmpty) {
      return l10n.protocolVersionTargetListRequired;
    }
    if (methods.isEmpty) return l10n.protocolVersionDetectionMethodsRequired;
    if (_effortFields.isEmpty) return l10n.protocolVersionEffortRequired;
    return null;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final scope = _scopeTaxa;
    final targets = _parseTargetList(_targetList.text);
    final methods = _parseDetectionMethods(_detectionMethods.text);

    final List<CovariateDefinition> visitCovariates;
    final List<CovariateDefinition> siteCovariates;
    try {
      visitCovariates = _parseCovariates(_visitCovariates.text);
      siteCovariates = _parseCovariates(_siteCovariates.text);
    } on FormatException {
      setState(() => _error = l10n.protocolVersionInvalidCovariates);
      return;
    }

    final error = _validationError(
      l10n: l10n,
      scope: scope,
      targets: targets,
      methods: methods,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() {
      _error = null;
      _saving = true;
    });

    final document = ProtocolDocument(
      protocolId: _protocolId.text.trim(),
      version: (_displayed?.document.version ?? 0) + 1,
      taxonomicScope: TaxonomicScope(taxa: scope),
      detectionMethods: methods,
      requiredEffortFields: _orderedEffortFields,
      targetList: _completeListMode ? null : targets,
      visitCovariates: visitCovariates.isEmpty ? null : visitCovariates,
      siteCovariates: siteCovariates.isEmpty ? null : siteCovariates,
    );

    try {
      final saved = await widget.client.create(
        projectId: widget.projectId,
        document: document,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _displayed = saved;
        _editing = !saved.isFrozen;
      });
      widget.onSaved?.call(saved);
    } on ProtocolVersionsException {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = l10n.protocolVersionCreateFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final displayed = _displayed;
    final showForm = _editing || displayed == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          showForm ? l10n.protocolVersionNewTitle : l10n.protocolVersionTitle,
        ),
      ),
      body: showForm ? _buildForm(l10n) : _buildReadOnly(l10n, displayed),
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          key: const Key('protocol_id'),
          controller: _protocolId,
          decoration: InputDecoration(
            labelText: l10n.protocolVersionProtocolId,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('taxonomic_scope'),
          controller: _scope,
          decoration: InputDecoration(
            labelText: l10n.protocolVersionTaxonomicScope,
          ),
        ),
        SwitchListTile(
          key: const Key('complete_list_mode'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.protocolVersionCompleteListMode),
          value: _completeListMode,
          onChanged: (value) => setState(() => _completeListMode = value),
        ),
        if (!_completeListMode)
          TextField(
            key: const Key('target_list'),
            controller: _targetList,
            minLines: 2,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: l10n.protocolVersionTargetList,
            ),
          ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('detection_methods'),
          controller: _detectionMethods,
          minLines: 2,
          maxLines: 6,
          decoration: InputDecoration(
            labelText: l10n.protocolVersionDetectionMethods,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.protocolVersionRequiredEffort,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        CheckboxListTile(
          key: const Key('effort_start'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.effortFieldStart),
          value: _effortFields.contains(SamplingEffortField.start),
          onChanged: (value) => _toggleEffort(SamplingEffortField.start, value),
        ),
        CheckboxListTile(
          key: const Key('effort_duration'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.effortFieldDuration),
          value: _effortFields.contains(SamplingEffortField.duration),
          onChanged: (value) =>
              _toggleEffort(SamplingEffortField.duration, value),
        ),
        CheckboxListTile(
          key: const Key('effort_observers'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.effortFieldObservers),
          value: _effortFields.contains(SamplingEffortField.observers),
          onChanged: (value) =>
              _toggleEffort(SamplingEffortField.observers, value),
        ),
        CheckboxListTile(
          key: const Key('effort_detection_methods'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.effortFieldDetectionMethods),
          value: _effortFields.contains(SamplingEffortField.detectionMethods),
          onChanged: (value) =>
              _toggleEffort(SamplingEffortField.detectionMethods, value),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('visit_covariates'),
          controller: _visitCovariates,
          minLines: 1,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: l10n.protocolVersionVisitCovariates,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('site_covariates'),
          controller: _siteCovariates,
          minLines: 1,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: l10n.protocolVersionSiteCovariates,
          ),
        ),
        if (_error != null)
          Padding(
            key: const Key('protocol_version_error'),
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('save_protocol_version'),
          onPressed: _saving ? null : _save,
          child: Text(l10n.protocolVersionSave),
        ),
      ],
    );
  }

  Widget _buildReadOnly(AppLocalizations l10n, ProtocolVersion version) {
    final document = version.document;
    return ListView(
      key: const Key('protocol_version_readonly'),
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Chip(
            key: const Key('frozen_badge'),
            avatar: const Icon(Icons.lock_outline),
            label: Text(l10n.protocolVersionFrozen),
          ),
        ),
        const SizedBox(height: 8),
        Text(l10n.protocolVersionVersion(document.version)),
        const SizedBox(height: 16),
        _readOnlyRow(l10n.protocolVersionProtocolId, document.protocolId),
        _readOnlyRow(
          l10n.protocolVersionTaxonomicScope,
          document.taxonomicScope.taxa.join(', '),
        ),
        _readOnlyRow(
          l10n.protocolVersionCompleteListMode,
          document.targetList == null
              ? l10n.protocolVersionCompleteListMode
              : l10n.protocolVersionTargetList,
        ),
        if (document.targetList != null)
          _readOnlyRow(
            l10n.protocolVersionTargetList,
            document.targetList!
                .map((taxon) => taxon.label ?? taxon.taxonRef)
                .join(', '),
          ),
        _readOnlyRow(
          l10n.protocolVersionDetectionMethods,
          document.detectionMethods.map((method) => method.label).join(', '),
        ),
        _readOnlyRow(
          l10n.protocolVersionRequiredEffort,
          document.requiredEffortFields
              .map((field) => _effortLabel(l10n, field))
              .join(', '),
        ),
        _readOnlyRow(
          l10n.protocolVersionVisitCovariates,
          _covariatesText(document.visitCovariates),
        ),
        _readOnlyRow(
          l10n.protocolVersionSiteCovariates,
          _covariatesText(document.siteCovariates),
        ),
        const SizedBox(height: 8),
        Text(l10n.protocolVersionReadOnly),
        const SizedBox(height: 24),
        if (version.isFrozen)
          FilledButton(
            key: const Key('create_new_version'),
            onPressed: () => setState(() => _editing = true),
            child: Text(l10n.protocolVersionCreateNew),
          ),
      ],
    );
  }

  Widget _readOnlyRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text('$label: $value'),
  );

  void _toggleEffort(SamplingEffortField field, bool? selected) {
    setState(() {
      if (selected ?? false) {
        _effortFields.add(field);
      } else {
        _effortFields.remove(field);
      }
    });
  }
}

String _effortLabel(AppLocalizations l10n, SamplingEffortField field) =>
    switch (field) {
      SamplingEffortField.start => l10n.effortFieldStart,
      SamplingEffortField.duration => l10n.effortFieldDuration,
      SamplingEffortField.observers => l10n.effortFieldObservers,
      SamplingEffortField.detectionMethods => l10n.effortFieldDetectionMethods,
    };

String _targetListText(List<TargetTaxon>? targets) =>
    (targets ?? const <TargetTaxon>[])
        .map(
          (target) => target.label == null
              ? target.taxonRef
              : '${target.taxonRef} = ${target.label}',
        )
        .join('\n');

String _detectionMethodsText(List<DetectionMethod>? methods) =>
    (methods ?? const <DetectionMethod>[])
        .map((method) => '${method.id} = ${method.label}')
        .join('\n');

String _covariatesText(List<CovariateDefinition>? covariates) =>
    (covariates ?? const <CovariateDefinition>[])
        .map((covariate) {
          final tail = covariate.type == CovariateDefinitionType.enumValue
              ? covariate.options?.join(',')
              : covariate.unit;
          return tail == null || tail.isEmpty
              ? '${covariate.name}:${covariate.type.toJson()}'
              : '${covariate.name}:${covariate.type.toJson()}:$tail';
        })
        .join('\n');

/// Parses one `taxonRef` (with an optional `= label`) per line.
List<TargetTaxon> _parseTargetList(String text) {
  final targets = <TargetTaxon>[];
  for (final line in text.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    final separator = trimmed.indexOf('=');
    if (separator == -1) {
      targets.add(TargetTaxon(taxonRef: trimmed));
      continue;
    }
    final ref = trimmed.substring(0, separator).trim();
    final label = trimmed.substring(separator + 1).trim();
    if (ref.isEmpty) continue;
    targets.add(
      TargetTaxon(taxonRef: ref, label: label.isEmpty ? null : label),
    );
  }
  return targets;
}

/// Parses one `id = label` (or bare `id`) per line.
List<DetectionMethod> _parseDetectionMethods(String text) {
  final methods = <DetectionMethod>[];
  for (final line in text.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    final separator = trimmed.indexOf('=');
    final id = separator == -1
        ? trimmed
        : trimmed.substring(0, separator).trim();
    final label = separator == -1
        ? trimmed
        : trimmed.substring(separator + 1).trim();
    if (id.isEmpty) continue;
    methods.add(DetectionMethod(id: id, label: label.isEmpty ? id : label));
  }
  return methods;
}

/// Parses one `name:type[:unit]` per line; a `enum` covariate's tail holds its
/// comma-separated options. Throws [FormatException] on an unparseable line.
List<CovariateDefinition> _parseCovariates(String text) {
  final covariates = <CovariateDefinition>[];
  for (final line in text.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;

    final parts = trimmed.split(':');
    final name = parts.first.trim();
    if (name.isEmpty || parts.length < 2) {
      throw const FormatException('Unparseable covariate definition');
    }
    final type = CovariateDefinitionType.fromJson(parts[1].trim());
    final tail = parts.length > 2 ? parts.sublist(2).join(':').trim() : null;

    if (type == CovariateDefinitionType.enumValue) {
      final options = (tail ?? '')
          .split(',')
          .map((option) => option.trim())
          .where((option) => option.isNotEmpty)
          .toList();
      if (options.isEmpty) {
        throw const FormatException('An enum covariate needs options');
      }
      covariates.add(
        CovariateDefinition(name: name, type: type, options: options),
      );
    } else {
      covariates.add(
        CovariateDefinition(
          name: name,
          type: type,
          unit: tail == null || tail.isEmpty ? null : tail,
        ),
      );
    }
  }
  return covariates;
}
