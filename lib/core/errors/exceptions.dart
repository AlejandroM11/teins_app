/// Excepciones de la capa de datos.
///
/// Se usan dentro de datasources/repositorios y se convierten
/// en [Failure] antes de llegar al dominio.
class AppException implements Exception {
  const AppException(this.message, {this.code, this.originalError});

  final String message;
  final String? code;
  final Object? originalError;

  @override
  String toString() => 'AppException($code): $message';
}

class NetworkException extends AppException {
  const NetworkException({
    String message = 'No hay conexión a Internet.',
    String? code,
    Object? originalError,
  }) : super(message, code: code, originalError: originalError);
}

/// Excepción de autenticación propia (distinta de `AuthException` de gotrue/supabase).
class AppAuthException extends AppException {
  const AppAuthException({
    required String message,
    String? code,
    Object? originalError,
  }) : super(message, code: code, originalError: originalError);
}

/// Alias mantenido por compatibilidad interna — apunta a AppAuthException.
/// Usar AppAuthException directamente en código nuevo.
typedef AuthException = AppAuthException;

class DatabaseException extends AppException {
  const DatabaseException({
    required String message,
    String? code,
    Object? originalError,
  }) : super(message, code: code, originalError: originalError);
}

class SyncException extends AppException {
  const SyncException({
    required String message,
    String? code,
    Object? originalError,
  }) : super(message, code: code, originalError: originalError);
}

class StorageException extends AppException {
  const StorageException({
    required String message,
    String? code,
    Object? originalError,
  }) : super(message, code: code, originalError: originalError);
}

class ValidationException extends AppException {
  const ValidationException({
    required String message,
    String? code,
  }) : super(message, code: code);
}

class PermissionException extends AppException {
  const PermissionException({
    String message = 'Permiso denegado.',
    String? code,
  }) : super(message, code: code);
}
