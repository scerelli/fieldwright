import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../projects/projects_client.dart';
import '../../store/project_dao.dart';

/// The create/edit form for a Project's settings (`DOMAIN.md`): its name,
/// validation, sensitive-taxa obfuscation, and the pinned Taxonomic reference
/// version.
///
/// It runs in one of two modes: creation, through [ProjectsClient], or the
/// settings surface for an existing Project, through [ProjectDao] — the same
/// local aggregate creation and the config pull write (`ARCHITECTURE.md`,
/// ADR-0002). Invalid settings are reported without a request leaving the
/// device.
class ProjectEditor extends StatefulWidget {
  const ProjectEditor({
    super.key,
    this.client,
    this.dao,
    this.initial,
    this.onSaved,
  }) : assert(
         (client == null) != (dao == null),
         'ProjectEditor takes exactly one of client (create) or dao (settings)',
       ),
       assert(
         initial == null || dao != null,
         'Editing an existing Project takes a dao',
       );

  /// The create path: the server assigns identity and creator Membership.
  final ProjectsClient? client;

  /// The settings path: the existing Project is stored in the local aggregate.
  final ProjectDao? dao;

  /// The Project being configured on the settings surface, or null when
  /// creating one.
  final Project? initial;

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
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _name.text = initial.name;
      _referenceId.text = initial.taxonomicReferenceId ?? '';
      _referenceVersion.text = initial.taxonomicReferenceVersion ?? '';
      _validationEnabled = initial.validationEnabled;
      _sensitiveTaxaObfuscation = initial.sensitiveTaxaObfuscation;
    }
  }

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

    final initial = widget.initial;
    if (initial == null) {
      await _create(l10n);
    } else {
      await _saveSettings(initial, l10n);
    }
  }

  Future<void> _create(AppLocalizations l10n) async {
    final referenceId = _referenceId.text.trim();
    final referenceVersion = _referenceVersion.text.trim();

    try {
      final project = await widget.client!.create(
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
      _close();
    } on ProjectsException {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = l10n.projectEditorCreateFailed;
      });
    }
  }

  Future<void> _saveSettings(Project initial, AppLocalizations l10n) async {
    final referenceId = _referenceId.text.trim();
    final referenceVersion = _referenceVersion.text.trim();

    final project = Project(
      id: initial.id,
      name: _name.text.trim(),
      description: initial.description,
      validationEnabled: _validationEnabled,
      sensitiveTaxaObfuscation: _sensitiveTaxaObfuscation,
      taxonomicReferenceId: referenceId.isEmpty ? null : referenceId,
      taxonomicReferenceVersion: referenceVersion.isEmpty
          ? null
          : referenceVersion,
    );

    try {
      await widget.dao!.save(project);
    } on Exception catch (_) {
      // A store failure (an Exception) is reported; a programming Error is not
      // swallowed (CONVENTIONS.md — fail loud, never guess).
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = l10n.projectEditorSaveFailed;
      });
      return;
    }
    if (!mounted) return;
    widget.onSaved?.call(project);
    _close();
  }

  void _close() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSettings = widget.initial != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSettings ? l10n.projectSettingsTitle : l10n.projectEditorNewTitle,
        ),
      ),
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
              helperText: l10n.projectEditorReferenceIdHelper,
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
              helperText: l10n.projectEditorReferenceVersionHelper,
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

/// The Project settings surface (`DOMAIN.md` Project aggregate), reached from
/// inside a Project (`UX.md` UX-019): its pinned Taxonomic reference and
/// validation and sensitive-taxa obfuscation settings, stored in the local
/// Project aggregate through [ProjectDao].
///
/// The Project is supplied by the hub; a deep link with none loads it from the
/// local store by [projectId].
class ProjectSettingsScreen extends ConsumerStatefulWidget {
  const ProjectSettingsScreen({
    super.key,
    required this.projectId,
    this.initial,
  });

  final String projectId;

  /// The Project the hub supplied, or null when reached without one.
  final Project? initial;

  @override
  ConsumerState<ProjectSettingsScreen> createState() =>
      _ProjectSettingsScreenState();
}

class _ProjectSettingsScreenState extends ConsumerState<ProjectSettingsScreen> {
  Project? _project;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _project = initial;
    } else {
      _loading = true;
      _load();
    }
  }

  Future<void> _load() async {
    final project = await ref
        .read(projectDaoProvider)
        .findById(widget.projectId);
    if (!mounted) return;
    setState(() {
      _project = project;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final project = _project;
    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.projectSettingsTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.projectSettingsNotFound),
          ),
        ),
      );
    }
    return ProjectEditor(dao: ref.read(projectDaoProvider), initial: project);
  }
}
