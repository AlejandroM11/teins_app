import 'package:logger/logger.dart';
import '../config/app_config.dart';

/// Logger centralizado de la aplicación.
///
/// Usa niveles de log controlados por entorno.
/// NUNCA registrar contraseñas, tokens ni información sensible.
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: _resolveLevel(),
  );

  static Level _resolveLevel() {
    switch (AppConfig.logLevel) {
      case AppLogLevel.debug:
        return Level.debug;
      case AppLogLevel.info:
        return Level.info;
      case AppLogLevel.warning:
        return Level.warning;
      case AppLogLevel.error:
        return Level.error;
      case AppLogLevel.none:
        return Level.off;
    }
  }

  static void d(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  static void i(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  static void w(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void e(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
