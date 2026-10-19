import 'package:equatable/equatable.dart';

/// Jerarquía de errores de dominio tipados.
///
/// Los errores de infraestructura (excepciones de Supabase, SQLite, etc.)
/// se mapean a estas clases antes de llegar al dominio.
/// Nunca se exponen stack traces al usuario final.
abstract class Failure extends Equatable {
  const Failure({
    required this.message,
    this.code,
    this.originalError,
  });

  /// Mensaje amigable para mostrar al usuario.
  final String message;

  /// Código interno opcional para diagnóstico.
  final String? code;

  /// Error original para logging (nunca mostrar al usuario).
  final Object? originalError;

  @override
  List<Object?> get props => [message, code];
}

// ── Fallos de red / conectividad ──────────────────────────────────────────

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Sin conexión. Los cambios se guardarán en el dispositivo '
        'y se sincronizarán automáticamente cuando vuelva Internet.',
    super.code,
    super.originalError,
  });
}

class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'El servidor no está disponible en este momento. '
        'Tus datos locales están seguros.',
    super.code,
    super.originalError,
  });
}

// ── Fallos de autenticación ───────────────────────────────────────────────

class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    super.message = 'Credenciales incorrectas. Verifica tu usuario y contraseña.',
    super.code,
    super.originalError,
  });
}

class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure({
    super.message = 'Tu sesión ha expirado. Por favor inicia sesión nuevamente.',
    super.code,
    super.originalError,
  });
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.message = 'No tienes permiso para realizar esta acción.',
    super.code,
    super.originalError,
  });
}

// ── Fallos de base de datos local ─────────────────────────────────────────

class DatabaseFailure extends Failure {
  const DatabaseFailure({
    super.message = 'Error al acceder a los datos locales. '
        'Por favor intenta nuevamente.',
    super.code,
    super.originalError,
  });
}

// ── Fallos de sincronización ──────────────────────────────────────────────

class SyncFailure extends Failure {
  const SyncFailure({
    super.message = 'No se pudo sincronizar. Tus datos siguen guardados localmente.',
    super.code,
    super.originalError,
  });
}

class ConflictFailure extends Failure {
  const ConflictFailure({
    super.message = 'Se detectó un conflicto en la sincronización. '
        'La información ha sido preservada para revisión.',
    super.code,
    super.originalError,
  });
}

// ── Fallos de validación ─────────────────────────────────────────────────

class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
    super.originalError,
  });
}

// ── Fallos de permisos del dispositivo ──────────────────────────────────

class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = 'Se necesita permiso para continuar. '
        'Por favor actívalo en la configuración del dispositivo.',
    super.code,
    super.originalError,
  });
}

// ── Fallos de almacenamiento (Storage / archivos) ─────────────────────────

class StorageFailure extends Failure {
  const StorageFailure({
    super.message = 'Error al guardar o cargar el archivo. '
        'Verifica el espacio disponible en el dispositivo.',
    super.code,
    super.originalError,
  });
}

// ── Fallo genérico ────────────────────────────────────────────────────────

class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'Ha ocurrido un error inesperado. '
        'Por favor intenta nuevamente.',
    super.code,
    super.originalError,
  });
}
