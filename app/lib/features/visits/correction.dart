/// A Correction as the versioned API returns it (GLOSSARY.md Correction;
/// DOMAIN.md): an append-only change to a submitted Visit carrying its author,
/// the recording time, the reason and the change payload.
///
/// The payload is the server's untyped `jsonb`, so it travels as a map with no
/// fixed schema; the client never invents one.
class Correction {
  const Correction({
    required this.authorId,
    required this.reason,
    required this.payload,
    this.createdAt,
  });

  factory Correction.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'];
    final createdAt = json['createdAt'];
    return Correction(
      authorId: json['authorId'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      payload: payload is Map
          ? payload.cast<String, dynamic>()
          : const <String, dynamic>{},
      createdAt: createdAt is String ? DateTime.tryParse(createdAt) : null,
    );
  }

  /// The id of the Person who recorded the Correction.
  final String authorId;
  final String reason;
  final Map<String, dynamic> payload;
  final DateTime? createdAt;
}
