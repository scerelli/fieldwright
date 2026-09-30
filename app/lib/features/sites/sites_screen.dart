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
  const SitesScreen({super.key, this.projectId, this.protocol});

  final String? projectId;
  final ProtocolDocument? protocol;

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
      final site = await createFieldSite(
        locationService: ref.read(locationServiceProvider),
        dao: ref.read(siteDaoProvider),
        projectId: projectId,
      );
      if (!mounted) return;
      setState(() => _sites.add(site));
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
    setState(() {
      final index = _sites.indexWhere((candidate) => candidate.id == site.id);
      if (index != -1) _sites[index] = updated;
    });
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
      appBar: AppBar(
        title: Text(l10n.navSites),
        actions: [
          if (hasProject)
            IconButton(
              key: const Key('create_site_here'),
              onPressed: _createHere,
              tooltip: l10n.sitesCreateHere,
              icon: const Icon(Icons.my_location_outlined),
            ),
          if (hasProject)
            IconButton(
              key: const Key('open_sites_map'),
              onPressed: _openMap,
              icon: const Icon(Icons.map_outlined),
            ),
        ],
      ),
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
                  onTap: widget.protocol == null
                      ? null
                      : () => _openCovariates(site),
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
