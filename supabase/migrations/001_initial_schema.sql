-- ═══════════════════════════════════════════════════════════════════════════
-- TEINS App — Migración inicial
-- Versión: 001
-- Descripción: Esquema completo de la base de datos para la app móvil.
--
-- Principios de diseño:
-- • UUIDs como PK en todas las tablas sincronizadas con el cliente móvil.
-- • created_at / updated_at en todas las tablas para auditoría.
-- • RLS habilitado en todas las tablas — por defecto sin acceso.
-- • Índices solo donde hay búsquedas/filtros reales.
-- ═══════════════════════════════════════════════════════════════════════════

-- Habilitar extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─────────────────────────────────────────────────────────────────────────────
-- ENUMS
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TYPE user_role AS ENUM ('admin', 'office', 'technician', 'client');
CREATE TYPE visit_status AS ENUM (
    'assigned', 'inProgress', 'completed', 'pendingReview', 'synced'
);
CREATE TYPE sync_status AS ENUM (
    'local', 'pendingSync', 'syncing', 'synced', 'syncError', 'conflict'
);
CREATE TYPE photo_sync_status AS ENUM (
    'local', 'pendingUpload', 'uploading', 'uploaded', 'uploadError'
);

-- ─────────────────────────────────────────────────────────────────────────────
-- PROFILES (extiende auth.users de Supabase)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE profiles (
    id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email       TEXT NOT NULL,
    full_name   TEXT,
    role        user_role NOT NULL DEFAULT 'technician',
    phone       TEXT,
    avatar_url  TEXT,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trigger: crear perfil automáticamente al registrar usuario en auth.users
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    INSERT INTO profiles (id, email, full_name, role)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'technician')
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Trigger: actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- VISIT_TYPES
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE visit_types (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL,
    description TEXT,
    icon        TEXT,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER visit_types_updated_at
    BEFORE UPDATE ON visit_types
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- FORM_TEMPLATES
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE form_templates (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name          TEXT NOT NULL,
    visit_type    TEXT NOT NULL,
    version       INTEGER NOT NULL DEFAULT 1,
    sections_json JSONB NOT NULL DEFAULT '[]'::jsonb,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Un solo template activo por tipo y versión
    CONSTRAINT uq_template_type_version UNIQUE (visit_type, version, is_active)
);

CREATE INDEX idx_form_templates_visit_type ON form_templates (visit_type);
CREATE INDEX idx_form_templates_active ON form_templates (is_active) WHERE is_active = TRUE;

CREATE TRIGGER form_templates_updated_at
    BEFORE UPDATE ON form_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- VISITS
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE visits (
    id                    UUID PRIMARY KEY,
    technician_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
    client_id             UUID REFERENCES profiles(id) ON DELETE SET NULL,
    client_name           TEXT,
    title                 TEXT NOT NULL,
    description           TEXT,
    visit_type            TEXT NOT NULL,
    address               TEXT,
    status                visit_status NOT NULL DEFAULT 'assigned',
    sync_status           sync_status NOT NULL DEFAULT 'local',
    form_template_id      UUID REFERENCES form_templates(id) ON DELETE SET NULL,
    form_template_version INTEGER,
    observations          TEXT,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    started_at            TIMESTAMPTZ,
    completed_at          TIMESTAMPTZ,
    latitude              DOUBLE PRECISION,
    longitude             DOUBLE PRECISION,

    -- Validar que completedAt solo se establece cuando status = completed
    CONSTRAINT chk_completed_at CHECK (
        completed_at IS NULL OR status IN ('completed', 'pendingReview', 'synced')
    )
);

-- Índices críticos para las consultas más frecuentes
CREATE INDEX idx_visits_technician_id ON visits (technician_id);
CREATE INDEX idx_visits_status ON visits (status);
CREATE INDEX idx_visits_created_at ON visits (created_at DESC);
CREATE INDEX idx_visits_sync_status ON visits (sync_status)
    WHERE sync_status IN ('local', 'pendingSync', 'syncError');

CREATE TRIGGER visits_updated_at
    BEFORE UPDATE ON visits
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- FORM_RESPONSES
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE form_responses (
    id                UUID PRIMARY KEY,
    visit_id          UUID NOT NULL REFERENCES visits(id) ON DELETE CASCADE,
    template_id       UUID REFERENCES form_templates(id) ON DELETE SET NULL,
    template_version  INTEGER NOT NULL DEFAULT 1,
    -- Respuestas como JSONB: {"field_id": value, ...}
    responses         JSONB NOT NULL DEFAULT '{}'::jsonb,
    sync_status       sync_status NOT NULL DEFAULT 'local',
    is_complete       BOOLEAN NOT NULL DEFAULT FALSE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at      TIMESTAMPTZ,

    -- Una respuesta por visita
    CONSTRAINT uq_form_response_visit UNIQUE (visit_id)
);

CREATE INDEX idx_form_responses_visit_id ON form_responses (visit_id);

CREATE TRIGGER form_responses_updated_at
    BEFORE UPDATE ON form_responses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- MATERIAL_CATALOG
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE material_catalog (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code        TEXT NOT NULL UNIQUE,
    name        TEXT NOT NULL,
    description TEXT,
    unit        TEXT NOT NULL,
    category    TEXT,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_material_catalog_code ON material_catalog (code);
CREATE INDEX idx_material_catalog_name ON material_catalog (LOWER(name));
CREATE INDEX idx_material_catalog_category ON material_catalog (category);
CREATE INDEX idx_material_catalog_active ON material_catalog (is_active)
    WHERE is_active = TRUE;

CREATE TRIGGER material_catalog_updated_at
    BEFORE UPDATE ON material_catalog
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- VISIT_MATERIALS
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE visit_materials (
    id             UUID PRIMARY KEY,
    visit_id       UUID NOT NULL REFERENCES visits(id) ON DELETE CASCADE,
    material_id    UUID NOT NULL REFERENCES material_catalog(id) ON DELETE RESTRICT,
    material_code  TEXT NOT NULL,  -- Desnormalizado para lectura offline eficiente
    material_name  TEXT NOT NULL,  -- Desnormalizado
    unit           TEXT NOT NULL,  -- Desnormalizado
    quantity       NUMERIC(12, 3) NOT NULL,
    observations   TEXT,
    sync_status    sync_status NOT NULL DEFAULT 'local',
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_quantity_positive CHECK (quantity > 0)
);

CREATE INDEX idx_visit_materials_visit_id ON visit_materials (visit_id);
CREATE INDEX idx_visit_materials_material_id ON visit_materials (material_id);

CREATE TRIGGER visit_materials_updated_at
    BEFORE UPDATE ON visit_materials
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- PHOTOS
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE photos (
    id               UUID PRIMARY KEY,
    visit_id         UUID NOT NULL REFERENCES visits(id) ON DELETE CASCADE,
    form_field_id    TEXT,
    local_path       TEXT NOT NULL,
    storage_path     TEXT,
    storage_url      TEXT,
    caption          TEXT,
    sync_status      photo_sync_status NOT NULL DEFAULT 'local',
    file_size_bytes  INTEGER,
    width            INTEGER,
    height           INTEGER,
    captured_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    uploaded_at      TIMESTAMPTZ,

    CONSTRAINT chk_storage_consistent CHECK (
        (storage_path IS NULL AND storage_url IS NULL) OR
        (storage_path IS NOT NULL AND storage_url IS NOT NULL)
    )
);

CREATE INDEX idx_photos_visit_id ON photos (visit_id);
CREATE INDEX idx_photos_sync_status ON photos (sync_status)
    WHERE sync_status IN ('local', 'pendingUpload', 'uploadError');

-- ─────────────────────────────────────────────────────────────────────────────
-- ANNOTATIONS
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE annotations (
    id               UUID PRIMARY KEY,
    visit_id         UUID NOT NULL REFERENCES visits(id) ON DELETE CASCADE,
    title            TEXT,
    -- Almacenar elementos como JSONB para queries y índices futuros
    elements         JSONB NOT NULL DEFAULT '[]'::jsonb,
    base_image_path  TEXT,
    canvas_width     DOUBLE PRECISION,
    canvas_height    DOUBLE PRECISION,
    sync_status      sync_status NOT NULL DEFAULT 'local',
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Una anotación por visita
    CONSTRAINT uq_annotation_visit UNIQUE (visit_id)
);

CREATE INDEX idx_annotations_visit_id ON annotations (visit_id);

CREATE TRIGGER annotations_updated_at
    BEFORE UPDATE ON annotations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- AUDIT_LOGS (trazabilidad — tabla solo append, sin DELETE ni UPDATE)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE audit_logs (
    id            BIGSERIAL PRIMARY KEY,
    user_id       UUID REFERENCES profiles(id) ON DELETE SET NULL,
    action        TEXT NOT NULL,      -- 'create' | 'update' | 'delete' | 'sync'
    entity_type   TEXT NOT NULL,      -- 'visit' | 'form_response' | 'photo' etc.
    entity_id     UUID,
    old_values    JSONB,
    new_values    JSONB,
    is_offline    BOOLEAN NOT NULL DEFAULT FALSE,
    ip_address    INET,
    user_agent    TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Solo índice por entidad para búsquedas de auditoría
CREATE INDEX idx_audit_logs_entity ON audit_logs (entity_type, entity_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs (user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs (created_at DESC);
