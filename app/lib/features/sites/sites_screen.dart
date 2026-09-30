import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../store/database_provider.dart';
import '../../widgets/empty_state.dart';
import 'site.dart';
import 'site_editor.dart';

class SitesScreen extends ConsumerStatefulWidget {
  const SitesScreen({super.key, this.projectId});

  final String? projectId;

  @override
  ConsumerState<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends ConsumerState<SitesScreen> {
  final List<Site> _sites = <Site>[];

  Future<void> _openEditor() async {
    final projectId = widget.projectId;
    if (projectId == null) return;
    final dao = ref.read(siteDaoProvider);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SiteEditor(
          dao: dao,
          projectId: projectId,
          onSaved: (site) => setState(() => _sites.add(site)),
        ),
      ),
    );
  }

  String _geometryLabel(AppLocalizations l10n, SiteGeometry geometry) =>
      switch (geometry) {
        PointGeometry() => l10n.siteGeometryPoint,
        LineGeometry() => l10n.siteGeometryLine,
        PolygonGeometry() => l10n.siteGeometryPolygon,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasProject = widget.projectId != null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSites)),
      body: !hasProject
          ? EmptyState(
              title: l10n.projectsEmptyTitle,
              message: l10n.projectsEmptyMessage,
            )
          : _sites.isEmpty
          ? EmptyState(
              title: l10n.sitesEmptyTitle,
              message: l10n.sitesEmptyMessage,
            )
          : ListView.builder(
              itemCount: _sites.length,
              itemBuilder: (context, index) {
                final site = _sites[index];
                return ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(_geometryLabel(l10n, site.geometry)),
                );
              },
            ),
      floatingActionButton: hasProject
          ? FloatingActionButton(
              onPressed: _openEditor,
              tooltip: l10n.sitesAddSite,
              child: const Icon(Icons.add_location_alt_outlined),
            )
          : null,
    );
  }
}
