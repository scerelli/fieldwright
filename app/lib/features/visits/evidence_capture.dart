import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../l10n/app_localizations.dart';
import '../../store/evidence_dao.dart';
import 'evidence.dart';

/// Media just captured on the device, before it is attached as [Evidence].
/// [filePath] already points at the local store, so the capture works with no
/// connectivity.
class CapturedMedia {
  const CapturedMedia({
    required this.kind,
    required this.filePath,
    required this.contentHash,
    required this.capturedAt,
  });

  final EvidenceKind kind;
  final String filePath;
  final String contentHash;
  final DateTime capturedAt;
}

/// The file extension stored for each Evidence kind.
const Map<EvidenceKind, String> evidenceFileExtensions = {
  EvidenceKind.photo: 'jpg',
  EvidenceKind.audio: 'm4a',
};

/// Copies a freshly captured file into [directory], under a fresh name, and
/// returns the stored [CapturedMedia] with the SHA-256 of its bytes. The file
/// lives on the device, so capture never needs a network.
Future<CapturedMedia> persistEvidenceFile({
  required EvidenceKind kind,
  required String sourcePath,
  required Directory directory,
  String? fileName,
  DateTime? capturedAt,
}) async {
  await directory.create(recursive: true);
  final name =
      fileName ?? '${const Uuid().v7()}.${evidenceFileExtensions[kind]}';
  final destination = File('${directory.path}/$name');
  final bytes = await File(sourcePath).readAsBytes();
  await destination.writeAsBytes(bytes, flush: true);
  return CapturedMedia(
    kind: kind,
    filePath: destination.path,
    contentHash: sha256.convert(bytes).toString(),
    capturedAt: capturedAt ?? DateTime.now().toUtc(),
  );
}

/// Captures Evidence media on the device. The seam is injectable so widget
/// tests can fake the picker and recorder instead of touching platform
/// channels (which are unavailable under `flutter test`).
abstract interface class EvidenceCaptureService {
  /// Opens the camera and captures a photo. Returns null if the user cancels.
  Future<CapturedMedia?> capturePhoto();

  /// Starts recording audio to local storage.
  Future<void> startAudioRecording();

  /// Stops the current recording. Returns the recorded media, or null if the
  /// recording produced no file.
  Future<CapturedMedia?> stopAudioRecording();
}

/// Raised when a capture cannot proceed, e.g. a denied permission or a
/// missing platform channel.
class EvidenceCaptureException implements Exception {
  const EvidenceCaptureException(this.message);

  final String message;

  @override
  String toString() => 'EvidenceCaptureException: $message';
}

/// The production [EvidenceCaptureService]: the device camera through
/// `image_picker` and audio through `record`, stored under the app support
/// directory (TECH_STACK.md).
class DeviceEvidenceCaptureService implements EvidenceCaptureService {
  DeviceEvidenceCaptureService({ImagePicker? picker, AudioRecorder? recorder})
    : _picker = picker ?? ImagePicker(),
      _recorder = recorder ?? AudioRecorder();

  final ImagePicker _picker;
  final AudioRecorder _recorder;
  String? _audioPath;

  @override
  Future<CapturedMedia?> capturePhoto() async {
    final shot = await _picker.pickImage(source: ImageSource.camera);
    if (shot == null) return null;
    return persistEvidenceFile(
      kind: EvidenceKind.photo,
      sourcePath: shot.path,
      directory: await _evidenceDirectory(),
    );
  }

  @override
  Future<void> startAudioRecording() async {
    if (!await _recorder.hasPermission()) {
      throw const EvidenceCaptureException('Microphone permission denied');
    }
    final directory = await _evidenceDirectory();
    await directory.create(recursive: true);
    final path = '${directory.path}/${const Uuid().v7()}.m4a';
    _audioPath = path;
    await _recorder.start(const RecordConfig(), path: path);
  }

  @override
  Future<CapturedMedia?> stopAudioRecording() async {
    final recorded = await _recorder.stop();
    final path = recorded ?? _audioPath;
    _audioPath = null;
    if (path == null) return null;
    final bytes = await File(path).readAsBytes();
    return CapturedMedia(
      kind: EvidenceKind.audio,
      filePath: path,
      contentHash: sha256.convert(bytes).toString(),
      capturedAt: DateTime.now().toUtc(),
    );
  }

  Future<Directory> _evidenceDirectory() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}/evidence');
  }
}

/// The device capture service used by the running app. Tests override this
/// with a fake so no platform channel is touched.
final evidenceCaptureServiceProvider = Provider<EvidenceCaptureService>(
  (ref) => DeviceEvidenceCaptureService(),
);

/// The Evidence capture affordance for one Detection (UX-010): a photo button
/// and, for audio, a record button that turns into a stop control. Each
/// capture is at most one tap away from the Detection, well inside the
/// three-tap budget, and attaches the captured media to the Detection
/// immutably — the Evidence already attached is listed above the controls.
class EvidenceCapture extends ConsumerStatefulWidget {
  const EvidenceCapture({
    super.key,
    required this.visitId,
    required this.taxonRef,
  });

  final String visitId;
  final String taxonRef;

  @override
  ConsumerState<EvidenceCapture> createState() => _EvidenceCaptureState();
}

class _EvidenceCaptureState extends ConsumerState<EvidenceCapture> {
  List<Evidence> _evidence = const <Evidence>[];
  bool _recording = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final evidence = await ref
        .read(evidenceDaoProvider)
        .forDetection(widget.visitId, widget.taxonRef);
    if (!mounted) return;
    setState(() => _evidence = evidence);
  }

  Future<void> _capturePhoto() =>
      _capture(() => ref.read(evidenceCaptureServiceProvider).capturePhoto());

  Future<void> _startAudio() async {
    if (_busy || _recording) return;
    setState(() => _busy = true);
    try {
      await ref.read(evidenceCaptureServiceProvider).startAudioRecording();
      if (!mounted) return;
      setState(() => _recording = true);
    } on Object {
      _reportFailure();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stopAudio() async {
    if (!_recording) return;
    setState(() => _busy = true);
    try {
      final media = await ref
          .read(evidenceCaptureServiceProvider)
          .stopAudioRecording();
      if (!mounted) return;
      setState(() => _recording = false);
      if (media != null) await _attach(media);
    } on Object {
      if (mounted) setState(() => _recording = false);
      _reportFailure();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _capture(Future<CapturedMedia?> Function() capture) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final media = await capture();
      if (media != null) await _attach(media);
    } on Object {
      _reportFailure();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _attach(CapturedMedia media) async {
    await ref
        .read(evidenceDaoProvider)
        .attach(
          visitId: widget.visitId,
          taxonRef: widget.taxonRef,
          kind: media.kind,
          filePath: media.filePath,
          contentHash: media.contentHash,
          capturedAt: media.capturedAt,
        );
    await _load();
  }

  void _reportFailure() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).evidenceCaptureFailed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stopKey = Key('evidence_audio_stop_${widget.taxonRef}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_evidence.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final evidence in _evidence)
                  Chip(
                    key: Key('evidence_${evidence.id}'),
                    avatar: Icon(
                      evidence.kind == EvidenceKind.photo
                          ? Icons.photo_camera_outlined
                          : Icons.mic_none,
                    ),
                    label: Text(
                      evidence.kind == EvidenceKind.photo
                          ? l10n.evidencePhoto
                          : l10n.evidenceAudio,
                    ),
                  ),
              ],
            ),
          ),
        Row(
          children: [
            IconButton(
              key: Key('capture_photo_${widget.taxonRef}'),
              tooltip: l10n.evidencePhoto,
              onPressed: _busy ? null : _capturePhoto,
              icon: const Icon(Icons.photo_camera_outlined),
            ),
            IconButton(
              key: Key('capture_audio_${widget.taxonRef}'),
              tooltip: l10n.evidenceAudio,
              onPressed: (_busy || _recording) ? null : _startAudio,
              icon: const Icon(Icons.mic_none),
            ),
            if (_recording)
              TextButton.icon(
                key: stopKey,
                onPressed: _busy ? null : _stopAudio,
                icon: const Icon(Icons.stop),
                label: Text(l10n.evidenceStop),
              ),
          ],
        ),
      ],
    );
  }
}
