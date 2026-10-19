import 'package:uuid/uuid.dart';

/// Genera UUIDs v4 para todas las entidades sincronizadas.
///
/// Los IDs deben generarse en el cliente para que funcionen offline.
/// Nunca usar IDs autoincrementales como identificadores de sincronización.
class UuidGenerator {
  const UuidGenerator._();

  static const _uuid = Uuid();

  /// Genera un UUID v4 único.
  static String generate() => _uuid.v4();
}
