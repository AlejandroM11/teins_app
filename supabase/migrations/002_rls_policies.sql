-- ═══════════════════════════════════════════════════════════════════════════
-- TEINS App — Row Level Security (RLS) Policies
-- Versión: 002
--
-- Principios de seguridad:
-- • RLS habilitado en TODAS las tablas.
-- • Sin política → sin acceso (deny by default).
-- • NUNCA usar service_role en la app móvil.
-- • Acceso mínimo necesario por rol.
-- ═══════════════════════════════════════════════════════════════════════════

-- ── Helper functions ──────────────────────────────────────────────────────────

-- Obtiene el rol del usuario actual desde la tabla profiles
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS user_role LANGUAGE sql STABLE SECURITY DEFINER AS $$
    SELECT role FROM profiles WHERE id = auth.uid() LIMIT 1;
$$;

-- Verifica si el usuario actual es técnico
CREATE OR REPLACE FUNCTION is_technician()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
    SELECT EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND role = 'technician' AND is_active = TRUE
    );
$$;

-- Verifica si el usuario actual es admin u oficina
CREATE OR REPLACE FUNCTION is_admin_or_office()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
    SELECT EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND role IN ('admin', 'office') AND is_active = TRUE
    );
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- PROFILES
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Cada usuario puede leer su propio perfil
CREATE POLICY "profiles_select_own"
    ON profiles FOR SELECT
    USING (id = auth.uid());

-- Admin y oficina pueden leer todos los perfiles
CREATE POLICY "profiles_select_all_admin_office"
    ON profiles FOR SELECT
    USING (is_admin_or_office());

-- Cada usuario puede actualizar su propio perfil (excepto rol e is_active)
CREATE POLICY "profiles_update_own"
    ON profiles FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (
        id = auth.uid()
        AND role = (SELECT role FROM profiles WHERE id = auth.uid())
        AND is_active = (SELECT is_active FROM profiles WHERE id = auth.uid())
    );

-- Solo admin puede actualizar roles
CREATE POLICY "profiles_update_admin"
    ON profiles FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- ─────────────────────────────────────────────────────────────────────────────
-- VISIT_TYPES — Solo lectura para autenticados
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE visit_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY "visit_types_select_authenticated"
    ON visit_types FOR SELECT
    TO authenticated
    USING (is_active = TRUE);

CREATE POLICY "visit_types_manage_admin"
    ON visit_types FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- ─────────────────────────────────────────────────────────────────────────────
-- FORM_TEMPLATES — Lectura para técnicos, gestión para admin
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE form_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "form_templates_select_authenticated"
    ON form_templates FOR SELECT
    TO authenticated
    USING (is_active = TRUE);

CREATE POLICY "form_templates_manage_admin"
    ON form_templates FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- ─────────────────────────────────────────────────────────────────────────────
-- VISITS
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE visits ENABLE ROW LEVEL SECURITY;

-- Técnico: ver solo sus propias visitas
CREATE POLICY "visits_select_own_technician"
    ON visits FOR SELECT
    USING (
        technician_id = auth.uid()
        AND is_technician()
    );

-- Admin y oficina: ver todas las visitas
CREATE POLICY "visits_select_all_admin_office"
    ON visits FOR SELECT
    USING (is_admin_or_office());

-- Técnico: crear nuevas visitas asignadas a sí mismo
CREATE POLICY "visits_insert_technician"
    ON visits FOR INSERT
    WITH CHECK (
        technician_id = auth.uid()
        AND is_technician()
    );

-- Técnico: actualizar solo sus propias visitas
CREATE POLICY "visits_update_own_technician"
    ON visits FOR UPDATE
    USING (
        technician_id = auth.uid()
        AND is_technician()
    )
    WITH CHECK (
        technician_id = auth.uid()
        -- No permitir cambiar el técnico asignado
        AND technician_id = (SELECT technician_id FROM visits WHERE id = visits.id)
    );

-- Admin y oficina: actualizar cualquier visita
CREATE POLICY "visits_update_admin_office"
    ON visits FOR UPDATE
    USING (is_admin_or_office());

-- Solo admin puede eliminar visitas
CREATE POLICY "visits_delete_admin"
    ON visits FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- ─────────────────────────────────────────────────────────────────────────────
-- FORM_RESPONSES
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE form_responses ENABLE ROW LEVEL SECURITY;

-- Técnico: ver y editar solo respuestas de sus visitas
CREATE POLICY "form_responses_own_technician"
    ON form_responses FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM visits
            WHERE visits.id = form_responses.visit_id
            AND visits.technician_id = auth.uid()
        )
        AND is_technician()
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM visits
            WHERE visits.id = form_responses.visit_id
            AND visits.technician_id = auth.uid()
        )
    );

-- Admin y oficina: ver todas las respuestas
CREATE POLICY "form_responses_select_admin_office"
    ON form_responses FOR SELECT
    USING (is_admin_or_office());

-- ─────────────────────────────────────────────────────────────────────────────
-- MATERIAL_CATALOG
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE material_catalog ENABLE ROW LEVEL SECURITY;

-- Todos los autenticados pueden leer el catálogo
CREATE POLICY "material_catalog_select_authenticated"
    ON material_catalog FOR SELECT
    TO authenticated
    USING (is_active = TRUE);

-- Solo admin puede gestionar el catálogo
CREATE POLICY "material_catalog_manage_admin"
    ON material_catalog FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- ─────────────────────────────────────────────────────────────────────────────
-- VISIT_MATERIALS
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE visit_materials ENABLE ROW LEVEL SECURITY;

CREATE POLICY "visit_materials_own_technician"
    ON visit_materials FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM visits
            WHERE visits.id = visit_materials.visit_id
            AND visits.technician_id = auth.uid()
        )
        AND is_technician()
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM visits
            WHERE visits.id = visit_materials.visit_id
            AND visits.technician_id = auth.uid()
        )
    );

CREATE POLICY "visit_materials_select_admin_office"
    ON visit_materials FOR SELECT
    USING (is_admin_or_office());

-- ─────────────────────────────────────────────────────────────────────────────
-- PHOTOS
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "photos_own_technician"
    ON photos FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM visits
            WHERE visits.id = photos.visit_id
            AND visits.technician_id = auth.uid()
        )
        AND is_technician()
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM visits
            WHERE visits.id = photos.visit_id
            AND visits.technician_id = auth.uid()
        )
    );

CREATE POLICY "photos_select_admin_office"
    ON photos FOR SELECT
    USING (is_admin_or_office());

-- ─────────────────────────────────────────────────────────────────────────────
-- ANNOTATIONS
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE annotations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "annotations_own_technician"
    ON annotations FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM visits
            WHERE visits.id = annotations.visit_id
            AND visits.technician_id = auth.uid()
        )
        AND is_technician()
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM visits
            WHERE visits.id = annotations.visit_id
            AND visits.technician_id = auth.uid()
        )
    );

CREATE POLICY "annotations_select_admin_office"
    ON annotations FOR SELECT
    USING (is_admin_or_office());

-- ─────────────────────────────────────────────────────────────────────────────
-- AUDIT_LOGS — Solo lectura para admin
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "audit_logs_select_admin"
    ON audit_logs FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Solo el sistema (via service_role en backend) puede insertar audit logs
-- No policy de INSERT para authenticated — solo via service_role desde Edge Functions
