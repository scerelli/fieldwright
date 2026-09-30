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
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _referenceId.dispose();
    _referenceVersion.dispose();
    super.dispose();
  }

  String? _validationError(AppLocalizations l10n) {
    if (_name.text.trim().isEmpty) return l10n.projectEditorNameRequired;
    if (_referenceId.text.trim().isEmpty) {
      return l10n.projectEditorReferenceRequired;
    }
    if (_referenceVersion.text.trim().isEmpty) {
      return l10n.projectEditorVersionRequired;
    }
    return null;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final error = _validationError(l10n);
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() {
      _error = null;
      _saving = true;
    });

    try {
      final project = await widget.client.create(
        CreateProjectInput(
          name: _name.text.trim(),
          validationEnabled: _validationEnabled,
          sensitiveTaxaObfuscation: _sensitiveTaxaObfuscation,
          taxonomicReferenceId: _referenceId.text.trim(),
          taxonomicReferenceVersion: _referenceVersion.text.trim(),
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
            decoration: InputDecoration(labelText: l10n.projectEditorName),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('project_reference_id'),
            controller: _referenceId,
            decoration: InputDecoration(
              labelText: l10n.projectEditorReferenceId,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('project_reference_version'),
            controller: _referenceVersion,
            decoration: InputDecoration(
              labelText: l10n.projectEditorReferenceVersion,
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
