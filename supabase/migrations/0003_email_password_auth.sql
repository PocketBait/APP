-- Login con correo/usuario + contraseña (además de Google/Apple).
--
-- Dos piezas nuevas:
--   1. Campos de perfil que se piden al registrarse a mano (teléfono,
--      fecha de nacimiento — esta última también sienta la base para
--      verificar mayoría de edad en la Fase 2 de apuestas).
--   2. Una función que permite iniciar sesión con "username" en vez de
--      correo: Supabase Auth solo sabe autenticar por correo, así que
--      resolvemos username -> correo con una función security definer de
--      superficie mínima (ella sí puede leer auth.users, el cliente nunca
--      puede leer esa tabla directamente).

alter table public.profiles
  add column phone text,
  add column date_of_birth date,
  add constraint minimum_age
    check (date_of_birth is null or date_of_birth <= (current_date - interval '13 years')::date);

-- Reemplaza el trigger de creación de perfil para tomar en cuenta los
-- datos que manda el formulario de registro por correo (username propio,
-- teléfono, fecha de nacimiento), no solo lo que trae Google/Apple.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, username, display_name, avatar_url, phone, date_of_birth)
  values (
    new.id,
    coalesce(
      nullif(lower(new.raw_user_meta_data ->> 'username'), ''),
      lower(regexp_replace(coalesce(new.raw_user_meta_data ->> 'full_name', 'user_' || substr(new.id::text, 1, 8)), '[^a-z0-9_]', '', 'gi')) || '_' || substr(new.id::text, 1, 4)
    ),
    coalesce(new.raw_user_meta_data ->> 'full_name', 'Usuario'),
    new.raw_user_meta_data ->> 'avatar_url',
    new.raw_user_meta_data ->> 'phone',
    nullif(new.raw_user_meta_data ->> 'date_of_birth', '')::date
  );
  return new;
end;
$$;

-- Dado un username, devuelve el correo asociado (o null si no existe) —
-- se llama ANTES de iniciar sesión, así que tiene que poder ejecutarla
-- alguien todavía no autenticado (rol "anon").
create or replace function public.get_email_by_username(p_username text)
returns text
language sql
security definer
set search_path = public
stable
as $$
  select u.email
  from auth.users u
  join public.profiles p on p.id = u.id
  where p.username = lower(p_username)
  limit 1;
$$;

revoke all on function public.get_email_by_username(text) from public;
grant execute on function public.get_email_by_username(text) to anon, authenticated;
