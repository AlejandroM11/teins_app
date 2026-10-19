-- ═══════════════════════════════════════════════════════════════════════════
-- TEINS App — Configuración para PowerSync
-- Versión: 004
--
-- PowerSync requiere que las tablas que sincroniza tengan:
-- 1. UUID como clave primaria
-- 2. Columna updated_at con timestamp
-- 3. Triggers para updated_at (ya creados en migración 001)
--
-- Publicación de replicación: expone las tablas al motor de PowerSync.
-- PowerSync usa logical replication de PostgreSQL para detectar cambios.
-- ═══════════════════════════════════════════════════════════════════════════

-- Crear publicación para PowerSync (requiere usuario con privilegio REPLICATION)
-- Nota: En Supabase, ejecutar esto como usuario postgres en el SQL Editor.

-- La publicación incluye solo las tablas que el técnico necesita offline.
-- NO incluir audit_logs (solo append, grande) ni profiles completos.

DO $$
BEGIN
    -- Verificar si la publicación ya existe
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication WHERE pubname = 'powersync'
    ) THEN
        CREATE PUBLICATION powersync FOR TABLE
            profiles,
            visit_types,
            form_templates,
            visits,
            form_responses,
            material_catalog,
            visit_materials,
            photos,
            annotations;
        RAISE NOTICE 'Publicación PowerSync creada.';
    ELSE
        RAISE NOTICE 'Publicación PowerSync ya existe.';
    END IF;
END;
$$;

-- ── Función de autenticación PowerSync ───────────────────────────────────────
-- PowerSync llama esta función para validar el JWT del usuario
-- y determinar qué datos puede sincronizar.
--
-- El servidor PowerSync (configurado en powersync.journeyapps.com) usa
-- el Supabase JWT para autenticar al usuario. El filtro de sincronización
-- se configura en el dashboard de PowerSync, no aquí.
--
-- Referencia: https://docs.powersync.com/integration-guides/supabase-+-powersync

-- ── Regla de negocio: un técnico solo sincroniza SUS visitas ──────────────────
-- Esto se configura en el PowerSync Dashboard con una Sync Rule como:
--
-- bucket_definitions:
--   technician_data:
--     parameters:
--       - name: user_id
--         value: token_parameters.user_id
--     data:
--       - SELECT * FROM visits WHERE technician_id = {user_id}
--       - SELECT fr.* FROM form_responses fr
--           JOIN visits v ON fr.visit_id = v.id
--           WHERE v.technician_id = {user_id}
--       - SELECT vm.* FROM visit_materials vm
--           JOIN visits v ON vm.visit_id = v.id
--           WHERE v.technician_id = {user_id}
--       - SELECT p.* FROM photos p
--           JOIN visits v ON p.visit_id = v.id
--           WHERE v.technician_id = {user_id}
--       - SELECT a.* FROM annotations a
--           JOIN visits v ON a.visit_id = v.id
--           WHERE v.technician_id = {user_id}
--       - SELECT * FROM form_templates WHERE is_active = true
--       - SELECT * FROM material_catalog WHERE is_active = true
--       - SELECT * FROM visit_types WHERE is_active = true
--       - SELECT * FROM profiles WHERE id = {user_id}

-- ── Índices adicionales para rendimiento de replicación ──────────────────────
-- PowerSync consulta updated_at frecuentemente para detectar cambios

CREATE INDEX IF NOT EXISTS idx_visits_updated_at
    ON visits (updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_form_responses_updated_at
    ON form_responses (updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_visit_materials_updated_at
    ON visit_materials (updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_photos_captured_at
    ON photos (captured_at DESC);

CREATE INDEX IF NOT EXISTS idx_annotations_updated_at
    ON annotations (updated_at DESC);
