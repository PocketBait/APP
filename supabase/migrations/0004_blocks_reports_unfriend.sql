-- Dejar de ser amigos, bloquear, reportar, y "amigos en común" en la
-- búsqueda de gente nueva.

-- =========================================================================
-- 1. blocks — quien bloquea deja de poder recibir solicitudes/propuestas
--    de la persona bloqueada, y viceversa.
-- =========================================================================
create table public.blocks (
  id         uuid primary key default gen_random_uuid(),
  blocker_id uuid not null references public.profiles (id) on delete cascade,
  blocked_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint no_self_block check (blocker_id <> blocked_id),
  unique (blocker_id, blocked_id)
);

alter table public.blocks enable row level security;

create policy "blocks: veo los que yo hice"
  on public.blocks for select
  to authenticated
  using (blocker_id = (select auth.uid()));

create policy "blocks: solo puedo bloquear a nombre mío"
  on public.blocks for insert
  to authenticated
  with check (blocker_id = (select auth.uid()));

create policy "blocks: solo puedo desbloquear lo que yo bloqueé"
  on public.blocks for delete
  to authenticated
  using (blocker_id = (select auth.uid()));

-- =========================================================================
-- 2. reports — reportar a otro usuario (requisito de Apple/Google para
--    apps donde los usuarios interactúan entre sí). Solo el que reporta
--    puede ver/crear su propio reporte; la revisión la hace un admin
--    directo en la base (no expuesto a la app).
-- =========================================================================
create table public.reports (
  id          uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  reported_id uuid not null references public.profiles (id) on delete cascade,
  reason      text not null,
  details     text,
  status      text not null default 'pending' check (status in ('pending', 'reviewed')),
  created_at  timestamptz not null default now(),
  constraint no_self_report check (reporter_id <> reported_id)
);

alter table public.reports enable row level security;

create policy "reports: veo los que yo hice"
  on public.reports for select
  to authenticated
  using (reporter_id = (select auth.uid()));

create policy "reports: solo puedo reportar a nombre mío"
  on public.reports for insert
  to authenticated
  with check (reporter_id = (select auth.uid()));

-- =========================================================================
-- 3. Dejar de ser amigos: permitir borrar la fila de friend_requests.
-- =========================================================================
create policy "friend_requests: cualquiera de los dos puede terminar la relación"
  on public.friend_requests for delete
  to authenticated
  using (requester_id = (select auth.uid()) or addressee_id = (select auth.uid()));

-- Si la amistad que se borra estaba aceptada, revoca cualquier acceso
-- activo entre esas dos personas — dejar de ser amigos también le quita
-- a un amigo el poder seguir proponiéndote límites.
create or replace function public.handle_friend_request_deleted()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.status = 'accepted' then
    update public.permission_grants
    set status = 'revoked', revoked_at = now()
    where status = 'active'
      and (
        (owner_id = old.requester_id and trustee_id = old.addressee_id) or
        (owner_id = old.addressee_id and trustee_id = old.requester_id)
      );
  end if;
  return old;
end;
$$;

create trigger on_friend_request_deleted
  after delete on public.friend_requests
  for each row execute function public.handle_friend_request_deleted();

-- =========================================================================
-- 4. No dejar mandar solicitudes ni accesos si hay un bloqueo de por medio
--    (reemplaza las policies de insert de 0001 para agregar esta regla).
-- =========================================================================
drop policy "friend_requests: solo puedo enviar solicitudes a mi nombre" on public.friend_requests;

create policy "friend_requests: enviar solicitud a mi nombre, sin bloqueo de por medio"
  on public.friend_requests for insert
  to authenticated
  with check (
    requester_id = (select auth.uid())
    and not exists (
      select 1 from public.blocks b
      where (b.blocker_id = requester_id and b.blocked_id = addressee_id)
         or (b.blocker_id = addressee_id and b.blocked_id = requester_id)
    )
  );

drop policy "permission_grants: solo el dueño otorga acceso, y solo a un amigo" on public.permission_grants;

create policy "permission_grants: otorgar acceso a un amigo, sin bloqueo de por medio"
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
    and not exists (
      select 1 from public.blocks b
      where (b.blocker_id = owner_id and b.blocked_id = trustee_id)
         or (b.blocker_id = trustee_id and b.blocked_id = owner_id)
    )
  );

-- =========================================================================
-- 5. Amigos en común: helper reutilizable + búsqueda + conteo aislado.
-- =========================================================================

-- IDs de los amigos aceptados de un usuario.
create or replace function public.friend_ids(p_user_id uuid)
returns table (friend_id uuid)
language sql
security definer
set search_path = public
stable
as $$
  select case when requester_id = p_user_id then addressee_id else requester_id end as friend_id
  from public.friend_requests
  where status = 'accepted'
    and (requester_id = p_user_id or addressee_id = p_user_id);
$$;

grant execute on function public.friend_ids(uuid) to authenticated;

-- Cuántos amigos en común tengo con otro usuario (para mostrar en su perfil).
create or replace function public.mutual_friends_count(p_other_id uuid)
returns bigint
language sql
security definer
set search_path = public
stable
as $$
  select count(*)
  from public.friend_ids(auth.uid()) mine
  join public.friend_ids(p_other_id) theirs on mine.friend_id = theirs.friend_id;
$$;

grant execute on function public.mutual_friends_count(uuid) to authenticated;

-- Búsqueda de gente nueva: excluye a quien te bloqueó o bloqueaste, y
-- ordena a quienes tienen más amigos en común contigo primero.
create or replace function public.search_profiles(p_query text)
returns table (
  id uuid,
  username text,
  display_name text,
  avatar_url text,
  mutual_friends_count bigint
)
language sql
security definer
set search_path = public
stable
as $$
  select
    p.id,
    p.username,
    p.display_name,
    p.avatar_url,
    (
      select count(*)
      from public.friend_ids(auth.uid()) mine
      join public.friend_ids(p.id) theirs on mine.friend_id = theirs.friend_id
    ) as mutual_friends_count
  from public.profiles p
  where p.id <> auth.uid()
    and (p.username ilike '%' || p_query || '%' or p.display_name ilike '%' || p_query || '%')
    and not exists (
      select 1 from public.blocks b
      where (b.blocker_id = auth.uid() and b.blocked_id = p.id)
         or (b.blocker_id = p.id and b.blocked_id = auth.uid())
    )
  order by mutual_friends_count desc, p.display_name asc
  limit 20;
$$;

grant execute on function public.search_profiles(text) to authenticated;
