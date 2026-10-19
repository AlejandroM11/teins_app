import 'package:powersync/powersync.dart' as ps;
import '../../domain/entities/sync_status_info.dart';
import '../../domain/repositories/sync_repository.dart';
import '../services/powersync_service.dart';

class SyncRepositoryImpl implements SyncRepository {
  const SyncRepositoryImpl({required PowerSyncService powerSyncService})
      : _powerSync = powerSyncService;

  final PowerSyncService _powerSync;

  @override
  Stream<SyncStatusInfo> get syncStatusStream {
    if (!_powerSync.isInitialized) {
      return Stream.value(const SyncStatusInfo(state: SyncState.offline));
    }
    return _powerSync.syncStatusStream.map(_mapToInfo);
  }

  @override
  SyncStatusInfo get currentStatus {
    if (!_powerSync.isInitialized) {
      return const SyncStatusInfo(state: SyncState.offline);
    }
    return _mapToInfo(_powerSync.currentSyncStatus);
  }

  @override
  Future<void> triggerSync() async {
    // PowerSync sincroniza automáticamente — método disponible para integración futura.
  }

  SyncStatusInfo _mapToInfo(ps.SyncStatus status) {
    final SyncState state;

    if (!status.connected) {
      state = SyncState.offline;
    } else if (status.downloading || status.uploading) {
      state = SyncState.syncing;
    } else if (status.hasSynced == true) {
      state = SyncState.synced;
    } else {
      state = SyncState.online;
    }

    return SyncStatusInfo(
      state: state,
      lastSyncAt: status.lastSyncedAt,
    );
  }
}
