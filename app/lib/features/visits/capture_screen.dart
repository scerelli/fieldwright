import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../protocol/protocol.dart';
import '../../store/database_provider.dart';
import '../../store/measurement_dao.dart';
import '../../widgets/sync_indicator.dart';
import 'detection_list.dart';
import 'effort_timer.dart';
import 'measurement.dart';
import 'sensor_service.dart';
import 'visit.dart';
import 'visit_recovery.dart';

/// The Visit capture flow. It identifies its Visit by [visit] but renders the
/// state read from the local store, so every change is persisted and no
/// in-memory copy can drift from the store (UX-013).
class CaptureScreen extends ConsumerWidget {
  const CaptureScreen({
    super.key,
    required this.visit,
    this.protocol,
    this.clock,
  });

  /// The Visit this screen belongs to. Only its identity is used; the rendered
  /// state comes from the store so a kill never leaves a stale copy on screen.
  final Visit visit;
  final ProtocolDocument? protocol;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stored = ref.watch(captureVisitProvider(visit.id)).value;
    if (stored == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _CaptureView(visit: stored, protocol: protocol, clock: clock);
  }
}

class _CaptureView extends ConsumerWidget {
  const _CaptureView({required this.visit, this.protocol, this.clock});

  final Visit visit;
  final ProtocolDocument? protocol;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final stateLabel = visit.isEnded
        ? l10n.visitStateEnded
        : l10n.visitStateInProgress;
    final visitCovariates =
        protocol?.visitCovariates ?? const <CovariateDefinition>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.captureTitle),
        actions: [
          if (visit.isEnded)
            IconButton(
              key: const Key('submit_visit'),
              onPressed: () async {
                final outbox = ref.read(outboxProvider);
                await outbox.submit(visit);
                // Show the queued state as soon as it is recorded, then follow
                // the delivery to its outcome so the indicator reaches synced
                // or failed instead of stalling (UX-008). Guard every
                // invalidate against disposal: delivery can outlast the screen
                // and `ref` throws once the widget is unmounted.
                if (context.mounted) {
                  ref.invalidate(visitSyncStateProvider(visit.id));
                }
                try {
                  await outbox.flush();
                } on StateError {
                  // The outbox is not wired for delivery here (queue-only);
                  // the Visit stays queued for the next delivery-capable flush
                  // (UX-007).
                }
                if (context.mounted) {
                  ref.invalidate(visitSyncStateProvider(visit.id));
                }
              },
              icon: const Icon(Icons.cloud_upload_outlined),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.captureState(stateLabel), key: const Key('capture_state')),
          const SizedBox(height: 8),
          SyncIndicator(
            visitId: visit.id,
            onRetry: () async {
              final outbox = ref.read(outboxProvider);
              await outbox.submit(visit);
              try {
                await outbox.flush();
              } on StateError {
                // The outbox is not wired for delivery here (queue-only);
                // the Visit stays queued for the next delivery-capable flush
                // (UX-007).
              }
              if (context.mounted) {
                ref.invalidate(visitSyncStateProvider(visit.id));
              }
            },
          ),
          const SizedBox(height: 8),
          Text(
            l10n.captureEffortStarted(visit.effort.startedAt.toIso8601String()),
            key: const Key('capture_effort_started'),
          ),
          const SizedBox(height: 8),
          EffortTimer(
            startedAt: visit.effort.startedAt,
            endedAt: visit.effort.endedAt,
            clock: clock,
          ),
          const SizedBox(height: 8),
          VisitObservers(
            visitId: visit.id,
            observers: visit.effort.observers,
            enabled: !visit.isSubmitted,
          ),
          if (protocol != null) ...[
            const SizedBox(height: 16),
            DetectionList(protocol: protocol!, visitId: visit.id),
          ],
          if (visitCovariates.isNotEmpty) ...[
            const SizedBox(height: 16),
            VisitCovariates(visitId: visit.id, definitions: visitCovariates),
          ],
        ],
      ),
    );
  }
}

/// The capture screen control for the Visit's `observers` Sampling-effort
/// field (INV-005). The recorded names seed the field on open; saving persists
/// them through the local store, so a relaunch reloads them (UX-013). A
/// submitted Visit is immutable, so the field is disabled once it is submitted
/// (INV-001).
class VisitObservers extends ConsumerStatefulWidget {
  const VisitObservers({
    super.key,
    required this.visitId,
    required this.observers,
    this.enabled = true,
  });

  final String visitId;
  final List<String> observers;
  final bool enabled;

  @override
  ConsumerState<VisitObservers> createState() => _VisitObserversState();
}

class _VisitObserversState extends ConsumerState<VisitObservers> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.observers.join(', '),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> _parse(String value) => value
      .split(',')
      .map((name) => name.trim())
      .where((name) => name.isNotEmpty)
      .toList(growable: false);

  Future<void> _save() async {
    await ref
        .read(visitDaoProvider)
        .recordObservers(widget.visitId, _parse(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            key: const Key('observers_field'),
            controller: _controller,
            enabled: widget.enabled,
            decoration: InputDecoration(labelText: l10n.effortFieldObservers),
          ),
        ),
        IconButton(
          key: const Key('observers_save'),
          onPressed: widget.enabled ? _save : null,
          icon: const Icon(Icons.check),
        ),
      ],
    );
  }
}

/// The visit covariate entry on the capture screen. Each covariate the
/// Protocol version defines is read from the phone sensor that backs it; when
/// this device has no such sensor, the field falls back to manual entry and is
/// labelled as such (UX-011). A value read from an uncalibrated sensor is
/// marked low-confidence. Saving records each value as a Measurement carrying
/// its provenance (INV-010).
class VisitCovariates extends ConsumerStatefulWidget {
  const VisitCovariates({
    super.key,
    required this.visitId,
    required this.definitions,
  });

  final String visitId;
  final List<CovariateDefinition> definitions;

  @override
  ConsumerState<VisitCovariates> createState() => _VisitCovariatesState();
}

class _VisitCovariatesState extends ConsumerState<VisitCovariates> {
  late final Map<String, TextEditingController> _manual = {
    for (final field in widget.definitions) field.name: TextEditingController(),
  };
  final Map<String, ProvenanceMethod?> _methods = <String, ProvenanceMethod?>{};
  final Map<String, SensorValue?> _sensorValues = <String, SensorValue?>{};
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = ref.read(sensorServiceProvider);
    for (final field in widget.definitions) {
      _sensorValues[field.name] = await service.read(field);
    }
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    for (final controller in _manual.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final measurements = <Measurement>[];
    for (final field in widget.definitions) {
      final sensorValue = _sensorValues[field.name];
      if (sensorValue != null) {
        measurements.add(
          Measurement(
            name: field.name,
            value: sensorValue.value.toString(),
            unit: field.unit,
            provenance: Provenance(
              method: ProvenanceMethod.phoneSensor,
              calibration: sensorValue.calibration,
            ),
          ),
        );
        continue;
      }
      final value = _manual[field.name]!.text.trim();
      if (value.isEmpty) continue;
      final measurement = buildMeasurement(
        name: field.name,
        value: value,
        unit: field.unit,
        method: _methods[field.name],
      );
      if (measurement == null) {
        setState(() => _error = l10n.measurementMissingMethod);
        return;
      }
      measurements.add(measurement);
    }

    final dao = ref.read(measurementDaoProvider);
    for (final measurement in measurements) {
      await dao.record(visitId: widget.visitId, measurement: measurement);
    }
    if (!mounted) return;
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.visitCovariatesHeading,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final field in widget.definitions) _buildField(field, l10n),
        if (_error != null)
          Padding(
            key: const Key('measurements_error'),
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton(
          key: const Key('measurements_save'),
          onPressed: _save,
          child: Text(l10n.measurementSave),
        ),
      ],
    );
  }

  Widget _buildField(CovariateDefinition field, AppLocalizations l10n) {
    final sensorValue = _sensorValues[field.name];
    final label = field.unit == null
        ? field.name
        : '${field.name} (${field.unit})';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sensorValue == null) ...[
            Text(
              l10n.measurementManualFallback,
              key: Key('measurement_manual_fallback_${field.name}'),
            ),
            const SizedBox(height: 4),
            TextField(
              key: Key('covariate_manual_${field.name}'),
              controller: _manual[field.name],
              decoration: InputDecoration(labelText: label),
            ),
            const SizedBox(height: 8),
            DropdownButton<ProvenanceMethod>(
              key: Key('covariate_method_${field.name}'),
              value: _methods[field.name],
              hint: Text(l10n.measurementMethod),
              onChanged: (method) =>
                  setState(() => _methods[field.name] = method),
              items: [
                for (final method in ProvenanceMethod.values)
                  DropdownMenuItem(
                    value: method,
                    child: Text(_methodLabel(l10n, method)),
                  ),
              ],
            ),
          ] else ...[
            Text(
              field.unit == null
                  ? '${sensorValue.value}'
                  : '${sensorValue.value} ${field.unit}',
              key: Key('covariate_sensor_value_${field.name}'),
            ),
            if (sensorValue.calibration == CalibrationState.uncalibrated)
              Text(
                l10n.measurementLowConfidence,
                key: Key('covariate_low_confidence_${field.name}'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ],
      ),
    );
  }

  String _methodLabel(AppLocalizations l10n, ProvenanceMethod method) =>
      switch (method) {
        ProvenanceMethod.phoneSensor => l10n.covariateMethodPhoneSensor,
        ProvenanceMethod.fieldInstrument => l10n.covariateMethodFieldInstrument,
        ProvenanceMethod.visualEstimate => l10n.covariateMethodVisualEstimate,
      };
}
