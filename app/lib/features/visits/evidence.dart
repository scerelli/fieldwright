/// The kind of media an [Evidence] carries: a photo or an audio recording.
enum EvidenceKind { photo, audio }

/// A photo or audio recording attached to a Detection as proof of it
/// (DOMAIN.md › Evidence). An Evidence belongs to exactly one Visit and
/// references the Detection it was captured for by that Detection's identity,
/// the pair of [visitId] and [taxonRef].
///
/// An attached Evidence is immutable: every field is final and there is no
/// copy or mutator path, so nothing can rewrite it once it is stored.
class Evidence {
  const Evidence({
    required this.id,
    required this.visitId,
    required this.taxonRef,
    required this.kind,
    required this.filePath,
    required this.capturedAt,
    required this.contentHash,
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

  @override
  bool operator ==(Object other) =>
      other is Evidence &&
      other.id == id &&
      other.visitId == visitId &&
      other.taxonRef == taxonRef &&
      other.kind == kind &&
      other.filePath == filePath &&
      other.capturedAt == capturedAt &&
      other.contentHash == contentHash;

  @override
  int get hashCode => Object.hash(
    id,
    visitId,
    taxonRef,
    kind,
    filePath,
    capturedAt,
    contentHash,
  );
}
