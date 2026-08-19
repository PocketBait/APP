-- Settings de cuenta: preferencias, seguridad, privacidad de datos.
--
-- Incluye una corrección importante: `phone` y `date_of_birth` (de la
-- migración 0003) heredaron el policy amplio de SELECT de `profiles`
-- ("cualquiera autenticado puede leer"), pensado solo para username/
-- display_name/avatar_url. Eso dejaba el teléfono y fecha de nacimiento
-- de cualquier usuario visibles para cualquier otro. Se corrige acá
-- restringiendo qué columnas son de lectura pública.

-- =========================================================================
-- 1. Restringir columnas públicas de profiles
-- =========================================================================
revoke select on public.profiles from authenticated;

grant select (id, username, display_name, avatar_url, created_at, updated_at)
  on public.profiles to authenticated;

-- El dueño de la fila lee TODOS sus propios campos (incluido phone y
-- date_of_birth) por esta función — el acceso normal a la tabla se queda
-- limitado a las columnas públicas de arriba, para todos.
create or replace function public.get_my_profile()
returns public.profiles
language sql
security definer
set search_path = public
stable
as $$
  select * from public.profiles where id = auth.uid();
$$;

grant execute on function public.get_my_profile() to authenticated;

-- =========================================================================
-- 2. Eliminar mi cuenta — borra auth.users, y todo lo demás cae en
--    cascada (profiles, friend_requests, permission_grants,
--    limit_proposals, limit_proposal_apps, blocks, reports).
--    security definer porque un usuario normal no tiene permiso de
--    tocar auth.users directamente.
-- =========================================================================
create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from auth.users where id = auth.uid();
end;
$$;

grant execute on function public.delete_own_account() to authenticated;
