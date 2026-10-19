import '../entities/sync_status_info.dart';
import '../repositories/sync_repository.dart';

class GetSyncStatus {
  const GetSyncStatus(this._repository);

  final SyncRepository _repository;

  Stream<SyncStatusInfo> call() => _repository.syncStatusStream;

  SyncStatusInfo current() => _repository.currentStatus;
}
