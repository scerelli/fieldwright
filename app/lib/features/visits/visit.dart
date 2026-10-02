enum VisitState { inProgress, ended, submitted }

class SamplingEffort {
  const SamplingEffort({
    required this.startedAt,
    this.endedAt,
    this.observers = const <String>[],
  });

  final DateTime startedAt;
  final DateTime? endedAt;

  /// The people who carried out the search, recorded when the Visit's Protocol
  /// version requires the `observers` Sampling-effort field (INV-005).
  final List<String> observers;

  SamplingEffort copyWith({DateTime? endedAt, List<String>? observers}) =>
      SamplingEffort(
        startedAt: startedAt,
        endedAt: endedAt ?? this.endedAt,
        observers: observers ?? this.observers,
      );
}

class Visit {
  const Visit({
    required this.id,
    required this.siteId,
    required this.surveyPeriodId,
    required this.protocolVersionId,
    required this.state,
    required this.effort,
  });

  final String id;
  final String siteId;
  final String surveyPeriodId;
  final String protocolVersionId;
  final VisitState state;
  final SamplingEffort effort;

  bool get isInProgress => state == VisitState.inProgress;
  bool get isEnded => state == VisitState.ended;
  bool get isSubmitted => state == VisitState.submitted;

  Visit copyWith({VisitState? state, SamplingEffort? effort}) => Visit(
    id: id,
    siteId: siteId,
    surveyPeriodId: surveyPeriodId,
    protocolVersionId: protocolVersionId,
    state: state ?? this.state,
    effort: effort ?? this.effort,
  );
}
