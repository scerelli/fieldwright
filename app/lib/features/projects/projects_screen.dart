import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      appBar: AppBar(title: Text(l10n.navProjects)),
      body: _projects.isEmpty
          ? EmptyState(
              title: l10n.projectsEmptyTitle,
              message: l10n.projectsEmptyMessage,
            )
          : ListView.builder(
              itemCount: _projects.length,
              itemBuilder: (context, index) {
                final project = _projects[index];
                return ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(project.name),
                  subtitle: Text(project.taxonomicReferenceVersion),
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
