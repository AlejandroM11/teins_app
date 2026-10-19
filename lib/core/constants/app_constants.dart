/// Constantes globales de la aplicación.
/// Centralizar aquí evita strings/números mágicos dispersos.
class AppConstants {
  const AppConstants._();

  // ── Almacenamiento seguro ─────────────────────────────────────────────────
  static const String kAuthTokenKey = 'auth_token';
  static const String kRefreshTokenKey = 'refresh_token';
  static const String kUserIdKey = 'user_id';
  static const String kLastSyncKey = 'last_sync_timestamp';

  // ── Base de datos local ───────────────────────────────────────────────────
  static const String kDbName = 'teins_local.db';
  static const int kDbSchemaVersion = 1;

  // ── Sincronización ────────────────────────────────────────────────────────
  /// Tiempo de espera antes de reintentar una sincronización fallida (ms).
  static const int kSyncRetryDelayMs = 5000;
  /// Máximo número de reintentos automáticos por sesión.
  static const int kMaxSyncRetries = 3;

  // ── Fotografías ───────────────────────────────────────────────────────────
  /// Ancho máximo al que se redimensiona una fotografía antes de guardarla.
  static const int kPhotoMaxWidth = 1920;
  static const int kPhotoMaxHeight = 1080;
  /// Calidad JPEG (0-100).
  static const int kPhotoJpegQuality = 85;
  /// Tamaño máximo permitido en bytes antes de comprimir (5 MB).
  static const int kPhotoMaxBytes = 5 * 1024 * 1024;

  // ── Formularios ───────────────────────────────────────────────────────────
  /// Debounce para autosave de formularios (ms).
  static const int kFormAutosaveDebounceMs = 800;

  // ── UI ────────────────────────────────────────────────────────────────────
  /// Duración estándar de animaciones (ms).
  static const int kAnimationDurationMs = 250;
  /// Tamaño mínimo de área táctil según WCAG 2.1.
  static const double kMinTouchTarget = 48.0;

  // ── Paginación ────────────────────────────────────────────────────────────
  static const int kVisitsPageSize = 20;
  static const int kMaterialsPageSize = 30;
  static const int kPhotosPageSize = 20;

  // ── Storage Supabase ─────────────────────────────────────────────────────
  static const String kPhotosBucket = 'visit-photos';

  /// Ruta de fotos: visits/{visitId}/photos/{photoId}.jpg
  static String photosPath(String visitId, String photoId) =>
      'visits/$visitId/photos/$photoId.jpg';

  // ── Roles ─────────────────────────────────────────────────────────────────
  static const String kRoleTechnician = 'technician';
  static const String kRoleOffice = 'office';
  static const String kRoleClient = 'client';
  static const String kRoleAdmin = 'admin';
}
