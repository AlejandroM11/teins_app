import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' show MaterialUiCompatibilityBridge;
import '../core/routing/app_router.dart';
import '../core/theme/app_theme.dart';

/// Widget raíz de la aplicación.
///
/// ProviderScope envuelve toda la app para que Riverpod funcione.
/// MaterialUiCompatibilityBridge permite que el proyecto use flutter/material.dart
/// mientras flutter_form_builder v11 usa package:material_ui — inyecta
/// theme y localización para que los widgets sin migrar sigan funcionando.
class TeinsApp extends StatelessWidget {
  const TeinsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TEINS — Visitas Técnicas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      locale: const Locale('es'),
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      builder: (BuildContext context, Widget? child) {
        return MaterialUiCompatibilityBridge(child: child!);
      },
    );
  }
}
