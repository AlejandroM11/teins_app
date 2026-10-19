import 'package:flutter/material.dart';

/// Paleta de colores corporativa de TEINS.
/// Diseño orientado a profesionales de ingeniería en campo.
class AppColors {
  const AppColors._();

  // ── Primarios ─────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF0D4F8B);       // Azul TEINS
  static const Color primaryLight = Color(0xFF2E72B8);
  static const Color primaryDark = Color(0xFF08305A);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ── Secundarios ───────────────────────────────────────────────────────────
  static const Color secondary = Color(0xFF00A878);     // Verde operativo
  static const Color secondaryLight = Color(0xFF33C49A);
  static const Color secondaryDark = Color(0xFF007A57);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // ── Neutros ───────────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F7FA);
  static const Color background = Color(0xFFF0F2F5);
  static const Color onSurface = Color(0xFF1A1A2E);
  static const Color onBackground = Color(0xFF1A1A2E);

  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // ── Estado / Feedback ─────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFF57F17);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color error = Color(0xFFC62828);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF01579B);
  static const Color infoLight = Color(0xFFE1F5FE);

  // ── Sincronización (indicadores de estado offline/online) ─────────────────
  static const Color online = Color(0xFF2E7D32);        // Verde
  static const Color syncing = Color(0xFFF57F17);       // Naranja
  static const Color offline = Color(0xFFB71C1C);       // Rojo
  static const Color synced = Color(0xFF0D4F8B);        // Azul TEINS
  static const Color pendingSync = Color(0xFFF9A825);   // Amarillo

  // ── Estados de visita ────────────────────────────────────────────────────
  static const Color visitAssigned = Color(0xFF01579B);
  static const Color visitInProgress = Color(0xFFF57F17);
  static const Color visitCompleted = Color(0xFF2E7D32);
  static const Color visitSynced = Color(0xFF0D4F8B);
  static const Color visitError = Color(0xFFC62828);

  // ── Texto ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textInverse = Color(0xFFFFFFFF);

  // ── Bordes ────────────────────────────────────────────────────────────────
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderFocus = Color(0xFF0D4F8B);

  // ── Overlay ───────────────────────────────────────────────────────────────
  static const Color scrim = Color(0x52000000);
}
