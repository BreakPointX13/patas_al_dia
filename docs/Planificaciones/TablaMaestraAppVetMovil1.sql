-- Esquema de Supabase (PostgreSQL) para Patas al Día.
--
-- Fuente de verdad: el schema real de `lib/data/database/database_helper.dart`
-- (SQLite, local). Este archivo es la traducción de ese schema a Postgres,
-- más Row Level Security (RLS) — no hay sincronización automática entre los
-- dos: cada cambio de tabla futuro se aplica a mano acá y en
-- `database_helper.dart` (ver `decisiones_arquitectura.md`, entrada del
-- 2026-08-18). Se pega tal cual en el SQL Editor de Supabase.
--
-- Pendiente para las próximas fases (no resuelto en este archivo):
-- - `usuarios.id` referencia `auth.users(id)` asumiendo que cada usuario,
--   invitado o registrado, termina teniendo una sesión real de Supabase
--   Auth (con "Anonymous Sign-ins" habilitado para los invitados). Conectar
--   el `usuarioId` que hoy genera la app localmente con ese `auth.uid()` es
--   trabajo de la fase de login real/conexión, no de este esquema.

-- =========================================================
-- 1. usuarios
-- =========================================================
create table public.usuarios (
  id uuid primary key references auth.users (id) on delete cascade,
  email text unique,
  es_invitado boolean default true,
  fecha_registro timestamptz default now(),
  ultima_sincronizacion timestamptz,
  dispositivo_id text,
  escala_texto real default 1.0,
  tema text default 'sistema',
  idioma text default 'sistema'
);
-- Nota: `sesion_activa` (SQLite local) no se replica acá — es un estado
-- puramente local; la sesión "real" la maneja Supabase Auth.

alter table public.usuarios enable row level security;

create policy "usuarios: ver/editar solo su propia fila"
  on public.usuarios for all
  using (id = auth.uid())
  with check (id = auth.uid());

-- =========================================================
-- 2. mascotas
-- =========================================================
create table public.mascotas (
  id uuid primary key,
  usuario_id uuid not null references public.usuarios (id) on delete cascade,
  nombre text not null,
  rut_mascota text,
  especie text,
  especie_personalizada text,
  sexo text,
  raza text,
  esterilizado boolean default false,
  colores text,
  numero_chip text,
  fecha_nacimiento date,
  peso_actual numeric(5, 2),
  foto_url text,
  fecha_estimada boolean default false
);

alter table public.mascotas enable row level security;

create policy "mascotas: solo el dueño"
  on public.mascotas for all
  using (usuario_id = auth.uid())
  with check (usuario_id = auth.uid());

-- =========================================================
-- 3. agenda_eventos
-- =========================================================
create table public.agenda_eventos (
  id uuid primary key,
  mascota_id uuid not null references public.mascotas (id) on delete cascade,
  tipo_evento text,
  tipo_evento_personalizado text,
  titulo text not null,
  observaciones text,
  fecha_programada timestamptz not null,
  fecha_realizada timestamptz,
  recordatorio_horas_antes text
);

alter table public.agenda_eventos enable row level security;

create policy "agenda_eventos: solo el dueño de la mascota"
  on public.agenda_eventos for all
  using (mascota_id in (select id from public.mascotas where usuario_id = auth.uid()))
  with check (mascota_id in (select id from public.mascotas where usuario_id = auth.uid()));

-- =========================================================
-- 3b. medicamentos_evento
-- =========================================================
create table public.medicamentos_evento (
  id uuid primary key,
  agenda_evento_id uuid not null references public.agenda_eventos (id) on delete cascade,
  tipo_presentacion text not null,
  nombre text not null,
  observaciones text
);

alter table public.medicamentos_evento enable row level security;

create policy "medicamentos_evento: solo el dueño del evento"
  on public.medicamentos_evento for all
  using (
    agenda_evento_id in (
      select ae.id from public.agenda_eventos ae
      join public.mascotas m on m.id = ae.mascota_id
      where m.usuario_id = auth.uid()
    )
  )
  with check (
    agenda_evento_id in (
      select ae.id from public.agenda_eventos ae
      join public.mascotas m on m.id = ae.mascota_id
      where m.usuario_id = auth.uid()
    )
  );

-- =========================================================
-- 4. documentos
-- =========================================================
create table public.documentos (
  id uuid primary key,
  mascota_id uuid not null references public.mascotas (id) on delete cascade,
  evento_id uuid references public.agenda_eventos (id) on delete set null,
  titulo text not null,
  tipo_documento text not null,
  tipo_documento_personalizado text,
  file_path text not null,
  file_extension text,
  fecha_emision date,
  fecha_vencimiento date,
  recordatorio_vencimiento boolean default false,
  fecha_subida timestamptz default now(),
  notas_asociadas text,
  sincronizado_nube boolean default false
);

alter table public.documentos enable row level security;

create policy "documentos: solo el dueño de la mascota"
  on public.documentos for all
  using (mascota_id in (select id from public.mascotas where usuario_id = auth.uid()))
  with check (mascota_id in (select id from public.mascotas where usuario_id = auth.uid()));

-- =========================================================
-- 5. mascotas_extraviadas (módulo Mapa)
-- =========================================================
-- A diferencia de las tablas anteriores, acá la lectura es pública a
-- propósito: el objetivo de la feature es que CUALQUIER usuario vea los
-- reportes activos, no solo el dueño. Escritura sigue restringida al dueño.
--
-- Datos de la mascota DENORMALIZADOS (2026-08-18, ver
-- decisiones_arquitectura.md): `mascota_id` ya NO es foreign key a
-- `mascotas` — esa tabla está vacía hasta que exista sync real (Fase 6,
-- todavía pendiente), y las mascotas hoy solo viven en SQLite local. En vez
-- de una referencia, el reporte lleva copiados los datos que necesita para
-- mostrarse (nombre/especie/foto) al momento de publicar. `mascota_id`
-- queda como un uuid simple (sin FK), solo para que la app sepa localmente
-- "esta mascota ya tiene un reporte activo" — no se valida contra ninguna
-- tabla de Supabase.
--
-- Como ya no hay relación con `mascotas` para saber el dueño, el reporte
-- guarda `usuario_id` directo (referencia real a `auth.users`, mismo
-- criterio que el resto de las tablas).
--
-- `contacto_emergencia` es NOT NULL a propósito (decisión del usuario,
-- 2026-08-18): un invitado puede reportar sin cuenta, pero sin email ni
-- login, el número de contacto es la única forma de que alguien lo ubique.
--
-- `mascota_nombre` pasó de NOT NULL a opcional (2026-08-19): hay tres
-- formas de crear un reporte (ver decisiones_arquitectura.md) — mascota
-- propia registrada, mascota propia sin registrar, o "encontré una mascota
-- que no es mía" (tipo inicial 'encontrado'). En este último caso quien
-- reporta puede no saber el nombre del animal.
--
-- `estado` se separó en `tipo` + `resuelto` (2026-08-19): antes un solo
-- campo (`estado`) hacía dos trabajos distintos — "qué clase de reporte es"
-- y "sigue activo o ya se cerró" — que colisionaban con el nuevo flujo
-- "encontré una mascota": ese reporte nace con naturaleza 'encontrado' pero
-- necesita seguir ACTIVO (visible en el mapa) hasta que alguien lo reclame,
-- algo que el viejo `estado = 'encontrado'` (que significaba "resuelto")
-- no podía representar. Ahora `tipo` no cambia nunca después de creado
-- (perdí / encontré), y `resuelto` es lo único que se actualiza al cerrar
-- un reporte, sea cual sea su tipo. El mapa siempre filtra por
-- `resuelto = false`, sin importar `tipo`.
create table public.mascotas_extraviadas (
  id uuid primary key,
  usuario_id uuid not null references auth.users (id) on delete cascade,
  mascota_id uuid,
  mascota_nombre text,
  mascota_especie text,
  mascota_foto_url text,
  ubicacion_lat numeric(10, 8),
  ubicacion_lng numeric(11, 8),
  recompensa numeric(12, 2) default 0,
  tipo text not null check (tipo in ('perdido', 'encontrado')),
  resuelto boolean default false,
  contacto_emergencia text not null,
  descripcion text,
  fecha_publicacion timestamptz default now()
);

alter table public.mascotas_extraviadas enable row level security;

create policy mascotas_extraviadas_lectura_publica
  on public.mascotas_extraviadas for select
  using (true);

create policy mascotas_extraviadas_insertar_dueno
  on public.mascotas_extraviadas for insert
  with check (usuario_id = auth.uid());

create policy mascotas_extraviadas_actualizar_dueno
  on public.mascotas_extraviadas for update
  using (usuario_id = auth.uid())
  with check (usuario_id = auth.uid());

create policy mascotas_extraviadas_borrar_dueno
  on public.mascotas_extraviadas for delete
  using (usuario_id = auth.uid());

-- Límite anti-abuso: máximo 3 reportes ACTIVOS (sin resolver) por usuario
-- al mismo tiempo, sin importar el tipo (decisión del usuario, 2026-08-19).
-- Los ya resueltos (`resuelto = true`) no cuentan — no se acumulan para
-- siempre. Se aplica acá (en la base, con un trigger), no solo en la app:
-- una validación solo del lado del cliente se puede saltar llamando a la
-- API de Supabase directo, sin pasar por la app — el límite real tiene que
-- vivir donde no se puede evitar.
create or replace function public.limitar_reportes_activos()
returns trigger as $$
begin
  if (
    select count(*) from public.mascotas_extraviadas
    where usuario_id = new.usuario_id and resuelto = false
  ) >= 3 then
    raise exception 'Ya tienes el máximo de 3 reportes activos. Marca alguno como resuelto antes de crear uno nuevo.';
  end if;
  return new;
end;
$$ language plpgsql;

create trigger mascotas_extraviadas_limite_reportes
  before insert on public.mascotas_extraviadas
  for each row
  execute function public.limitar_reportes_activos();

-- Ubicación obligatoria (decisión del usuario, 2026-08-19): un reporte sin
-- ubicación no aparece en el mapa, que es el propósito central del módulo.
-- Ya validado en la app (FormularioReporteMascotaExtraviadaScreen), pero
-- se refuerza acá también — mismo criterio que el límite de reportes de
-- arriba. `not valid` para no romper si ya existen filas de prueba con
-- ubicación nula de antes de este cambio: no las valida retroactivamente,
-- solo aplica a partir de ahora. Se puede validar esas filas viejas más
-- adelante con `alter table ... validate constraint ...`, una vez
-- limpiadas o completadas a mano.
alter table public.mascotas_extraviadas
  add constraint mascotas_extraviadas_ubicacion_obligatoria
  check (ubicacion_lat is not null and ubicacion_lng is not null)
  not valid;

-- =========================================================
-- 6. denuncias_reportes (moderación manual del módulo Mapa)
-- =========================================================
-- Sin motivo de texto libre a propósito (decisión del usuario,
-- 2026-08-19): alcanza con saber "quién denunció qué reporte" — el
-- desarrollador revisa el reporte denunciado directo desde el panel de
-- Supabase (ver decisiones_arquitectura.md, "Moderación de contenido").
-- Menos fricción para quien denuncia, sin restarle utilidad a la revisión.
create table public.denuncias_reportes (
  id uuid primary key,
  reporte_id uuid not null references public.mascotas_extraviadas (id) on delete cascade,
  usuario_id uuid not null references auth.users (id) on delete cascade,
  fecha timestamptz default now(),
  unique (reporte_id, usuario_id)
);

alter table public.denuncias_reportes enable row level security;

-- Solo el desarrollador necesita LEER las denuncias (vía el panel de
-- Supabase, que no pasa por RLS) — ningún usuario de la app necesita
-- consultar esta tabla, así que no hace falta una política de "select".
create policy denuncias_reportes_crear
  on public.denuncias_reportes for insert
  with check (usuario_id = auth.uid());

-- =========================================================
-- 7. Storage: bucket fotos_reportes (fotos del módulo Mapa)
-- =========================================================
-- Foto obligatoria en el reporte (decisión del usuario, 2026-08-19) — se
-- sube acá al publicar, y `mascotas_extraviadas.mascota_foto_url` guarda
-- la URL pública resultante. `storage.objects` ya viene con RLS activado
-- por Supabase, no hace falta habilitarlo a mano.
--
-- Lectura pública (cualquiera necesita poder ver la foto en el mapa/
-- detalle del reporte, mismo criterio que la lectura pública de
-- mascotas_extraviadas). Escritura restringida a cualquier usuario
-- autenticado (incluye invitados vía Anonymous Sign-ins) — sin política de
-- update: una foto de reporte no se reemplaza sola por ahora, no hace falta
-- esa complejidad todavía.
insert into storage.buckets (id, name, public)
values ('fotos_reportes', 'fotos_reportes', true);

create policy fotos_reportes_lectura_publica
  on storage.objects for select
  using (bucket_id = 'fotos_reportes');

create policy fotos_reportes_subir_autenticado
  on storage.objects for insert
  with check (bucket_id = 'fotos_reportes' and auth.uid() is not null);

-- Borrado (2026-08-20, ver decisiones_arquitectura.md): sin esto, borrar un
-- reporte (eliminarReporte, ver mascotaExtraviada.repository.md) no podía
-- borrar de verdad su foto del bucket — RLS rechazaba el intento en
-- silencio (el borrado del reporte en sí no dependía de esto, así que pasó
-- desapercibido hasta revisarlo a mano). Restringido al dueño de la foto —
-- la ruta dentro del bucket es "usuarioId/reporteId.ext" (ver subirFoto en
-- MascotaExtraviadaRepository), así que el primer segmento de la ruta
-- (storage.foldername(name))[1] es el usuarioId; solo puede borrar quien
-- la subió.
create policy fotos_reportes_borrar_dueno
  on storage.objects for delete
  using (bucket_id = 'fotos_reportes' and (storage.foldername(name))[1] = auth.uid()::text);
