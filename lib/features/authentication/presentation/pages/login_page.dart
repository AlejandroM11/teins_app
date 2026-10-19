import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../controllers/auth_controller.dart';
import '../providers/auth_providers.dart';
import '../widgets/login_form.dart';

/// Página de inicio de sesión.
///
/// Diseño limpio orientado a uso en campo.
/// Campos grandes, mínimas distracciones.
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Navegar al home cuando la autenticación sea exitosa.
    ref.listen<AuthState>(authControllerProvider, (_, state) {
      if (state is AuthAuthenticated) {
        context.go(AppRoutes.home);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // En tablet: centrar el formulario con ancho máximo
            final isTablet = constraints.maxWidth > 600;
            final horizontalPadding = isTablet
                ? (constraints.maxWidth - 480) / 2
                : AppSpacing.screenHorizontal;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  _buildHeader(),
                  const SizedBox(height: AppSpacing.xxxl),
                  const LoginForm(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildFooter(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.engineering_rounded,
            size: 44,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'TEINS',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Visitas Técnicas',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Text(
      '© ${DateTime.now().year} TEINS — Todos los derechos reservados',
      style: const TextStyle(
        fontSize: 11,
        color: AppColors.textDisabled,
      ),
      textAlign: TextAlign.center,
    );
  }
}
