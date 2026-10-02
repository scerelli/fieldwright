/// The kind of media an [Evidence] carries: a photo or an audio recording.
enum EvidenceKind { photo, audio }

/// A photo or audio recording attached to a Detection as proof of it
/// (DOMAIN.md › Evidence). An Evidence belongs to exactly one Visit and
/// references the Detection it was captured for by that Detection's identity,
/// the pair of [visitId] and [taxonRef].
///
/// An attached Evidence is immutable: every field is final and the only
/// derivation is [withStorageKey], which returns a new value after an upload
/// rather than rewriting a stored one.
class Evidence {
  const Evidence({
    required this.id,
    required this.visitId,
    required this.taxonRef,
    required this.kind,
    required this.filePath,
    required this.capturedAt,
    required this.contentHash,
    this.storageKey,
  });

  /// Client-generated UUIDv7 identity of the Evidence.
  final String id;

  /// The Visit this Evidence belongs to.
  final String visitId;

  /// The target taxon of the Detection this Evidence is attached to — with
  /// [visitId] it identifies the Detection.
  final String taxonRef;

  final EvidenceKind kind;

  /// Local path of the stored media file, on the device and available offline.
  final String filePath;

  /// When the media was captured.
  final DateTime capturedAt;

  /// SHA-256 of the media file's bytes, for integrity and deduplication.
  final String contentHash;

  /// The content-addressed key `POST /api/v1/media` returned when this
  /// Evidence was uploaded, or `null` while it has never been uploaded.
  /// It is the transport reference a submission's [EvidenceManifestEntry]
  /// carries, never part of the Evidence's own content.
  final String? storageKey;

  /// Returns this Evidence with [storageKey] filled in after a successful
  /// upload; the media file and its content are unchanged.
  Evidence withStorageKey(String storageKey) => Evidence(
    id: id,
    visitId: visitId,
    taxonRef: taxonRef,
    kind: kind,
    filePath: filePath,
    capturedAt: capturedAt,
    contentHash: contentHash,
    storageKey: storageKey,
  );

  @override
  bool operator ==(Object other) =>
      other is Evidence &&
      other.id == id &&
      other.visitId == visitId &&
      other.taxonRef == taxonRef &&
      other.kind == kind &&
      other.filePath == filePath &&
      other.capturedAt == capturedAt &&
      other.contentHash == contentHash &&
      other.storageKey == storageKey;

  @override
  int get hashCode => Object.hash(
    id,
    visitId,
    taxonRef,
    kind,
    filePath,
    capturedAt,
    contentHash,
    storageKey,
  );
}

/// One reference in a Visit's evidence manifest, the list the submission
/// carries (DOMAIN.md › Visit submitted): the [storageKey] the media API
/// returned for an uploaded Evidence and the [sha256] of its stored bytes.
class EvidenceManifestEntry {
  const EvidenceManifestEntry({required this.storageKey, required this.sha256});

  final String storageKey;
  final String sha256;

  @override
  bool operator ==(Object other) =>
      other is EvidenceManifestEntry &&
      other.storageKey == storageKey &&
      other.sha256 == sha256;

  @override
  int get hashCode => Object.hash(storageKey, sha256);
}

/// Builds the evidence manifest for a Visit from its Evidence: only Evidence
/// that has been uploaded (a non-null [Evidence.storageKey]) is referenced, so
/// Evidence that has never been uploaded is excluded. Each entry carries the
/// Evidence's [Evidence.contentHash] as its [EvidenceManifestEntry.sha256],
/// which is the SHA-256 of the uploaded file's bytes.
List<EvidenceManifestEntry> evidenceManifest(Iterable<Evidence> evidence) =>
    <EvidenceManifestEntry>[
      for (final entry in evidence)
        if (entry.storageKey != null)
          EvidenceManifestEntry(
            storageKey: entry.storageKey!,
            sha256: entry.contentHash,
          ),
    ];
