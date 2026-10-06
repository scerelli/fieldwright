import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../projects/projects_client.dart';
import '../../widgets/empty_state.dart';
import 'project_editor.dart';

/// Lists the signed-in person's Projects and lets a creator define a new one.
class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  final List<Project> _projects = <Project>[];

  Future<void> _openEditor() async {
    final client = ref.read(projectsClientProvider);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProjectEditor(
          client: client,
          onSaved: (project) => setState(() => _projects.add(project)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navProjects),
        actions: [
          IconButton(
            key: const Key('open_help'),
            icon: const Icon(Icons.help_outline),
            tooltip: l10n.helpOpen,
            onPressed: () => context.push('/help'),
          ),
        ],
      ),
      body: _projects.isEmpty
          ? EmptyState(
              title: l10n.projectsEmptyTitle,
              message: l10n.projectsEmptyMessage,
              action: FilledButton(
                key: const Key('create_project_empty'),
                onPressed: _openEditor,
                child: Text(l10n.projectsCreateProject),
              ),
            )
          : ListView.builder(
              itemCount: _projects.length,
              itemBuilder: (context, index) {
                final project = _projects[index];
                return ProjectCard(
                  key: Key('project_${project.id}'),
                  project: project,
                  onTap: () =>
                      context.go('/projects/${project.id}', extra: project),
                  onPinReference: () =>
                      context.push('/projects/${project.id}/settings'),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        key: const Key('create_project'),
        onPressed: _openEditor,
        tooltip: l10n.projectsCreateProject,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// A Project in the Projects list (`UX.md` UX-022): its name and pinned
/// Taxonomic reference version as basic info, plus the authored description
/// when one is set.
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    this.onTap,
    this.onPinReference,
  });

  final Project project;
  final VoidCallback? onTap;

  /// The pin/download action the UX-034 badge offers; null renders the badge
  /// as plain text (a card outside the list, e.g. a snapshot). The Projects
  /// list wires it to the Project settings surface.
  final VoidCallback? onPinReference;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final description = project.description?.trim();
    final bodyStyle = Theme.of(context).textTheme.bodyLarge;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.folder_outlined),
        title: Text(project.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (project.taxonomicReferenceId == null)
              // UX-034: a Project with no pinned reference carries a
              // non-blocking badge that offers the pin action — never a modal;
              // capture and submission go on with provisional taxa until one is
              // pinned.
              Padding(
                key: Key('project_no_reference_${project.id}'),
                padding: const EdgeInsets.only(top: 4),
                child: onPinReference == null
                    ? Text(
                        l10n.projectCardNoReference,
                        style: bodyStyle?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      )
                    : TextButton.icon(
                        key: Key('project_pin_reference_${project.id}'),
                        onPressed: onPinReference,
                        icon: const Icon(Icons.link_outlined, size: 16),
                        label: Text(l10n.projectCardNoReference),
                      ),
              ),
            if (project.taxonomicReferenceVersion != null)
              Text(project.taxonomicReferenceVersion!, style: bodyStyle),
            if (description != null && description.isNotEmpty)
              Text(description, style: bodyStyle),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

/// The entry point to a Project's configuration surfaces (`ARCHITECTURE.md`):
/// its Protocol version, Members and Survey periods (`DOMAIN.md`).
///
/// Opened from a Project in the Projects list; each entry routes to the
/// matching sub-screen, which navigates back here.
class ProjectDetailScreen extends StatelessWidget {
  const ProjectDetailScreen({super.key, required this.projectId, this.project});

  final String projectId;

  /// The Project when the entry point supplied it; a deep link falls back to
  /// the generic Projects title.
  final Project? project;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(project?.name ?? l10n.navProjects)),
      body: ListView(
        children: [
          ListTile(
            key: const Key('open_protocol_version'),
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.protocolVersionTitle),
            onTap: () => context.go('/projects/$projectId/protocol'),
          ),
          ListTile(
            key: const Key('open_members'),
            leading: const Icon(Icons.people_outline),
            title: Text(l10n.membersTitle),
            onTap: () => context.go('/projects/$projectId/members'),
          ),
          ListTile(
            key: const Key('open_survey_periods'),
            leading: const Icon(Icons.date_range_outlined),
            title: Text(l10n.surveyPeriodsTitle),
            onTap: () => context.go('/projects/$projectId/survey-periods'),
          ),
          ListTile(
            key: const Key('open_project_settings'),
            leading: const Icon(Icons.tune_outlined),
            title: Text(l10n.projectSettingsTitle),
            onTap: () =>
                context.go('/projects/$projectId/settings', extra: project),
          ),
        ],
      ),
    );
  }
}
