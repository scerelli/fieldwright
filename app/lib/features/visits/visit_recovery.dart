import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../store/database_provider.dart';
import '../../store/detection_dao.dart';
import 'detection.dart';
import 'visit.dart';

/// An in-progress Visit together with the Detections recorded against it, as
/// read from the local store when the app resumes (UX-013).
typedef RecoveredVisit = ({Visit visit, List<Detection> detections});

/// Loads the in-progress Visit the app should resume, with its Detections,
/// from the local store on startup. `null` when no Visit is in progress.
///
/// The store is the only source, so a crash or kill loses no field work and a
/// relaunch restores it (UX-013).
final inProgressVisitProvider = FutureProvider<RecoveredVisit?>((ref) async {
  final inProgress = await ref.watch(visitDaoProvider).inProgress();
  if (inProgress.isEmpty) return null;
  final visit = inProgress.first;
  final detections = await ref.watch(detectionDaoProvider).forVisit(visit.id);
  return (visit: visit, detections: detections);
});

/// Reads one Visit from the local store. The capture screen watches this, so
/// the store — never a copied in-memory Visit — is the source of truth for the
/// capture flow (UX-013).
final captureVisitProvider = FutureProvider.family<Visit?, String>(
  (ref, visitId) => ref.watch(visitDaoProvider).findById(visitId),
);
