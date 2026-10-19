import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/connectivity_banner.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../synchronization/domain/entities/sync_status_info.dart';
import '../../../synchronization/presentation/providers/sync_providers.dart';
import '../../../visits/domain/entities/visit.dart';
import '../../../visits/presentation/providers/visit_providers.dart';
import '../providers/home_providers.dart';

/// Dashboard principal del técnico.
///
/// Muestra de un vistazo:
/// - Estado de conectividad y sincronización
/// - Estadísticas de visitas
/// - Visitas en progreso (acceso rápido)
/// - Visitas recientes
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, ref, user?.displayName),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(assignedVisitsProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Bienvenida ────────────────────────────────────────────
              _WelcomeHeader(name: user?.displayName ?? 'Técnico'),
              const SizedBox(height: AppSpacing.md),

              // ── Estado de sincronización ──────────────────────────────
              const _SyncStatusCard(),
              const SizedBox(height: AppSpacing.md),

              // ── Estadísticas ──────────────────────────────────────────
              const _StatsRow(),
              const SizedBox(height: AppSpacing.lg),

              // ── Visitas en progreso (acceso rápido) ───────────────────
              const _InProgressSection(),
              const SizedBox(height: AppSpacing.lg),

              // ── Accesos directos ──────────────────────────────────────
              const _QuickActions(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    String? userName,
  ) {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.engineering_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Text(
            'TEINS',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
      actions: [
        // Badge de sincronización en el AppBar
        const _AppBarSyncBadge(),
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'Cerrar sesión',
          onPressed: () async {
            await ref.read(authControllerProvider.notifier).signOut();
            if (context.mounted) context.go(AppRoutes.login);
          },
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(28),
        child: ConnectivityBanner(),
      ),
    );
  }
}

// ── Cabecera de bienvenida ─────────────────────────────────────────────────

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buenos días'
        : hour < 18
            ? 'Buenas tardes'
            : 'Buenas noches';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          AppDateUtils.formatDate(DateTime.now()),
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Card de estado de sincronización ─────────────────────────────────────────

class _SyncStatusCard extends ConsumerWidget {
  const _SyncStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncAsync = ref.watch(syncStatusProvider);
    final connectAsync = ref.watch(connectivityStatusProvider);

    return syncAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (syncInfo) {
        final (bgColor, icon, title, subtitle) = _buildContent(syncInfo);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: bgColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: bgColor.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: bgColor, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: bgColor,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  (Color, IconData, String, String) _buildContent(SyncStatusInfo info) {
    switch (info.state) {
      case SyncState.offline:
        return (
          AppColors.offline,
          Icons.wifi_off_rounded,
          'Modo sin conexión',
          'Los cambios se guardan en el dispositivo',
        );
      case SyncState.syncing:
        return (
          AppColors.syncing,
          Icons.sync_rounded,
          'Sincronizando...',
          'Enviando información al servidor',
        );
      case SyncState.pending:
        return (
          AppColors.pendingSync,
          Icons.cloud_upload_rounded,
          '${info.pendingCount} elemento${info.pendingCount == 1 ? '' : 's'} pendiente${info.pendingCount == 1 ? '' : 's'}',
          'Se sincronizarán automáticamente',
        );
      case SyncState.synced:
      case SyncState.online:
        final lastSync = info.lastSyncAt != null
            ? 'Última sync: ${AppDateUtils.formatRelative(info.lastSyncAt!)}'
            : 'Todo sincronizado';
        return (
          AppColors.online,
          Icons.cloud_done_rounded,
          'Conectado y sincronizado',
          lastSync,
        );
      case SyncState.error:
        return (
          AppColors.error,
          Icons.cloud_off_rounded,
          'Error de sincronización',
          'Los datos locales están seguros',
        );
    }
  }
}

// ── Fila de estadísticas ───────────────────────────────────────────────────

class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(technicianStatsProvider);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Asignadas',
            value: stats.totalAssigned,
            icon: Icons.assignment_outlined,
            color: AppColors.visitAssigned,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            label: 'En progreso',
            value: stats.inProgress,
            icon: Icons.pending_actions_rounded,
            color: AppColors.visitInProgress,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            label: 'Completadas',
            value: stats.completed,
            icon: Icons.task_alt_rounded,
            color: AppColors.visitCompleted,
          ),
        ),
        if (stats.pendingSync > 0) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _StatCard(
              label: 'Pendientes',
              value: stats.pendingSync,
              icon: Icons.schedule_send_rounded,
              color: AppColors.pendingSync,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sección de visitas en progreso ─────────────────────────────────────────

class _InProgressSection extends ConsumerWidget {
  const _InProgressSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsync = ref.watch(assignedVisitsProvider);

    return visitsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (either) {
        final inProgress = either.fold(
          (_) => <Visit>[],
          (visits) =>
              visits.where((v) => v.status == VisitStatus.inProgress).toList(),
        );

        if (inProgress.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.pending_actions_rounded,
                  size: 18,
                  color: AppColors.visitInProgress,
                ),
                const SizedBox(width: AppSpacing.xs),
                const Text(
                  'En progreso',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go(AppRoutes.visits),
                  child: const Text('Ver todas'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...inProgress.take(3).map(
                  (v) => _InProgressTile(
                    visit: v,
                    onTap: () =>
                        context.go(AppRoutes.visitDetailPath(v.id)),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _InProgressTile extends StatelessWidget {
  const _InProgressTile({required this.visit, required this.onTap});

  final Visit visit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.visitInProgress,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visit.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (visit.clientName != null)
                      Text(
                        visit.clientName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    if (visit.startedAt != null)
                      Text(
                        'Iniciada ${AppDateUtils.formatRelative(visit.startedAt!)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Accesos directos ────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones rápidas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 2.2,
          children: [
            _QuickActionTile(
              icon: Icons.assignment_rounded,
              label: 'Mis visitas',
              color: AppColors.primary,
              onTap: () => context.go(AppRoutes.visits),
            ),
            _QuickActionTile(
              icon: Icons.add_circle_rounded,
              label: 'Nueva visita',
              color: AppColors.secondary,
              onTap: () => context.go(AppRoutes.visits),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Badge de sync en AppBar ────────────────────────────────────────────────

class _AppBarSyncBadge extends ConsumerWidget {
  const _AppBarSyncBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncAsync = ref.watch(syncStatusProvider);

    return syncAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (info) {
        final (color, icon) = switch (info.state) {
          SyncState.offline => (AppColors.offline, Icons.wifi_off_rounded),
          SyncState.syncing => (AppColors.syncing, Icons.sync_rounded),
          SyncState.pending => (AppColors.pendingSync, Icons.cloud_upload_rounded),
          SyncState.synced || SyncState.online => (AppColors.online, Icons.cloud_done_rounded),
          SyncState.error => (AppColors.error, Icons.cloud_off_rounded),
        };

        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              if (info.state == SyncState.pending && info.pendingCount > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        info.pendingCount > 9 ? '9+' : '${info.pendingCount}',
                        style: const TextStyle(
                          fontSize: 6,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
