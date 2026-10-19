-- ═══════════════════════════════════════════════════════════════════════════
-- TEINS App — Supabase Storage Policies
-- Versión: 003
-- Descripción: Configuración del bucket de fotos y políticas de acceso.
-- ═══════════════════════════════════════════════════════════════════════════

-- Crear bucket de fotografías de visitas
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'visit-photos',
    'visit-photos',
    FALSE,   -- Privado: requiere autenticación para leer/escribir
    5242880, -- 5 MB límite por archivo
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ── Política de subida ────────────────────────────────────────────────────────
-- Técnico solo puede subir fotos en la ruta: visits/{su_visita_id}/photos/{photo_id}.jpg
-- La validación del visitId se hace comparando con sus visitas asignadas.

CREATE POLICY "photos_upload_technician"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'visit-photos'
        AND (
            -- La ruta debe empezar con visits/{visitId} donde visitId pertenece al técnico
            EXISTS (
                SELECT 1 FROM public.visits
                WHERE
                    visits.technician_id = auth.uid()
                    AND starts_with(name, 'visits/' || visits.id::text || '/')
            )
        )
    );

-- ── Política de lectura ────────────────────────────────────────────────────────
-- Técnico solo puede ver fotos de sus propias visitas
-- Admin y oficina pueden ver todas

CREATE POLICY "photos_select_own_technician"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'visit-photos'
        AND (
            -- Técnico: solo sus visitas
            EXISTS (
                SELECT 1 FROM public.visits
                WHERE
                    visits.technician_id = auth.uid()
                    AND starts_with(name, 'visits/' || visits.id::text || '/')
            )
            OR
            -- Admin/oficina: acceso completo
            EXISTS (
                SELECT 1 FROM public.profiles
                WHERE id = auth.uid() AND role IN ('admin', 'office')
            )
        )
    );

-- ── Política de actualización (re-subida) ──────────────────────────────────────

CREATE POLICY "photos_update_own_technician"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'visit-photos'
        AND EXISTS (
            SELECT 1 FROM public.visits
            WHERE
                visits.technician_id = auth.uid()
                AND starts_with(name, 'visits/' || visits.id::text || '/')
        )
    );

-- ── Política de eliminación ────────────────────────────────────────────────────
-- Solo admin puede eliminar fotos (técnico elimina via la app que gestiona el registro)

CREATE POLICY "photos_delete_admin"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'visit-photos'
        AND EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );
