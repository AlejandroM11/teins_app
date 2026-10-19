import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../features/visits/domain/entities/visit.dart';

/// Badge visual para el estado de una visita.
class VisitStatusBadge extends StatelessWidget {
  const VisitStatusBadge({super.key, required this.status});

  final VisitStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      VisitStatus.assigned => (AppColors.visitAssigned, 'Asignada'),
      VisitStatus.inProgress => (AppColors.visitInProgress, 'En progreso'),
      VisitStatus.completed => (AppColors.visitCompleted, 'Completada'),
      VisitStatus.pendingReview => (AppColors.warning, 'En revisión'),
      VisitStatus.synced => (AppColors.visitSynced, 'Sincronizada'),
    };

    return _Badge(color: color, label: label);
  }
}

/// Badge para el estado de sincronización de un registro.
class SyncStateBadge extends StatelessWidget {
  const SyncStateBadge({super.key, required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (status) {
      SyncStatus.local => (AppColors.grey500, Icons.save_rounded, 'Local'),
      SyncStatus.pendingSync => (
          AppColors.pendingSync,
          Icons.schedule_rounded,
          'Pendiente'
        ),
      SyncStatus.syncing => (
          AppColors.syncing,
          Icons.sync_rounded,
          'Sincronizando'
        ),
      SyncStatus.synced => (AppColors.online, Icons.cloud_done_rounded, 'Sync'),
      SyncStatus.syncError => (
          AppColors.error,
          Icons.cloud_off_rounded,
          'Error'
        ),
      SyncStatus.conflict => (
          AppColors.warning,
          Icons.warning_rounded,
          'Conflicto'
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
