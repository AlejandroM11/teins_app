# TEINS App — Arquitectura

## Visión general

```
┌─────────────────────────────────────────────────────────┐
│                 Flutter App (Mobile/Tablet)              │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐  │
│  │   Home   │  │  Visits  │  │  Forms   │  │  ...   │  │
│  │Dashboard │  │  List    │  │ Dynamic  │  │        │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └───┬────┘  │
│       │              │              │             │       │
│  ════════════════ PRESENTATION ════════════════════      │
│       │              │              │             │       │
│  ┌────┴──────────────┴──────────────┴─────────────┴──┐   │
│  │          Riverpod Providers / Controllers          │   │
│  └────────────────────┬───────────────────────────────┘   │
│                       │                                   │
│  ════════════════ DOMAIN ═══════════════════════════      │
│                       │                                   │
│  ┌────────────────────┴───────────────────────────────┐   │
│  │    Use Cases    │    Entities    │   Repositories  │   │
│  │  (sin Flutter,  │  (Equatable,  │   (interfaces)  │   │
│  │   sin Supabase) │   sin deps)   │                 │   │
│  └────────────────────┬───────────────────────────────┘   │
│                       │                                   │
│  ════════════════ DATA ════════════════════════════       │
│                       │                                   │
│  ┌────────────────────┴───────────────────────────────┐   │
│  │  Repository Impls  │  Models (DTOs)  │  Datasources│   │
│  └────────┬───────────────────────────────────┬───────┘   │
│           │                                   │           │
└───────────┼───────────────────────────────────┼───────────┘
            │                                   │
    ┌───────┴────────┐                 ┌────────┴────────┐
    │   PowerSync    │                 │    Supabase     │
    │   (SQLite)     │◄───────────────►│   (PostgreSQL)  │
    │   LOCAL        │   Sync Engine   │   REMOTE        │
    └────────────────┘                 └─────────────────┘
```

---

## Principio fundamental: Offline-First

**LOCAL FIRST, SYNC SECOND.**

Toda acción del usuario se persiste en SQLite local antes de intentar cualquier operación remota. PowerSync se encarga de la sincronización bidireccional en background.

```
Usuario actúa
    ↓
SQLite local (inmediato)
    ↓
UI se actualiza (stream reactivo)
    ↓
PowerSync sincroniza cuando hay conexión
    ↓
Supabase recibe los cambios
```

La app trata el modo offline como un **estado normal**, no como un error.

---

## Clean Architecture por capa

### Domain (núcleo del negocio)

- **Entities:** clases Dart puras, sin imports de Flutter, Supabase ni PowerSync. Usan `equatable` para comparación por valor.
- **Use Cases:** una clase = una responsabilidad. Reciben repositorio por interface, retornan `Either<Failure, T>`.
- **Repository interfaces:** contratos que definen qué operaciones existen, sin saber cómo se implementan.

La capa Domain es 100% testeable sin infraestructura.

### Data (infraestructura)

- **Models (DTOs):** manejan serialización `fromRow` / `toRow` / `toEntity` para SQLite. Aislados del dominio.
- **Datasources:** hablan directamente con PowerSync/SQLite. Un datasource = un recurso.
- **Repository Implementations:** implementan las interfaces del dominio usando los datasources.

### Presentation (UI)

- **Providers (Riverpod):** exponen streams y estados derivados de los use cases. No conocen Supabase.
- **Pages:** widgets de pantalla completa que consumen providers. Sin lógica de negocio.
- **Widgets:** componentes reutilizables con responsabilidad única.

---

## Flujo de datos

### Lectura (query)

```
Page
  → watch provider (Riverpod StreamProvider)
    → Use Case
      → Repository (interface)
        → Repository Impl
          → Datasource
            → PowerSyncService.watch(sql)
              → SQLite stream reactivo
                → mapper: Row → Model → Entity
                  → Either<Failure, List<T>>
                    → Page se reconstruye automáticamente
```

### Escritura (command)

```
User action en Page
  → Provider notifier
    → Use Case
      → Repository (interface)
        → Repository Impl
          → Datasource
            → PowerSyncService.execute(sql)
              → SQLite escribe localmente (inmediato)
                → stream reactivo emite nuevo estado
                  → UI actualizada
                    → PowerSync detecta cambio
                      → Sincroniza con Supabase en background
```

---

## PowerSync — arquitectura de sincronización

PowerSync actúa como **motor de sincronización offline-first** entre SQLite (cliente) y PostgreSQL (Supabase).

### Cómo funciona internamente

1. **Client write:** cuando el app ejecuta `INSERT/UPDATE/DELETE`, PowerSync intercepta la operación y la registra en una "upload queue" local.
2. **SQLite view:** PowerSync aplica el schema definido en `powersync_schema.dart` como vistas SQLite sobre sus tablas internas.
3. **Download:** cuando hay conexión, PowerSync descarga los cambios del servidor usando logical replication de PostgreSQL y los aplica localmente.
4. **Upload:** PowerSync llama a `uploadData()` en el conector para enviar los cambios locales al servidor.
5. **Sync Rules:** determinan qué datos descarga cada usuario (configuradas en el dashboard de PowerSync).

### Abstracción del PowerSync

La app no usa `PowerSyncDatabase` directamente en sus features. Todo pasa por `PowerSyncService`:

```dart
// Las features usan esto:
_db.getAll(sql, params)
_db.watch(sql, params)   // Stream reactivo
_db.execute(sql, params)
_db.writeTransaction(callback)

// No usan esto:
PowerSyncDatabase.watch(...)  // API interna de PowerSync
```

Esto permite cambiar el motor de sincronización en el futuro sin tocar los features.

---

## Esquema de base de datos local (SQLite)

Definido en `powersync_schema.dart`. PowerSync aplica este schema sobre sus tablas internas mediante vistas SQLite.

```
profiles           visit_types        form_templates
    │                                      │
    │                                      │
    ▼                                      ▼
visits ─────────────────────────── form_responses
    │
    ├──► visit_materials ─────────► material_catalog
    │
    ├──► photos
    │
    └──► annotations
```

Todas las tablas tienen:
- `id` UUID (generado en el cliente, sin autoincrement)
- `sync_status` para trazabilidad de estado de sincronización
- Timestamps en formato ISO 8601 UTC

---

## Gestión de estado (Riverpod)

### Patrón para datos reactivos (lectura)

```dart
// StreamProvider — se actualiza cuando SQLite cambia
final assignedVisitsProvider = StreamProvider<Either<Failure, List<Visit>>>((ref) {
  final user = ref.watch(currentUserProvider);
  return sl<GetAssignedVisits>()(user.id);
});
```

### Patrón para acciones (escritura)

```dart
// StateNotifier — gestiona el ciclo loading/success/error
class VisitActionController extends StateNotifier<VisitActionState> {
  Future<void> createVisit(CreateVisitParams params) async {
    state = const VisitActionLoading();
    final result = await _createVisit(params);
    result.fold(
      (f) => state = VisitActionError(f),
      (v) => state = VisitActionSuccess(v),
    );
  }
}
```

### Patrón para formularios con autosave

```dart
// Autosave debounced — no bloquea UI, guarda localmente
void updateField(String fieldId, dynamic value) {
  // 1. Actualizar estado en memoria (inmediato)
  state = state.copyWith(response: updatedResponse);
  // 2. Programar guardado en 800ms
  _scheduleAutosave();
}
```

---

## Manejo de errores

### Jerarquía de Failures

```
Failure (abstract, Equatable)
├── NetworkFailure          — sin conexión
├── ServerFailure           — servidor no disponible
├── AuthenticationFailure   — credenciales inválidas
├── SessionExpiredFailure   — sesión expirada
├── UnauthorizedFailure     — sin permiso
├── DatabaseFailure         — error SQLite local
├── SyncFailure             — error de sincronización
├── ConflictFailure         — conflicto de datos
├── ValidationFailure       — datos inválidos (con mensaje)
├── PermissionFailure       — permiso del dispositivo denegado
├── StorageFailure          — error de archivos/storage
└── UnknownFailure          — error inesperado
```

### Mensajes de error al usuario

Los mensajes de `Failure` están escritos en español de campo, sin jerga técnica:

```
❌ "Database transaction failed."        # Nunca
✅ "Error al guardar. Intenta nuevamente." # Siempre
```

---

## Fotografías — flujo completo

```
Cámara/Galería
    ↓
image_picker.pickImage()
    ↓
Comprimir con package:image
  • Redimensionar si > 1920×1080
  • Re-encodar JPEG calidad 85
    ↓
Guardar en ApplicationDocumentsDirectory/teins_photos/{id}.jpg
    ↓
Insertar en SQLite: sync_status = 'pendingUpload'
    ↓
UI muestra foto inmediatamente (local)
    ↓
Si hay Internet: upload async a Supabase Storage
  • visits/{visitId}/photos/{photoId}.jpg
  • Actualizar: sync_status = 'uploaded', storage_url = ...
    ↓
REGLA CRÍTICA: solo borrar archivo local si sync_status = 'uploaded'
```

---

## Canvas de anotaciones — arquitectura

```
VisitAnnotationsPage
    ├── DrawingCanvas (GestureDetector + RepaintBoundary + CustomPaint)
    │       └── AnnotationPainter (CustomPainter)
    │               └── Renderiza List<AnnotationElement>
    │                   • freeStroke (quadraticBezier)
    │                   • line, arrow, rectangle, circle
    │                   • marker, text
    └── AnnotationToolbar
            └── herramientas, colores, grosores
```

**Coordenadas normalizadas (0.0 – 1.0):**
Los puntos se almacenan normalizados respecto al tamaño del canvas. Al renderizar, se escalan al tamaño real del dispositivo. Esto hace que las anotaciones sean independientes de la resolución.

**Optimizaciones:**
- `RepaintBoundary` aísla el canvas del árbol de widgets
- `shouldRepaint` compara referencias de lista (no deep equal)
- Historial de undo: máximo 20 estados en memoria

---

## Seguridad

### Lo que NO está en la app

- `service_role key` de Supabase
- Contraseñas en texto plano
- Secretos en el código fuente
- Tokens en logs

### Lo que SÍ está protegido

- Tokens de sesión en `FlutterSecureStorage` (Keystore en Android, Keychain en iOS)
- `anon key` como `--dart-define` en build time (no en código)
- RLS en Supabase para todas las tablas
- Validación de estados en el dominio (no solo en UI)

---

## Decisiones arquitectónicas

| Decisión | Alternativa considerada | Razón de elección |
|---|---|---|
| PowerSync para sync | Implementación manual | PowerSync maneja queue, conflictos, retry. No reinventar la rueda. |
| Riverpod para estado | BLoC, Provider | Menos boilerplate, compatible con streams de PowerSync |
| get_it para DI | Provider de DI | Sencillo, sin necesidad de contexto de Flutter |
| dartz Either | Excepciones | Fuerza manejo explícito de errores en el dominio |
| Coordenadas normalizadas en canvas | Píxeles absolutos | Independiente de resolución/DPI de cada dispositivo |
| UPSERT con ON CONFLICT | INSERT + UPDATE separados | Idempotente — sincronización repetida no genera duplicados |
| formTemplateVersion en visits | Solo template ID | Protege que cambios de plantilla no rompan visitas históricas |
