extension StringExtensions on String {
  /// Retorna null si el string está vacío o es solo espacios.
  String? get nullIfEmpty => trim().isEmpty ? null : this;

  /// Capitaliza la primera letra.
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';

  /// Valida formato de email básico.
  bool get isValidEmail => RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      ).hasMatch(this);
}

extension NullableStringExtensions on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  String get orEmpty => this ?? '';
}
