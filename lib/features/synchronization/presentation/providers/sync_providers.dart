import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../domain/entities/sync_status_info.dart';
import '../../domain/usecases/get_sync_status.dart';

/// Provider del estado de sincronización — stream reactivo.
final syncStatusProvider = StreamProvider<SyncStatusInfo>((ref) {
  final useCase = sl<GetSyncStatus>();
  return useCase();
});

/// Provider del estado de conectividad — stream reactivo.
final connectivityStatusProvider =
    StreamProvider<ConnectivityStatus>((ref) {
  final service = sl<ConnectivityService>();
  return service.statusStream;
});
