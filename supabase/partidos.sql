-- ─────────────────────────────────────────────────────────────────
-- Feature Partidos / Cartas — tablas Supabase
-- Ejecutar en el SQL Editor de Supabase.
-- Los nombres de columna en camelCase van entre comillas dobles porque
-- deben coincidir EXACTO con las claves de toJson() de los modelos Dart.
-- ─────────────────────────────────────────────────────────────────

-- Tabla de partidos
create table if not exists public.partidos (
  id           text primary key,
  titulo       text        not null default '',
  "dateTime"   text        not null,           -- ISO8601 (igual que juntadas)
  tipo         text        not null default 'f5',
  "golesFavor" integer,
  "golesContra" integer,
  roster       jsonb       not null default '[]'::jsonb,
  cerrado      boolean     not null default false,
  "creatorId"  text        not null default ''
);

-- Tabla de calificaciones (1 fila = 1 votante califica a 1 compañero)
create table if not exists public.calificaciones (
  id          text primary key,
  "partidoId" text    not null references public.partidos(id) on delete cascade,
  "voterId"   text    not null,   -- oculto en la UI (anónimo)
  "targetId"  text    not null,
  pac integer not null,
  sho integer not null,
  pas integer not null,
  dri integer not null,
  def integer not null,
  phy integer not null
);

create index if not exists calificaciones_partido_idx
  on public.calificaciones ("partidoId");

-- ── Realtime (para los .stream() de la app) ──
alter publication supabase_realtime add table public.partidos;
alter publication supabase_realtime add table public.calificaciones;

-- ── RLS: políticas permisivas (grupo cerrado, sin auth) ──
alter table public.partidos       enable row level security;
alter table public.calificaciones enable row level security;

create policy "partidos_all"       on public.partidos
  for all using (true) with check (true);
create policy "calificaciones_all" on public.calificaciones
  for all using (true) with check (true);
