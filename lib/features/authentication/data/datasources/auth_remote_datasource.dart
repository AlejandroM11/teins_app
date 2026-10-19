import 'package:supabase_flutter/supabase_flutter.dart';
// Ocultamos AuthException de supabase_flutter para que no choque con la nuestra.
// La gotrue AuthException queda disponible como AuthException de supabase internamente.
import '../../../../core/errors/exceptions.dart' hide AuthException;
import '../../../../core/utils/logger.dart';
import '../models/auth_models.dart';

/// Contrato de la fuente de datos remota de autenticación.
abstract interface class AuthRemoteDatasource {
  Future<UserProfileModel> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<UserProfileModel?> getCurrentUser();

  Stream<UserProfileModel?> get authStateChanges;
}

/// Implementación usando Supabase Auth.
///
/// Solo la clave anon key se usa en el cliente.
/// La service_role key NUNCA se incluye en la app.
class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  const AuthRemoteDatasourceImpl({required SupabaseClient supabaseClient})
      : _client = supabaseClient;

  final SupabaseClient _client;

  @override
  Future<UserProfileModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AppAuthException(message: 'Credenciales incorrectas.');
      }

      // Intentar cargar perfil extendido desde la tabla profiles.
      // Si no existe o hay error de red, construir desde auth metadata.
      final profile = await _fetchProfile(user.id);
      AppLogger.i('Usuario autenticado: ${user.email}');
      return profile ?? UserProfileModel.fromAuthUser(user);
    } on AppAuthException {
      rethrow;
    } on AuthApiException catch (e) {
      AppLogger.w('Auth API error: ${e.message}');
      throw AppAuthException(
        message: _mapAuthError(e.message),
        code: e.statusCode.toString(),
        originalError: e,
      );
    } catch (e) {
      AppLogger.e('signIn error', error: e);
      throw AppAuthException(
        message: 'Error al iniciar sesión. Verifica tu conexión.',
        originalError: e,
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      AppLogger.i('Sesión cerrada.');
    } catch (e) {
      AppLogger.w('Error al cerrar sesión (se continúa): $e');
      // No propagamos el error — si hay fallo de red al cerrar sesión,
      // la sesión local igual se limpia.
    }
  }

  @override
  Future<UserProfileModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final profile = await _fetchProfile(user.id);
      return profile ?? UserProfileModel.fromAuthUser(user);
    } catch (e) {
      // Sin conexión: construir desde datos de sesión local.
      AppLogger.d('getCurrentUser offline fallback: $e');
      return UserProfileModel.fromAuthUser(user);
    }
  }

  @override
  Stream<UserProfileModel?> get authStateChanges {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user == null) return null;
      try {
        final profile = await _fetchProfile(user.id);
        return profile ?? UserProfileModel.fromAuthUser(user);
      } catch (_) {
        return UserProfileModel.fromAuthUser(user);
      }
    });
  }

  Future<UserProfileModel?> _fetchProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return null;
      return UserProfileModel.fromSupabaseRow(data);
    } catch (e) {
      AppLogger.d('_fetchProfile error (non-critical): $e');
      return null;
    }
  }

  String _mapAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid') || lower.contains('credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Debes confirmar tu correo electrónico antes de iniciar sesión.';
    }
    if (lower.contains('too many requests')) {
      return 'Demasiados intentos. Espera unos minutos e intenta nuevamente.';
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return 'Sin conexión. Verifica tu Internet e intenta nuevamente.';
    }
    return 'Error al iniciar sesión. Intenta nuevamente.';
  }
}
