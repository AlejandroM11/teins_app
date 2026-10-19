import 'package:powersync/powersync.dart';

/// Esquema SQLite local gestionado por PowerSync.
///
/// DISEÑO CLAVE:
/// PowerSync sincroniza datos schemaless desde Postgres y aplica
/// este esquema mediante SQLite views. No necesitamos migraciones
/// manuales en el cliente — PowerSync gestiona los cambios de esquema.
///
/// Tablas locales = subconjunto de las tablas Postgres, con solo
/// las columnas que el técnico necesita para trabajar en campo.
///
/// Índices: definidos solo donde hay búsquedas/filtros reales.
const schema = Schema([
    // ── Perfiles de usuario ───────────────────────────────────────────────
    Table(
      'profiles',
      [
        Column.text('email'),
        Column.text('full_name'),
        Column.text('role'),
        Column.text('phone'),
        Column.text('avatar_url'),
      ],
    ),

    // ── Tipos de visita ───────────────────────────────────────────────────
    Table(
      'visit_types',
      [
        Column.text('name'),
        Column.text('description'),
        Column.text('icon'),
        Column.integer('is_active'),
      ],
    ),

    // ── Plantillas de formulario ──────────────────────────────────────────
    Table(
      'form_templates',
      [
        Column.text('name'),
        Column.text('visit_type'),
        Column.integer('version'),
        Column.text('sections_json'),  // JSON serializado de las secciones
        Column.integer('is_active'),
        Column.text('created_at'),
        Column.text('updated_at'),
      ],
      indexes: [
        Index('ft_visit_type', [IndexedColumn('visit_type')]),
      ],
    ),

    // ── Visitas ───────────────────────────────────────────────────────────
    Table(
      'visits',
      [
        Column.text('technician_id'),
        Column.text('client_id'),
        Column.text('client_name'),
        Column.text('title'),
        Column.text('description'),
        Column.text('visit_type'),
        Column.text('address'),
        Column.text('status'),
        Column.text('sync_status'),
        Column.text('form_template_id'),
        Column.integer('form_template_version'),
        Column.text('observations'),
        Column.text('created_at'),
        Column.text('updated_at'),
        Column.text('started_at'),
        Column.text('completed_at'),
        Column.real('latitude'),
        Column.real('longitude'),
      ],
      indexes: [
        Index('v_technician', [IndexedColumn('technician_id')]),
        Index('v_status', [IndexedColumn('status')]),
        Index('v_created', [IndexedColumn('created_at', ascending: false)]),
      ],
    ),

    // ── Respuestas de formulario ──────────────────────────────────────────
    Table(
      'form_responses',
      [
        Column.text('visit_id'),
        Column.text('template_id'),
        Column.integer('template_version'),
        Column.text('responses_json'),  // Map<fieldId, value> serializado
        Column.text('sync_status'),
        Column.integer('is_complete'),
        Column.text('created_at'),
        Column.text('updated_at'),
        Column.text('completed_at'),
      ],
      indexes: [
        Index('fr_visit', [IndexedColumn('visit_id')]),
      ],
    ),

    // ── Catálogo de materiales ────────────────────────────────────────────
    Table(
      'material_catalog',
      [
        Column.text('code'),
        Column.text('name'),
        Column.text('description'),
        Column.text('unit'),
        Column.text('category'),
        Column.integer('is_active'),
      ],
      indexes: [
        // Índice de texto para búsquedas por nombre y código
        Index('mc_code', [IndexedColumn('code')]),
        Index('mc_name', [IndexedColumn('name')]),
        Index('mc_category', [IndexedColumn('category')]),
      ],
    ),

    // ── Materiales de visita ──────────────────────────────────────────────
    Table(
      'visit_materials',
      [
        Column.text('visit_id'),
        Column.text('material_id'),
        Column.text('material_code'),
        Column.text('material_name'),
        Column.text('unit'),
        Column.real('quantity'),
        Column.text('observations'),
        Column.text('sync_status'),
        Column.text('created_at'),
        Column.text('updated_at'),
      ],
      indexes: [
        Index('vm_visit', [IndexedColumn('visit_id')]),
      ],
    ),

    // ── Fotografías ───────────────────────────────────────────────────────
    Table(
      'photos',
      [
        Column.text('visit_id'),
        Column.text('form_field_id'),
        Column.text('local_path'),
        Column.text('storage_path'),
        Column.text('storage_url'),
        Column.text('caption'),
        Column.text('sync_status'),
        Column.text('captured_at'),
        Column.text('uploaded_at'),
        Column.integer('file_size_bytes'),
        Column.integer('width'),
        Column.integer('height'),
      ],
      indexes: [
        Index('ph_visit', [IndexedColumn('visit_id')]),
        Index('ph_sync', [IndexedColumn('sync_status')]),
      ],
    ),

    // ── Anotaciones ───────────────────────────────────────────────────────
    Table(
      'annotations',
      [
        Column.text('visit_id'),
        Column.text('title'),
        Column.text('elements_json'),    // Lista de AnnotationElement serializada
        Column.text('base_image_path'),
        Column.real('canvas_width'),
        Column.real('canvas_height'),
        Column.text('sync_status'),
        Column.text('created_at'),
        Column.text('updated_at'),
      ],
      indexes: [
        Index('an_visit', [IndexedColumn('visit_id')]),
      ],
    ),
]);
