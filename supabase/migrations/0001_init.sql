-- PocketBait — esquema inicial (Fase 1: sin dinero)
--
-- Diseño de seguridad:
--   * Toda tabla tiene Row Level Security (RLS) activada: Postgres rechaza
--     cualquier fila que no cumpla la política, sin importar si el bug está
--     en la app, en un endpoint nuevo o en una query hecha a mano. La
--     seguridad vive en la base de datos, no solo en el cliente Flutter.
--   * auth.uid() lo provee Supabase Auth a partir del JWT de la sesión —
--     no es un valor que el cliente pueda falsificar.
--   * "Dar acceso a un amigo para que proponga límites" y "aceptar/rechazar
--     una propuesta" son las dos acciones sensibles del producto: están
--     modeladas explícitamente como filas con estado, nunca como algo que
--     un usuario pueda forzar directamente sobre el teléfono de otro.

-- =========================================================================
-- 1. profiles — datos públicos del usuario, 1:1 con auth.users
-- =========================================================================
create table public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  username     text not null unique,
  display_name text not null,
  avatar_url   text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  constraint username_format check (username ~ '^[a-z0-9_]{3,20}$')
);

alter table public.profiles enable row level security;

-- Cualquier usuario autenticado puede ver perfiles públicos (para poder
-- buscar y agregar amigos por username). No se exponen aquí datos
-- sensibles (correo, tokens, etc.) — esos quedan solo en auth.users.
create policy "profiles: cualquiera autenticado puede leer"
  on public.profiles for select
  to authenticated
  using (true);

create policy "profiles: solo puedo crear mi propio perfil"
  on public.profiles for insert
  to authenticated
  with check (id = (select auth.uid()));

create policy "profiles: solo puedo editar mi propio perfil"
  on public.profiles for update
  to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- Crea el perfil automáticamente cuando alguien se registra (Google/Apple),
-- usando lo que venga en el metadata del proveedor.
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, username, display_name, avatar_url)
  values (
    new.id,
    lower(regexp_replace(coalesce(new.raw_user_meta_data ->> 'full_name', 'user_' || substr(new.id::text, 1, 8)), '[^a-z0-9_]', '', 'gi')) || '_' || substr(new.id::text, 1, 4),
    coalesce(new.raw_user_meta_data ->> 'full_name', 'Usuario'),
    new.raw_user_meta_data ->> 'avatar_url'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- =========================================================================
-- 2. friend_requests — solicitud de amistad; una vez aceptada, ES la
--    relación de amistad (no hay tabla separada "friendships").
-- =========================================================================
create table public.friend_requests (
  id            uuid primary key default gen_random_uuid(),
  requester_id  uuid not null references public.profiles (id) on delete cascade,
  addressee_id  uuid not null references public.profiles (id) on delete cascade,
  status        text not null default 'pending'
                  check (status in ('pending', 'accepted', 'declined', 'cancelled')),
  created_at    timestamptz not null default now(),
  responded_at  timestamptz,
  constraint no_self_friend_request check (requester_id <> addressee_id)
);

-- Evita pares duplicados en cualquier dirección mientras haya una solicitud
-- pendiente o ya aceptada entre las mismas dos personas.
create unique index friend_requests_unique_active_pair
  on public.friend_requests (least(requester_id, addressee_id), greatest(requester_id, addressee_id))
  where status in ('pending', 'accepted');

create index friend_requests_addressee_idx on public.friend_requests (addressee_id, status);
create index friend_requests_requester_idx on public.friend_requests (requester_id, status);

alter table public.friend_requests enable row level security;

create policy "friend_requests: veo las mías (enviadas o recibidas)"
  on public.friend_requests for select
  to authenticated
  using (requester_id = (select auth.uid()) or addressee_id = (select auth.uid()));

create policy "friend_requests: solo puedo enviar solicitudes a mi nombre"
  on public.friend_requests for insert
  to authenticated
  with check (requester_id = (select auth.uid()));

create policy "friend_requests: aceptar/rechazar (destinatario) o cancelar (quien la envió)"
  on public.friend_requests for update
  to authenticated
  using (requester_id = (select auth.uid()) or addressee_id = (select auth.uid()))
  with check (requester_id = (select auth.uid()) or addressee_id = (select auth.uid()));

-- =========================================================================
-- 3. permission_grants — "le doy acceso a un amigo para que me proponga
--    límites de tiempo". Sin esta fila en estado 'active', nadie puede
--    crear una propuesta contra ti (ver policy de limit_proposals).
-- =========================================================================
create table public.permission_grants (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid not null references public.profiles (id) on delete cascade,
  trustee_id  uuid not null references public.profiles (id) on delete cascade,
  status      text not null default 'active' check (status in ('active', 'revoked')),
  created_at  timestamptz not null default now(),
  revoked_at  timestamptz,
  constraint no_self_grant check (owner_id <> trustee_id)
);

create unique index permission_grants_unique_active_pair
  on public.permission_grants (owner_id, trustee_id)
  where status = 'active';

alter table public.permission_grants enable row level security;

create policy "permission_grants: veo los míos (como dueño o como amigo autorizado)"
  on public.permission_grants for select
  to authenticated
  using (owner_id = (select auth.uid()) or trustee_id = (select auth.uid()));

-- Solo el dueño del teléfono puede otorgar acceso, y solo a alguien que ya
-- es su amigo aceptado — así no se le puede dar acceso "por accidente" a
-- un desconocido.
create policy "permission_grants: solo el dueño otorga acceso, y solo a un amigo"
  on public.permission_grants for insert
  to authenticated
  with check (
    owner_id = (select auth.uid())
    and exists (
      select 1 from public.friend_requests fr
      where fr.status = 'accepted'
        and (
          (fr.requester_id = owner_id and fr.addressee_id = trustee_id) or
          (fr.addressee_id = owner_id and fr.requester_id = trustee_id)
        )
    )
  );

-- El dueño puede revocar el acceso en cualquier momento; el amigo autorizado
-- también puede renunciar a él.
create policy "permission_grants: revocar (dueño) o renunciar (amigo autorizado)"
  on public.permission_grants for update
  to authenticated
  using (owner_id = (select auth.uid()) or trustee_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()) or trustee_id = (select auth.uid()));

-- =========================================================================
-- 4. limit_proposals — el "borrador" de límites que un amigo autorizado
--    propone; solo aplica de verdad si owner_id lo acepta.
-- =========================================================================
create table public.limit_proposals (
  id                  uuid primary key default gen_random_uuid(),
  permission_grant_id uuid not null references public.permission_grants (id) on delete cascade,
  owner_id            uuid not null references public.profiles (id) on delete cascade,
  proposed_by         uuid not null references public.profiles (id) on delete cascade,
  status              text not null default 'pending'
                        check (status in ('pending', 'accepted', 'rejected', 'cancelled')),
  starts_at           timestamptz,
  ends_at             timestamptz not null,
  note                text,
  created_at          timestamptz not null default now(),
  responded_at        timestamptz,
  constraint no_self_proposal check (owner_id <> proposed_by),
  constraint valid_window check (ends_at > created_at)
);

create index limit_proposals_owner_idx on public.limit_proposals (owner_id, status);
create index limit_proposals_proposer_idx on public.limit_proposals (proposed_by, status);

alter table public.limit_proposals enable row level security;

create policy "limit_proposals: veo las mías (recibidas o que yo propuse)"
  on public.limit_proposals for select
  to authenticated
  using (owner_id = (select auth.uid()) or proposed_by = (select auth.uid()));

-- Solo se puede crear una propuesta si existe un permission_grant ACTIVO
-- donde yo (auth.uid()) soy el trustee autorizado por ese owner_id. Esta es
-- la regla que impide que "cualquiera te ponga límites" — sin permiso
-- activo, el INSERT es rechazado por Postgres, no solo escondido en la UI.
create policy "limit_proposals: solo con permiso activo del dueño"
  on public.limit_proposals for insert
  to authenticated
  with check (
    proposed_by = (select auth.uid())
    and exists (
      select 1 from public.permission_grants pg
      where pg.id = permission_grant_id
        and pg.status = 'active'
        and pg.owner_id = limit_proposals.owner_id
        and pg.trustee_id = (select auth.uid())
    )
  );

create policy "limit_proposals: aceptar/rechazar (dueño) o cancelar (quien propuso)"
  on public.limit_proposals for update
  to authenticated
  using (owner_id = (select auth.uid()) or proposed_by = (select auth.uid()))
  with check (owner_id = (select auth.uid()) or proposed_by = (select auth.uid()));

-- =========================================================================
-- 5. limit_proposal_apps — apps + minutos diarios dentro de una propuesta
-- =========================================================================
create table public.limit_proposal_apps (
  id                uuid primary key default gen_random_uuid(),
  proposal_id       uuid not null references public.limit_proposals (id) on delete cascade,
  -- Identificador nativo: bundle id en iOS (com.instagram.app) o
  -- package name en Android (com.instagram.android).
  app_identifier    text not null,
  app_display_name  text not null,
  daily_limit_minutes integer not null check (daily_limit_minutes > 0 and daily_limit_minutes <= 1440)
);

create index limit_proposal_apps_proposal_idx on public.limit_proposal_apps (proposal_id);

alter table public.limit_proposal_apps enable row level security;

create policy "limit_proposal_apps: veo las apps de propuestas que puedo ver"
  on public.limit_proposal_apps for select
  to authenticated
  using (
    exists (
      select 1 from public.limit_proposals lp
      where lp.id = proposal_id
        and (lp.owner_id = (select auth.uid()) or lp.proposed_by = (select auth.uid()))
    )
  );

-- Solo quien propuso el límite puede agregar apps a SU PROPIA propuesta
-- pendiente (no se puede editar después de aceptada/rechazada).
create policy "limit_proposal_apps: solo el proponente, en su propuesta pendiente"
  on public.limit_proposal_apps for insert
  to authenticated
  with check (
    exists (
      select 1 from public.limit_proposals lp
      where lp.id = proposal_id
        and lp.proposed_by = (select auth.uid())
        and lp.status = 'pending'
    )
  );

-- =========================================================================
-- Trigger genérico para mantener updated_at al día
-- =========================================================================
create function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();
