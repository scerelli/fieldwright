/// The lifecycle state a stored Visit reports through the versioned API
/// (`server/src/db/schema.ts`'s `visit_state`; GLOSSARY.md Visit, Validation).
///
/// The client reads it from `GET /api/v1/visits/:id`; `submitted` means no
/// Validation has been recorded yet, so `validatorId` and `validatedAt` are
/// null (INV-013).
enum VisitLifecycleState {
  inProgress('in_progress'),
  ended('ended'),
  submitted('submitted'),
  validated('validated'),
  rejected('rejected');

  const VisitLifecycleState(this.wire);

  /// The value the server stores and returns.
  final String wire;

  static VisitLifecycleState fromWire(Object? value) {
    for (final state in values) {
      if (state.wire == value) return state;
    }
    throw FormatException('Unknown Visit state: $value');
  }
}

/// A stored Visit's Validation state as the versioned API returns it
/// (GLOSSARY.md Visit, Validation; INV-013): its lifecycle `state`, the
/// validating Person's id and the Validation instant, both null until a
/// Validation is recorded.
class VisitStatus {
  const VisitStatus({required this.state, this.validatorId, this.validatedAt});

  factory VisitStatus.fromJson(Map<String, dynamic> json) {
    final validatedAt = json['validatedAt'];
    return VisitStatus(
      state: VisitLifecycleState.fromWire(json['state']),
      validatorId: json['validatorId'] as String?,
      validatedAt: validatedAt is String
          ? DateTime.tryParse(validatedAt)
          : null,
    );
  }

  final VisitLifecycleState state;
  final String? validatorId;
  final DateTime? validatedAt;
}
