import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import '../utils/logger.dart';

/// Estado de conectividad con tres niveles de verificación:
/// 1. Red disponible (Wi-Fi o datos)
/// 2. Acceso real a Internet
/// 3. Backend disponible (verificado via PowerSync)
enum ConnectivityStatus {
  /// Sin red de ningún tipo.
  offline,

  /// Red disponible pero sin acceso a Internet comprobado.
  localOnly,

  /// Internet disponible y backend alcanzable.
  online,
}

/// Servicio de monitoreo de conectividad.
///
/// Distingue entre "tener Wi-Fi" y "tener acceso real a Internet",
/// lo cual es crítico para el modo offline-first.
class ConnectivityService {
  ConnectivityService({
    Connectivity? connectivity,
    InternetConnection? internetChecker,
  })  : _connectivity = connectivity ?? Connectivity(),
        _internetChecker = internetChecker ?? InternetConnection();

  final Connectivity _connectivity;
  final InternetConnection _internetChecker;

  final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();

  ConnectivityStatus _currentStatus = ConnectivityStatus.offline;

  ConnectivityStatus get currentStatus => _currentStatus;
  bool get isOnline => _currentStatus == ConnectivityStatus.online;
  bool get isOffline => _currentStatus == ConnectivityStatus.offline;

  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Inicia el monitoreo de conectividad.
  Future<void> initialize() async {
    // Verificación inicial
    await _checkAndUpdate();

    // Suscripción a cambios de red
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (_) => _checkAndUpdate(),
      onError: (e) => AppLogger.w('ConnectivityService error: $e'),
    );

    AppLogger.i('ConnectivityService inicializado: $_currentStatus');
  }

  Future<void> _checkAndUpdate() async {
    final newStatus = await _determineStatus();
    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      _statusController.add(_currentStatus);
      AppLogger.i('Conectividad cambiada: $newStatus');
    }
  }

  Future<ConnectivityStatus> _determineStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();

      // Sin red de ningún tipo
      if (results.contains(ConnectivityResult.none) || results.isEmpty) {
        return ConnectivityStatus.offline;
      }

      // Hay red – verificar si hay acceso real a Internet
      final hasInternet = await _internetChecker.hasInternetAccess;
      return hasInternet
          ? ConnectivityStatus.online
          : ConnectivityStatus.localOnly;
    } catch (e) {
      AppLogger.w('Error verificando conectividad: $e');
      return ConnectivityStatus.offline;
    }
  }

  /// Fuerza una verificación inmediata.
  Future<ConnectivityStatus> checkNow() async {
    await _checkAndUpdate();
    return _currentStatus;
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
  }
}
