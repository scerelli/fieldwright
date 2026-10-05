import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../projects/projects_client.dart';

/// The create/edit form for a Project's settings (`DOMAIN.md`): its name,
/// validation, sensitive-taxa obfuscation, and the pinned Taxonomic reference
/// version.
///
/// Invalid settings are reported without a request leaving the device.
class ProjectEditor extends StatefulWidget {
  const ProjectEditor({super.key, required this.client, this.onSaved});

  final ProjectsClient client;
  final ValueChanged<Project>? onSaved;

  @override
  State<ProjectEditor> createState() => _ProjectEditorState();
}

class _ProjectEditorState extends State<ProjectEditor> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _referenceId = TextEditingController();
  final TextEditingController _referenceVersion = TextEditingController();
  bool _validationEnabled = false;
  bool _sensitiveTaxaObfuscation = true;
  String? _nameError;
  String? _referenceIdError;
  String? _referenceVersionError;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _referenceId.dispose();
    _referenceVersion.dispose();
    super.dispose();
  }

  /// Validates each field and reports its error under that field (`UX.md`
  /// UX-025) before any request leaves the device. Returns whether the settings
  /// are valid.
  bool _validate(AppLocalizations l10n) {
    final name = _name.text.trim();
    // The pinned Taxonomic reference is chosen after creation and is an
    // id+version unit, so it is optional here but must be set whole or not at
    // all (DOMAIN.md Project aggregate).
    final referenceId = _referenceId.text.trim();
    final referenceVersion = _referenceVersion.text.trim();

    final nameError = name.isEmpty ? l10n.projectEditorNameRequired : null;
    String? referenceIdError;
    String? referenceVersionError;
    if (referenceId.isNotEmpty && referenceVersion.isEmpty) {
      referenceVersionError = l10n.projectEditorVersionRequired;
    } else if (referenceId.isEmpty && referenceVersion.isNotEmpty) {
      referenceIdError = l10n.projectEditorReferenceRequired;
    }

    setState(() {
      _nameError = nameError;
      _referenceIdError = referenceIdError;
      _referenceVersionError = referenceVersionError;
    });

    return nameError == null &&
        referenceIdError == null &&
        referenceVersionError == null;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_validate(l10n)) return;

    setState(() {
      _error = null;
      _saving = true;
    });

    final referenceId = _referenceId.text.trim();
    final referenceVersion = _referenceVersion.text.trim();

    try {
      final project = await widget.client.create(
        CreateProjectInput(
          name: _name.text.trim(),
          validationEnabled: _validationEnabled,
          sensitiveTaxaObfuscation: _sensitiveTaxaObfuscation,
          taxonomicReferenceId: referenceId.isEmpty ? null : referenceId,
          taxonomicReferenceVersion: referenceVersion.isEmpty
              ? null
              : referenceVersion,
        ),
      );
      if (!mounted) return;
      widget.onSaved?.call(project);
      Navigator.of(context).pop();
    } on ProjectsException {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = l10n.projectEditorCreateFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.projectEditorNewTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const Key('project_name'),
            controller: _name,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
            decoration: InputDecoration(
              labelText: l10n.projectEditorName,
              errorText: _nameError,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('project_reference_id'),
            controller: _referenceId,
            onChanged: (_) {
              if (_referenceIdError != null) {
                setState(() => _referenceIdError = null);
              }
            },
            decoration: InputDecoration(
              labelText: l10n.projectEditorReferenceId,
              errorText: _referenceIdError,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('project_reference_version'),
            controller: _referenceVersion,
            onChanged: (_) {
              if (_referenceVersionError != null) {
                setState(() => _referenceVersionError = null);
              }
            },
            decoration: InputDecoration(
              labelText: l10n.projectEditorReferenceVersion,
              errorText: _referenceVersionError,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            key: const Key('project_validation'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.projectEditorValidation),
            value: _validationEnabled,
            onChanged: (value) => setState(() => _validationEnabled = value),
          ),
          SwitchListTile(
            key: const Key('project_obfuscation'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.projectEditorObfuscation),
            value: _sensitiveTaxaObfuscation,
            onChanged: (value) =>
                setState(() => _sensitiveTaxaObfuscation = value),
          ),
          if (_error != null)
            Padding(
              key: const Key('project_error'),
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('save_project'),
            onPressed: _saving ? null : _save,
            child: Text(l10n.projectEditorSave),
          ),
        ],
      ),
    );
  }
}
