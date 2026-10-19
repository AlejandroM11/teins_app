import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_profile.dart';

/// Contrato del repositorio de autenticación.
///
/// El dominio define la interfaz; la implementación vive en la capa de datos.
/// Esto permite sustituir Supabase por cualquier otro proveedor sin
/// tocar el dominio ni la presentación.
abstract interface class AuthRepository {
  /// Inicia sesión con email y contraseña.
  /// Retorna el perfil del usuario o un [Failure] tipado.
  Future<Either<Failure, UserProfile>> signIn({
    required String email,
    required String password,
  });

  /// Cierra la sesión activa.
  Future<Either<Failure, void>> signOut();

  /// Retorna el perfil del usuario actualmente autenticado,
  /// o null si no hay sesión activa.
  Future<Either<Failure, UserProfile?>> getCurrentUser();

  /// Stream que emite el perfil del usuario cada vez que cambia
  /// el estado de autenticación (login, logout, token refresh).
  Stream<UserProfile?> get authStateChanges;

  /// Recupera la sesión persistida en almacenamiento seguro.
  /// Debe llamarse al iniciar la app para restaurar sesión offline.
  Future<Either<Failure, UserProfile?>> recoverSession();
}
