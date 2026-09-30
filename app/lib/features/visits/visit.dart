enum VisitState { inProgress, ended }

class SamplingEffort {
  const SamplingEffort({required this.startedAt, this.endedAt});

  final DateTime startedAt;
  final DateTime? endedAt;

  SamplingEffort copyWith({DateTime? endedAt}) =>
      SamplingEffort(startedAt: startedAt, endedAt: endedAt ?? this.endedAt);
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

  bool get isEnded => state == VisitState.ended;

  Visit copyWith({VisitState? state, SamplingEffort? effort}) => Visit(
    id: id,
    siteId: siteId,
    surveyPeriodId: surveyPeriodId,
    protocolVersionId: protocolVersionId,
    state: state ?? this.state,
    effort: effort ?? this.effort,
  );
}
