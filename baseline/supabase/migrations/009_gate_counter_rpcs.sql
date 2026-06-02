-- Atomic counters for per-day gate tallies. The edge functions previously did a
-- read-modify-write (read days.gate_triggers / gate_dismissals, then write +1),
-- which loses updates under concurrent gate validations/resolutions. These functions
-- increment in a single statement and return the new authoritative value.

create or replace function public.increment_gate_triggers(p_day_id uuid, p_user_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  new_count integer;
begin
  update public.days
     set gate_triggers = coalesce(gate_triggers, 0) + 1
   where id = p_day_id and user_id = p_user_id
  returning gate_triggers into new_count;
  return new_count;
end;
$$;

create or replace function public.increment_gate_dismissals(p_day_id uuid, p_user_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  new_count integer;
begin
  update public.days
     set gate_dismissals = coalesce(gate_dismissals, 0) + 1
   where id = p_day_id and user_id = p_user_id
  returning gate_dismissals into new_count;
  return new_count;
end;
$$;

grant execute on function public.increment_gate_triggers(uuid, uuid) to authenticated, service_role;
grant execute on function public.increment_gate_dismissals(uuid, uuid) to authenticated, service_role;
