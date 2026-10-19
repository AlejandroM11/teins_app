import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/authenticate_user.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/sign_out.dart';

/// Estado del proceso de autenticación.
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final UserProfile user;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  const AuthError(this.failure);
  final Failure failure;
}

/// Controller de autenticación gestionado por Riverpod.
///
/// Orquesta los casos de uso y expone el estado a la UI.
/// La UI NO conoce Supabase directamente.
class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required AuthenticateUser authenticateUser,
    required GetCurrentUser getCurrentUser,
    required SignOut signOut,
  })  : _authenticateUser = authenticateUser,
        _getCurrentUser = getCurrentUser,
        _signOut = signOut,
        super(const AuthInitial());

  final AuthenticateUser _authenticateUser;
  final GetCurrentUser _getCurrentUser;
  final SignOut _signOut;

  /// Indica si la app está en modo demo (sin Supabase).
  /// El router lo consulta para no redirigir al login.
  static bool isDemoMode = false;

  /// Verifica si existe una sesión activa al arrancar la app.
  Future<void> checkSession() async {
    state = const AuthLoading();
    final result = await _getCurrentUser();
    result.fold(
      (failure) {
        AppLogger.w('checkSession failure: ${failure.message}');
        state = const AuthUnauthenticated();
      },
      (user) {
        if (user != null) {
          AppLogger.i('Sesión recuperada: ${user.email}');
          state = AuthAuthenticated(user);
        } else {
          state = const AuthUnauthenticated();
        }
      },
    );
  }

  /// Inicia sesión. Emite [AuthLoading] → [AuthAuthenticated] o [AuthError].
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    final result = await _authenticateUser(
      AuthenticateUserParams(email: email, password: password),
    );
    result.fold(
      (failure) {
        AppLogger.w('signIn failure: ${failure.message}');
        state = AuthError(failure);
      },
      (user) {
        AppLogger.i('Login exitoso: ${user.email}');
        state = AuthAuthenticated(user);
      },
    );
  }

  /// Cierra la sesión y limpia el estado.
  Future<void> signOut() async {
    await _signOut();
    state = const AuthUnauthenticated();
  }

  /// Modo demo — entra a la app sin credenciales reales.
  /// Solo para presentaciones. No llama a Supabase.
  void enterDemoMode() {
    AuthController.isDemoMode = true;
    const demoUser = UserProfile(
      id: 'demo-user-000',
      email: 'demo@teins.com',
      role: UserRole.technician,
      fullName: 'Técnico Demo',
    );
    AppLogger.i('Modo demo activado');
    state = const AuthAuthenticated(demoUser);
  }

  UserProfile? get currentUser {
    final s = state;
    return s is AuthAuthenticated ? s.user : null;
  }
}
