# TEINS — Aplicación Móvil de Visitas Técnicas

Aplicación móvil offline-first para técnicos de campo de TEINS. Permite realizar visitas técnicas completas sin conexión a Internet, sincronizando automáticamente con Supabase cuando vuelve la conectividad.

---

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| Mobile | Flutter / Dart |
| Base local | SQLite (via PowerSync) |
| Sincronización | PowerSync |
| Backend | Supabase (PostgreSQL) |
| Auth | Supabase Auth |
| Storage | Supabase Storage |
| Formularios | flutter_form_builder |
| Dibujo | Flutter CustomPainter |
| Estado | Riverpod |
| Navegación | go_router |
| DI | get_it |

---

## Requisitos previos

- Flutter `>=3.19.0` — [instalar Flutter](https://docs.flutter.dev/get-started/install)
- Dart `>=3.3.0`
- Cuenta en [Supabase](https://supabase.com)
- Cuenta en [PowerSync](https://powersync.com)
- Android Studio o Xcode para compilar en dispositivo

---

## Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/teins/teins_app.git
cd teins_app
```

### 2. Configurar variables de entorno

```bash
cp .env.example .env
```

Editar `.env` con los valores reales:

```
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key
POWERSYNC_URL=https://your-instance.powersync.journeyapps.com
APP_ENV=development
LOG_LEVEL=debug
```

> **Importante:** Nunca usar la `service_role` key en la app móvil. Solo la `anon` key es segura para el cliente.

### 3. Instalar dependencias

```bash
flutter pub get
```

### 4. Configurar Supabase

#### a. Ejecutar migraciones

En el SQL Editor de Supabase, ejecutar en orden:

```
supabase/migrations/001_initial_schema.sql
supabase/migrations/002_rls_policies.sql
supabase/migrations/003_storage_policies.sql
supabase/migrations/004_powersync_config.sql
```

#### b. Cargar datos de demostración (desarrollo)

```
supabase/seed/001_demo_data.sql
```

#### c. Crear usuarios demo en Supabase Auth

En **Authentication > Users**, crear:
- `tecnico@teins.com` / `Teins2025!` — con metadata `{"role": "technician", "full_name": "Carlos Técnico Demo"}`
- `oficina@teins.com` / `Teins2025!` — con metadata `{"role": "office", "full_name": "Ana Oficina Demo"}`

> Los UUIDs deben coincidir con los del seed. Actualizar el seed si son diferentes.

### 5. Configurar PowerSync

1. Crear un proyecto en [PowerSync Dashboard](https://powersync.journeyapps.com)
2. Conectar con Supabase (proporcionar PostgreSQL connection string)
3. En **Sync Rules**, crear reglas para que cada técnico sincronice solo sus datos:

```yaml
bucket_definitions:
  technician_data:
    parameters:
      - name: user_id
        value: token_parameters.user_id
    data:
      - SELECT * FROM visits WHERE technician_id = {user_id}
      - SELECT fr.* FROM form_responses fr
          JOIN visits v ON fr.visit_id = v.id
          WHERE v.technician_id = {user_id}
      - SELECT vm.* FROM visit_materials vm
          JOIN visits v ON vm.visit_id = v.id
          WHERE v.technician_id = {user_id}
      - SELECT p.* FROM photos p
          JOIN visits v ON p.visit_id = v.id
          WHERE v.technician_id = {user_id}
      - SELECT a.* FROM annotations a
          JOIN visits v ON a.visit_id = v.id
          WHERE v.technician_id = {user_id}
      - SELECT * FROM form_templates WHERE is_active = true
      - SELECT * FROM material_catalog WHERE is_active = true
      - SELECT * FROM visit_types WHERE is_active = true
      - SELECT * FROM profiles WHERE id = {user_id}
```

4. Obtener la **PowerSync URL** del dashboard y colocarla en `.env`

---

## Ejecución

### Desarrollo (con variables de entorno)

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=POWERSYNC_URL=https://your-instance.powersync.journeyapps.com \
  --dart-define=APP_ENV=development \
  --dart-define=LOG_LEVEL=debug
```

### Script de desarrollo (recomendado)

Crear `run_dev.sh`:

```bash
#!/bin/bash
flutter run \
  --dart-define=SUPABASE_URL="$(grep SUPABASE_URL .env | cut -d= -f2)" \
  --dart-define=SUPABASE_ANON_KEY="$(grep SUPABASE_ANON_KEY .env | cut -d= -f2)" \
  --dart-define=POWERSYNC_URL="$(grep POWERSYNC_URL .env | cut -d= -f2)" \
  --dart-define=APP_ENV=development \
  --dart-define=LOG_LEVEL=debug \
  "$@"
```

---

## Testing

```bash
# Todos los tests
flutter test

# Tests específicos
flutter test test/features/visits/
flutter test test/core/

# Con cobertura
flutter test --coverage
```

---

## Estructura de carpetas

```
lib/
├── app/                          # Configuración de la app (router, tema)
├── core/                         # Código compartido
│   ├── config/                   # AppConfig con --dart-define
│   ├── constants/                # Constantes globales
│   ├── di/                       # Inyección de dependencias (get_it)
│   ├── errors/                   # Failures y Exceptions tipados
│   ├── extensions/               # String, etc.
│   ├── network/                  # ConnectivityService
│   ├── permissions/              # PermissionService
│   ├── routing/                  # go_router centralizado
│   ├── storage/                  # SecureStorageService
│   ├── theme/                    # Design system (colores, tipografía, espaciado)
│   ├── utils/                    # Logger, UuidGenerator, DateUtils
│   └── widgets/                  # Widgets reutilizables
│
└── features/
    ├── authentication/           # Login, sesión, logout
    ├── visits/                   # CRUD visitas, estados, listado
    ├── dynamic_forms/            # Motor de formularios dinámicos + autosave
    ├── materials/                # Catálogo y materiales por visita
    ├── photos/                   # Captura, compresión, galería
    ├── annotations/              # CustomPainter, canvas de dibujo
    ├── home/                     # Dashboard del técnico
    └── synchronization/          # PowerSync, estados de sync
```

Cada feature sigue Clean Architecture:
```
feature/
├── data/
│   ├── datasources/      # SQLite (via PowerSync) / Supabase
│   ├── models/           # DTOs con serialización fromRow/toRow
│   └── repositories/     # Implementaciones concretas
├── domain/
│   ├── entities/         # Clases de dominio puras (sin Flutter)
│   ├── repositories/     # Interfaces (contratos)
│   └── usecases/         # Un caso de uso = una responsabilidad
└── presentation/
    ├── pages/            # Pantallas
    ├── providers/        # Riverpod providers + controllers
    └── widgets/          # Widgets del feature
```

---

## Flujo offline

```
Técnico realiza acción
        ↓
  Guarda en SQLite local
        ↓
  UI se actualiza inmediatamente
        ↓
  ¿Hay Internet?
   ├── SÍ: PowerSync sincroniza en background
   └── NO: cambio queda en cola (sync_status = pendingSync)
        ↓
  Cuando vuelve Internet:
  PowerSync detecta cambios pendientes
        ↓
  Sincronización automática
        ↓
  sync_status → synced
```

**Comportamiento ante pérdida de conexión:**
- Formularios: autosave en SQLite cada 800ms, no se pierde nada
- Fotos: se guardan localmente, se suben al recuperar conexión
- Anotaciones: autosave en SQLite cada 1600ms
- Visitas/materiales: guardado inmediato en SQLite

---

## Sincronización — casos cubiertos

| Caso | Comportamiento |
|---|---|
| Crear visita offline → cerrar app → abrir | Datos persisten en SQLite |
| Completar formulario offline → recuperar Internet | PowerSync sincroniza automáticamente |
| Perder Internet durante sincronización | Reintento automático al volver |
| Internet inestable (cortes repetidos) | PowerSync maneja reconexión |
| App cerrada durante sync | Al abrir, sync continúa desde donde quedó |
| Misma operación enviada dos veces | `ON CONFLICT DO UPDATE` previene duplicados |
| Foto subida → borrar local | Solo se borra si `sync_status = uploaded` |

---

## Seguridad

- Solo `anon key` en la app móvil. La `service_role key` solo en backend.
- RLS activo en todas las tablas.
- Técnico solo ve/edita sus propias visitas.
- Tokens y credenciales en `FlutterSecureStorage` (Keystore/Keychain).
- No se loguean contraseñas ni tokens.
- Permisos de cámara/storage solicitados en el momento necesario.

---

## Variables de entorno

| Variable | Descripción | Obligatoria |
|---|---|---|
| `SUPABASE_URL` | URL del proyecto Supabase | Sí |
| `SUPABASE_ANON_KEY` | Clave anon pública de Supabase | Sí |
| `POWERSYNC_URL` | URL de la instancia PowerSync | Sí |
| `APP_ENV` | `development` \| `staging` \| `production` | No (default: development) |
| `LOG_LEVEL` | `debug` \| `info` \| `warning` \| `error` \| `none` | No (default: debug) |

---

## Troubleshooting

**PowerSync no sincroniza:**
1. Verificar `POWERSYNC_URL` en `.env`
2. Confirmar que la publicación de replicación existe: `SELECT * FROM pg_publication`
3. Revisar Sync Rules en el dashboard de PowerSync
4. Verificar conectividad: el banner de estado en la app indica el estado

**Formulario no carga:**
- Las plantillas se cargan desde `assets/templates/form_templates.json` como fallback
- Si SQLite está vacío, el seed se ejecuta automáticamente

**Fotos no suben:**
- Verificar que el bucket `visit-photos` existe en Supabase Storage
- Revisar políticas RLS del bucket (migración 003)
- Las fotos locales permanecen en el dispositivo hasta confirmar upload

**Tests fallan con mocks:**
```bash
dart run build_runner build --delete-conflicting-outputs
```
