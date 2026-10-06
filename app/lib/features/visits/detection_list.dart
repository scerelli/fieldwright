import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../protocol/protocol.dart';
import '../../store/detection_dao.dart';
import 'detection.dart';
import 'evidence_capture.dart';
import 'opportunistic_search.dart';
import 'submission_readiness.dart';
import 'taxon_reference.dart';

/// The capture-screen control for marking each target taxon of the Protocol
/// detected or not detected (UX-003). A target with no Detection shows a
/// visibly distinct "not recorded" state; the [detectionNextUnrecorded] button
/// brings the next unrecorded target into view in one tap (UX-004). The Visit
/// is reported incomplete while any target is unrecorded (INV-019).
class DetectionList extends ConsumerStatefulWidget {
  const DetectionList({
    super.key,
    required this.protocol,
    required this.visitId,
  });

  final ProtocolDocument protocol;
  final String visitId;

  @override
  ConsumerState<DetectionList> createState() => _DetectionListState();
}

class _DetectionListState extends ConsumerState<DetectionList> {
  final Map<String, GlobalKey> _rowKeys = <String, GlobalKey>{};
  List<Detection> _detections = const <Detection>[];
  String? _activeTaxonRef;

  /// The Detection method the next Detection is recorded with — chosen from
  /// the Protocol version's `detectionMethods` (GLOSSARY.md › Detection
  /// method). Recording is unavailable until one is chosen.
  String? _methodId;

  List<TargetTaxon> get _targets => requiredTargetTaxa(widget.protocol);

  List<DetectionMethod> get _methods => widget.protocol.detectionMethods;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final detections = await ref
        .read(detectionDaoProvider)
        .forVisit(widget.visitId);
    if (!mounted) return;
    setState(() => _detections = detections);
  }

  List<Detection> get _targetDetections => _detections
      .where((detection) => !detection.opportunistic)
      .toList(growable: false);

  List<Detection> get _opportunisticDetections => _detections
      .where((detection) => detection.opportunistic)
      .toList(growable: false);

  Detection? _detectionFor(String taxonRef) {
    for (final detection in _targetDetections) {
      if (detection.taxonRef == taxonRef) return detection;
    }
    return null;
  }

  Future<void> _record(TargetTaxon target, bool detected) async {
    final method = _methodId;
    if (method == null) return;
    await ref
        .read(detectionDaoProvider)
        .record(
          Detection(
            visitId: widget.visitId,
            taxonRef: target.taxonRef,
            detected: detected,
            method: method,
          ),
        );
    await _load();
  }

  Future<void> _recordOpportunistic(Taxon taxon) async {
    final method = _methodId;
    if (method == null) return;
    await ref
        .read(detectionDaoProvider)
        .record(
          Detection.opportunistic(
            visitId: widget.visitId,
            taxonRef: taxon.name,
            method: method,
          ),
        );
    await _load();
  }

  void _goToNextUnrecorded() {
    final unrecorded = unrecordedTargets(_targets, _detections);
    if (unrecorded.isEmpty) return;
    final next = unrecorded.first;
    setState(() => _activeTaxonRef = next.taxonRef);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _rowKeys[next.taxonRef]?.currentContext;
      if (context != null && Scrollable.maybeOf(context) != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 200),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final targets = _targets;
    final unrecorded = unrecordedTargets(targets, _detections);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.detectionTargetsHeading,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButton<String>(
          key: const Key('detection_method'),
          value: _methodId,
          isExpanded: true,
          hint: Text(l10n.measurementMethod),
          onChanged: _methods.isEmpty
              ? null
              : (method) => setState(() => _methodId = method),
          items: [
            for (final method in _methods)
              DropdownMenuItem<String>(
                value: method.id,
                child: Text(method.label),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (targets.isEmpty)
          Text(l10n.detectionNoTargets)
        else ...[
          for (final target in targets) _buildTarget(target, l10n),
          const SizedBox(height: 12),
          if (unrecorded.isNotEmpty) ...[
            FilledButton.icon(
              key: const Key('detection_next_unrecorded'),
              onPressed: _goToNextUnrecorded,
              icon: const Icon(Icons.keyboard_arrow_down),
              label: Text(l10n.detectionNextUnrecorded),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.visitIncomplete(unrecorded.length),
              key: const Key('visit_incomplete'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ] else
            Text(
              l10n.visitAllTargetsRecorded,
              key: const Key('visit_complete'),
            ),
        ],
        const Divider(height: 32),
        Text(
          l10n.opportunisticHeading,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final detection in _opportunisticDetections)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                key: Key('opportunistic_entry_${detection.taxonRef}'),
                contentPadding: EdgeInsets.zero,
                title: Text(detection.taxonRef),
                trailing: Text(l10n.opportunisticPresenceOnly),
              ),
              EvidenceCapture(
                visitId: widget.visitId,
                taxonRef: detection.taxonRef,
              ),
            ],
          ),
        OpportunisticSearch(onPick: _recordOpportunistic),
      ],
    );
  }

  Widget _buildTarget(TargetTaxon target, AppLocalizations l10n) {
    final detection = _detectionFor(target.taxonRef);
    final recorded = detection != null;
    final active = _activeTaxonRef == target.taxonRef;
    final rowKey = _rowKeys.putIfAbsent(target.taxonRef, GlobalKey.new);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      key: rowKey,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: active
          ? BoxDecoration(
              border: Border.all(color: colorScheme.primary, width: 2),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (active)
                Icon(
                  Icons.play_arrow,
                  key: Key('detection_active_${target.taxonRef}'),
                ),
              Expanded(child: Text(target.label ?? target.taxonRef)),
              if (!recorded)
                Text(
                  l10n.detectionNotRecorded,
                  key: Key('detection_not_recorded_${target.taxonRef}'),
                  style: TextStyle(color: colorScheme.outline),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            key: Key('detection_control_${target.taxonRef}'),
            emptySelectionAllowed: true,
            selected: recorded ? <bool>{detection.detected} : const <bool>{},
            onSelectionChanged: _methodId == null
                ? null
                : (selection) {
                    if (selection.isEmpty) return;
                    _record(target, selection.first);
                  },
            segments: [
              ButtonSegment(
                value: true,
                label: Text(
                  l10n.detectionDetected,
                  key: Key('detection_detected_${target.taxonRef}'),
                ),
              ),
              ButtonSegment(
                value: false,
                label: Text(
                  l10n.detectionNotDetected,
                  key: Key('detection_not_detected_${target.taxonRef}'),
                ),
              ),
            ],
          ),
          if (recorded)
            EvidenceCapture(visitId: widget.visitId, taxonRef: target.taxonRef),
        ],
      ),
    );
  }
}
