import 'package:equatable/equatable.dart';

enum SyncState {
  offline,
  online,
  syncing,
  pending,
  synced,
  error,
}

class SyncStatusInfo extends Equatable {
  const SyncStatusInfo({
    required this.state,
    this.pendingCount = 0,
    this.lastSyncAt,
    this.errorMessage,
  });

  final SyncState state;
  final int pendingCount;
  final DateTime? lastSyncAt;
  final String? errorMessage;

  bool get isOnline =>
      state == SyncState.online ||
      state == SyncState.syncing ||
      state == SyncState.synced;

  bool get hasPending => pendingCount > 0;

  String get userFriendlyMessage {
    switch (state) {
      case SyncState.offline:
        return 'Sin conexión — trabajando localmente';
      case SyncState.syncing:
        return 'Sincronizando información...';
      case SyncState.pending:
        return '$pendingCount ${pendingCount == 1 ? 'elemento pendiente' : 'elementos pendientes'} de sincronizar';
      case SyncState.synced:
      case SyncState.online:
        return 'Todo sincronizado';
      case SyncState.error:
        return errorMessage ??
            'Error de sincronización — datos seguros localmente';
    }
  }

  @override
  List<Object?> get props => [state, pendingCount, lastSyncAt, errorMessage];
}
