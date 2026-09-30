import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../store/site_dao.dart';
import 'site.dart';

enum SiteGeometryKind { point, line, polygon }

int _minimumVertices(SiteGeometryKind kind) => switch (kind) {
  SiteGeometryKind.point => 1,
  SiteGeometryKind.line => 2,
  SiteGeometryKind.polygon => 3,
};

int _distinctVertexCount(List<LatLng> vertices) => vertices
    .map((vertex) => '${vertex.latitude},${vertex.longitude}')
    .toSet()
    .length;

SiteGeometry? parseSiteGeometry(SiteGeometryKind kind, List<LatLng> vertices) {
  switch (kind) {
    case SiteGeometryKind.point:
      if (vertices.length != 1) return null;
      return PointGeometry(vertices.single);
    case SiteGeometryKind.line:
      if (_distinctVertexCount(vertices) < 2) return null;
      return LineGeometry(List<LatLng>.unmodifiable(vertices));
    case SiteGeometryKind.polygon:
      if (_distinctVertexCount(vertices) < 3) return null;
      final first = vertices.first;
      final last = vertices.last;
      final closed = first == last ? vertices : <LatLng>[...vertices, first];
      return PolygonGeometry(List<LatLng>.unmodifiable(closed));
  }
}

SiteGeometryKind? _kindOf(SiteGeometry? geometry) => switch (geometry) {
  PointGeometry() => SiteGeometryKind.point,
  LineGeometry() => SiteGeometryKind.line,
  PolygonGeometry() => SiteGeometryKind.polygon,
  null => null,
};

List<LatLng>? _verticesOf(SiteGeometry? geometry) => switch (geometry) {
  PointGeometry(:final point) => <LatLng>[point],
  LineGeometry(:final points) => points,
  PolygonGeometry(:final ring) =>
    ring.length > 1 && ring.first == ring.last
        ? ring.sublist(0, ring.length - 1)
        : ring,
  null => null,
};

class SiteEditor extends StatefulWidget {
  const SiteEditor({
    super.key,
    required this.dao,
    required this.projectId,
    this.initialSite,
    this.onSaved,
  });

  final SiteDao dao;
  final String projectId;
  final Site? initialSite;
  final ValueChanged<Site>? onSaved;

  @override
  State<SiteEditor> createState() => _SiteEditorState();
}

class _VertexControllers {
  final TextEditingController latitude = TextEditingController();
  final TextEditingController longitude = TextEditingController();

  void dispose() {
    latitude.dispose();
    longitude.dispose();
  }
}

class _SiteEditorState extends State<SiteEditor> {
  final Random _random = Random();
  late SiteGeometryKind _kind;
  late final List<_VertexControllers> _vertices;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSite;
    _kind = _kindOf(initial?.geometry) ?? SiteGeometryKind.point;
    _vertices = <_VertexControllers>[
      for (final vertex in _verticesOf(initial?.geometry) ?? const <LatLng>[])
        _VertexControllers()
          ..latitude.text = '${vertex.latitude}'
          ..longitude.text = '${vertex.longitude}',
    ];
    _fillToMinimum();
  }

  @override
  void dispose() {
    for (final vertex in _vertices) {
      vertex.dispose();
    }
    super.dispose();
  }

  void _fillToMinimum() {
    while (_vertices.length < _minimumVertices(_kind)) {
      _vertices.add(_VertexControllers());
    }
  }

  void _selectKind(SiteGeometryKind kind) {
    setState(() {
      _kind = kind;
      _fillToMinimum();
    });
  }

  void _addVertex() {
    setState(() => _vertices.add(_VertexControllers()));
  }

  void _removeVertex(int index) {
    if (_vertices.length <= _minimumVertices(_kind)) return;
    setState(() {
      _vertices.removeAt(index).dispose();
    });
  }

  LatLng? _parseVertex(_VertexControllers vertex) {
    final latitude = double.tryParse(vertex.latitude.text.trim());
    final longitude = double.tryParse(vertex.longitude.text.trim());
    if (latitude == null || longitude == null) return null;
    if (latitude < -90 || latitude > 90) return null;
    if (longitude < -180 || longitude > 180) return null;
    return LatLng(latitude, longitude);
  }

  SiteGeometry? _buildGeometry() {
    final vertices = <LatLng>[];
    for (final vertex in _vertices) {
      final point = _parseVertex(vertex);
      if (point == null) return null;
      vertices.add(point);
    }
    return parseSiteGeometry(_kind, vertices);
  }

  String _newId() {
    final microseconds = DateTime.now().toUtc().microsecondsSinceEpoch;
    final suffix = _random.nextInt(1 << 32).toRadixString(16);
    return '${microseconds.toRadixString(16)}-$suffix';
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final geometry = _buildGeometry();
    if (geometry == null) {
      setState(() => _error = l10n.siteEditorInvalidGeometry);
      return;
    }

    setState(() {
      _error = null;
      _saving = true;
    });

    final initial = widget.initialSite;
    final site = Site(
      id: initial?.id ?? _newId(),
      projectId: initial?.projectId ?? widget.projectId,
      geometry: geometry,
      origin: initial?.origin ?? SiteOrigin.planned,
      createdAt: initial?.createdAt ?? DateTime.now().toUtc(),
    );
    await widget.dao.save(site);
    if (!mounted) return;
    widget.onSaved?.call(site);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isUpdate = widget.initialSite != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isUpdate ? l10n.siteEditorUpdateTitle : l10n.siteEditorNewTitle,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<SiteGeometryKind>(
            segments: [
              ButtonSegment(
                value: SiteGeometryKind.point,
                label: Text(
                  l10n.siteGeometryPoint,
                  key: const Key('geometry_point'),
                ),
              ),
              ButtonSegment(
                value: SiteGeometryKind.line,
                label: Text(
                  l10n.siteGeometryLine,
                  key: const Key('geometry_line'),
                ),
              ),
              ButtonSegment(
                value: SiteGeometryKind.polygon,
                label: Text(
                  l10n.siteGeometryPolygon,
                  key: const Key('geometry_polygon'),
                ),
              ),
            ],
            selected: <SiteGeometryKind>{_kind},
            onSelectionChanged: (selection) => _selectKind(selection.first),
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < _vertices.length; index++)
            _buildVertexRow(index, l10n),
          if (_kind != SiteGeometryKind.point)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('add_vertex'),
                onPressed: _addVertex,
                icon: const Icon(Icons.add),
                label: Text(l10n.siteEditorAddVertex),
              ),
            ),
          if (_error != null)
            Padding(
              key: const Key('geometry_error'),
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: TextStyle(color: colorScheme.error)),
            ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('save_site'),
            onPressed: _saving ? null : _save,
            child: Text(l10n.siteEditorSave),
          ),
        ],
      ),
    );
  }

  Widget _buildVertexRow(int index, AppLocalizations l10n) {
    final vertex = _vertices[index];
    final removable =
        _kind != SiteGeometryKind.point &&
        _vertices.length > _minimumVertices(_kind);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              key: Key('latitude_$index'),
              controller: vertex.latitude,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(labelText: l10n.siteEditorLatitude),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              key: Key('longitude_$index'),
              controller: vertex.longitude,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(labelText: l10n.siteEditorLongitude),
            ),
          ),
          if (removable)
            IconButton(
              key: Key('remove_vertex_$index'),
              tooltip: l10n.siteEditorRemoveVertex,
              onPressed: () => _removeVertex(index),
              icon: const Icon(Icons.remove_circle_outline),
            ),
        ],
      ),
    );
  }
}
