import 'package:intl/intl.dart';

/// Utilidades de formato de fechas para la UI.
class AppDateUtils {
  const AppDateUtils._();

  static final _dateFormatter = DateFormat('dd/MM/yyyy');
  static final _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm');
  static final _timeFormatter = DateFormat('HH:mm');
  static final _relativeDateFormatter = DateFormat('dd MMM yyyy', 'es');

  static String formatDate(DateTime date) => _dateFormatter.format(date);

  static String formatDateTime(DateTime date) =>
      _dateTimeFormatter.format(date);

  static String formatTime(DateTime date) => _timeFormatter.format(date);

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Ahora mismo';
    if (difference.inMinutes < 60) return 'Hace ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Hace ${difference.inHours} h';
    if (difference.inDays == 1) return 'Ayer';
    if (difference.inDays < 7) return 'Hace ${difference.inDays} días';

    return _relativeDateFormatter.format(date);
  }

  /// Convierte un ISO 8601 string a DateTime (con manejo seguro de nulos).
  static DateTime? parseIso(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  /// Convierte DateTime a ISO 8601 UTC para almacenamiento/sincronización.
  static String toIso(DateTime date) => date.toUtc().toIso8601String();
}
