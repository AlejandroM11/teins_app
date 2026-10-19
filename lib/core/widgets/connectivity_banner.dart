import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/connectivity_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../features/synchronization/domain/entities/sync_status_info.dart';
import '../../features/synchronization/presentation/providers/sync_providers.dart';

/// Banner de conectividad que se muestra en la parte superior cuando
/// el dispositivo está offline o hay sincronización pendiente.
///
/// Es discreto pero siempre visible para que el técnico sepa el estado.
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityStatusProvider);

    return connectivityAsync.when(
      data: (status) => _buildBanner(context, status),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBanner(BuildContext context, ConnectivityStatus status) {
    if (status == ConnectivityStatus.online) return const SizedBox.shrink();

    final (color, icon, message) = switch (status) {
      ConnectivityStatus.offline => (
          AppColors.offline,
          Icons.wifi_off_rounded,
          'Sin conexión — los cambios se guardan localmente',
        ),
      ConnectivityStatus.localOnly => (
          AppColors.warning,
          Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
          'Red disponible sin acceso a Internet',
        ),
      ConnectivityStatus.online => (
          AppColors.online,
          Icons.wifi_rounded,
          '',
        ),
    };

    return Material(
      color: color,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs + 2,
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge compacto de estado de sincronización para AppBar o listado.
class SyncStatusBadge extends ConsumerWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncAsync = ref.watch(syncStatusProvider);

    return syncAsync.when(
      data: (status) => _SyncBadgeContent(status: status),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SyncBadgeContent extends StatelessWidget {
  const _SyncBadgeContent({required this.status});

  final SyncStatusInfo status;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (status.state) {
      SyncState.synced => (
          AppColors.online,
          Icons.cloud_done_rounded,
          'Sincronizado',
        ),
      SyncState.syncing => (
          AppColors.syncing,
          Icons.sync_rounded,
          'Sincronizando...',
        ),
      SyncState.pending => (
          AppColors.pendingSync,
          Icons.cloud_upload_rounded,
          '${status.pendingCount} pendientes',
        ),
      SyncState.error => (
          AppColors.offline,
          Icons.cloud_off_rounded,
          'Error sync',
        ),
      SyncState.offline => (
          AppColors.offline,
          Icons.wifi_off_rounded,
          'Sin conexión',
        ),
      SyncState.online => (
          AppColors.online,
          Icons.cloud_done_rounded,
          'Conectado',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
