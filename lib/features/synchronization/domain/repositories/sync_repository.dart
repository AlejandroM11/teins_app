import '../entities/sync_status_info.dart';

abstract interface class SyncRepository {
  /// Stream del estado de sincronización en tiempo real.
  Stream<SyncStatusInfo> get syncStatusStream;

  /// Estado actual sin stream.
  SyncStatusInfo get currentStatus;

  /// Fuerza una sincronización si hay conexión.
  Future<void> triggerSync();
}
