import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navProjects)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.projectsCount(_count)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => setState(() => _count++),
              child: Text(l10n.incrementProjects),
            ),
          ],
        ),
      ),
    );
  }
}
