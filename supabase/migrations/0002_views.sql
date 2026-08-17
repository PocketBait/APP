-- Vistas de conveniencia. security_invoker = on es importante: hace que la
-- vista respete el RLS del usuario que consulta, no el del dueño de la
-- vista — sin esto, una vista podría filtrar datos saltándose RLS.

create view public.active_limits
with (security_invoker = on)
as
select
  lp.id,
  lp.owner_id,
  lp.proposed_by,
  lp.starts_at,
  lp.ends_at,
  lp.note,
  lpa.app_identifier,
  lpa.app_display_name,
  lpa.daily_limit_minutes
from public.limit_proposals lp
join public.limit_proposal_apps lpa on lpa.proposal_id = lp.id
where lp.status = 'accepted'
  and lp.ends_at > now();

create view public.pending_incoming_proposals
with (security_invoker = on)
as
select lp.*
from public.limit_proposals lp
where lp.status = 'pending';
