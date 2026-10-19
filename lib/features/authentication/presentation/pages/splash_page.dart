import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../providers/auth_providers.dart';

/// Pantalla de splash: verifica sesión y redirige.
///
/// Aparece brevemente al iniciar la app mientras se comprueba
/// si existe una sesión persistida. No muestra lógica de negocio.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Verificar sesión en el siguiente frame para que el widget esté montado.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSession());
  }

  Future<void> _checkSession() async {
    await ref.read(authControllerProvider.notifier).checkSession();
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios de estado para navegar en cuanto tengamos respuesta.
    ref.listen<AuthState>(authControllerProvider, (_, state) {
      if (!mounted) return;
      if (state is AuthAuthenticated) {
        context.go(AppRoutes.home);
      } else if (state is AuthUnauthenticated || state is AuthError) {
        context.go(AppRoutes.login);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo placeholder — reemplazar con imagen real
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.engineering_rounded,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'TEINS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Visitas Técnicas',
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 64),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
