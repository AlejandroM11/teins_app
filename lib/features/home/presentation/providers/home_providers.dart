import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../visits/presentation/providers/visit_providers.dart';
import '../../../visits/domain/entities/visit.dart';

/// Estadísticas del técnico para el dashboard.
class TechnicianStats {
  const TechnicianStats({
    this.totalAssigned = 0,
    this.inProgress = 0,
    this.completed = 0,
    this.pendingSync = 0,
  });

  final int totalAssigned;
  final int inProgress;
  final int completed;
  final int pendingSync;
}

final technicianStatsProvider = Provider<TechnicianStats>((ref) {
  final visitsAsync = ref.watch(assignedVisitsProvider);

  return visitsAsync.when(
    data: (either) => either.fold(
      (_) => const TechnicianStats(),
      (visits) => TechnicianStats(
        totalAssigned: visits.length,
        inProgress:
            visits.where((v) => v.status == VisitStatus.inProgress).length,
        completed:
            visits.where((v) => v.status == VisitStatus.completed).length,
        pendingSync: visits.where((v) => v.hasPendingSync).length,
      ),
    ),
    loading: () => const TechnicianStats(),
    error: (_, __) => const TechnicianStats(),
  );
});
