import 'package:permission_handler/permission_handler.dart';
import '../errors/failures.dart';
import '../utils/logger.dart';

/// Gestión centralizada de permisos del dispositivo.
class PermissionService {
  /// Solicita permiso de cámara. Retorna [PermissionFailure] si es denegado.
  Future<PermissionFailure?> requestCamera() async {
    return _request(Permission.camera, 'cámara');
  }

  /// Solicita permiso de almacenamiento (fotos/galería).
  Future<PermissionFailure?> requestStorage() async {
    // En Android 13+ se usa photos en lugar de storage.
    final permission = await Permission.photos.status;
    if (permission.isGranted) return null;

    final result = await Permission.photos.request();
    if (result.isGranted) return null;

    // Fallback para Android < 13
    if (!result.isGranted) {
      final storageResult = await Permission.storage.request();
      if (storageResult.isGranted) return null;
    }

    AppLogger.w('Permiso de almacenamiento denegado');
    return const PermissionFailure(
      message: 'Se necesita acceso al almacenamiento para guardar fotografías.',
    );
  }

  /// Solicita permiso de ubicación (para formularios con coordenadas).
  Future<PermissionFailure?> requestLocation() async {
    return _request(Permission.locationWhenInUse, 'ubicación');
  }

  Future<PermissionFailure?> _request(
    Permission permission,
    String permissionName,
  ) async {
    final status = await permission.status;
    if (status.isGranted) return null;

    if (status.isPermanentlyDenied) {
      AppLogger.w('Permiso $permissionName permanentemente denegado');
      return PermissionFailure(
        message:
            'El permiso de $permissionName está desactivado. '
            'Por favor actívalo en la configuración del dispositivo.',
      );
    }

    final result = await permission.request();
    if (result.isGranted) return null;

    AppLogger.w('Permiso $permissionName denegado');
    return PermissionFailure(
      message: 'Se necesita el permiso de $permissionName para continuar.',
    );
  }

  /// Abre la configuración del sistema para que el usuario active permisos.
  Future<void> openSettings() => openAppSettings();
}
