import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../protocol/protocol.dart';
import '../../store/database_provider.dart';
import '../../store/site_dao.dart';
import '../../widgets/empty_state.dart';
import 'field_site.dart';
import 'site.dart';
import 'site_covariates.dart';
import 'site_editor.dart';
import 'sites_map.dart';

class SitesScreen extends ConsumerStatefulWidget {
  const SitesScreen({
    super.key,
    this.projectId,
    this.protocol,
    this.embedded = false,
  });

  final String? projectId;
  final ProtocolDocument? protocol;

  /// When embedded in the Project hub the screen renders its content inside the
  /// hub's own app bar and tabs, so it keeps its site actions in the body and
  /// omits its standalone app bar.
  final bool embedded;

  @override
  ConsumerState<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends ConsumerState<SitesScreen> {
  void _refresh() {
    final projectId = widget.projectId;
    if (projectId != null) {
      ref.invalidate(projectSitesProvider(projectId));
    }
  }

  Future<void> _openEditor() async {
    final projectId = widget.projectId;
    if (projectId == null) return;
    final dao = ref.read(siteDaoProvider);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SiteEditor(
          dao: dao,
          projectId: projectId,
          onSaved: (_) => _refresh(),
        ),
      ),
    );
  }

  void _openMap() {
    final projectId = widget.projectId;
    if (projectId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SitesMap(projectId: projectId)),
    );
  }

  Future<void> _createHere() async {
    final projectId = widget.projectId;
    if (projectId == null) return;
    final l10n = AppLocalizations.of(context);
    try {
      await createFieldSite(
        locationService: ref.read(locationServiceProvider),
        dao: ref.read(siteDaoProvider),
        projectId: projectId,
      );
      if (!mounted) return;
      _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.sitesCreateHereFailed)));
    }
  }

  Future<void> _openCovariates(Site site) async {
    final protocol = widget.protocol;
    if (protocol == null) return;
    final dao = ref.read(siteDaoProvider);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SiteCovariatesSheet(
        fields: siteCovariateFields(protocol),
        initialValues: site.covariates,
        onSave: (covariates) => _saveCovariates(dao, site, covariates),
      ),
    );
  }

  Future<void> _saveCovariates(
    SiteDao dao,
    Site site,
    List<SiteCovariate> covariates,
  ) async {
    final updated = site.copyWith(covariates: covariates);
    await dao.save(updated);
    if (!mounted) return;
    _refresh();
  }

  String _geometryLabel(AppLocalizations l10n, SiteGeometry geometry) =>
      switch (geometry) {
        PointGeometry() => l10n.siteGeometryPoint,
        LineGeometry() => l10n.siteGeometryLine,
        PolygonGeometry() => l10n.siteGeometryPolygon,
      };

  List<Widget> _actions(AppLocalizations l10n) => [
    IconButton(
      key: const Key('create_site_here'),
      onPressed: _createHere,
      tooltip: l10n.sitesCreateHere,
      icon: const Icon(Icons.my_location_outlined),
    ),
    IconButton(
      key: const Key('open_sites_map'),
      onPressed: _openMap,
      icon: const Icon(Icons.map_outlined),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final projectId = widget.projectId;
    final hasProject = projectId != null;
    final sites = hasProject
        ? ref.watch(projectSitesProvider(projectId)).value ?? const <Site>[]
        : const <Site>[];

    final content = !hasProject
        ? EmptyState(
            title: l10n.projectsEmptyTitle,
            message: l10n.projectsEmptyMessage,
          )
        : sites.isEmpty
        ? EmptyState(
            title: l10n.sitesEmptyTitle,
            message: l10n.sitesEmptyMessage,
          )
        : ListView.builder(
            itemCount: sites.length,
            itemBuilder: (context, index) {
              final site = sites[index];
              return ListTile(
                key: Key('site_${site.id}'),
                leading: const Icon(Icons.place_outlined),
                title: Text(_geometryLabel(l10n, site.geometry)),
                onTap: widget.protocol == null
                    ? null
                    : () => _openCovariates(site),
              );
            },
          );

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(l10n.navSites),
              actions: hasProject ? _actions(l10n) : null,
            ),
      body: widget.embedded && hasProject
          ? Column(
              children: [
                Row(children: _actions(l10n)),
                Expanded(child: content),
              ],
            )
          : content,
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
