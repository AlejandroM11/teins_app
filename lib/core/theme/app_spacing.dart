/// Sistema de espaciado consistente basado en múltiplos de 4.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Padding de pantallas
  static const double screenHorizontal = 16.0;
  static const double screenVertical = 16.0;

  // Padding de cards
  static const double cardPadding = 16.0;

  // Separación entre elementos de lista
  static const double listItemSpacing = 8.0;

  // Altura mínima de elementos táctiles (WCAG 2.1)
  static const double minTouchTarget = 48.0;
}

/// Sistema de radios de bordes.
class AppRadius {
  const AppRadius._();

  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 999.0;
}
