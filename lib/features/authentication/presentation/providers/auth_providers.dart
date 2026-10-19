import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection_container.dart';
import '../controllers/auth_controller.dart';

/// Provider del AuthController — accesible desde cualquier widget.
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) => sl<AuthController>());

/// Provider de conveniencia para obtener el usuario autenticado actual.
final currentUserProvider = Provider((ref) {
  final state = ref.watch(authControllerProvider);
  return state is AuthAuthenticated ? state.user : null;
});
