-- Prevent duplicate weekly/monthly insights. Two concurrent generate-* calls both
-- passed the "does a row already exist?" check and inserted a second (expensively
-- generated) row. Add uniqueness so the loser collides (23505) and can return the
-- winner's row instead. Dedupe any pre-existing duplicates first (keep the earliest).

delete from public.pattern_insights p
where p.id not in (
  select distinct on (user_id, week_start) id
  from public.pattern_insights
  order by user_id, week_start, created_at asc
);

delete from public.identity_mirror m
where m.id not in (
  select distinct on (user_id, month_start) id
  from public.identity_mirror
  order by user_id, month_start, created_at asc
);

create unique index if not exists pattern_insights_user_week_uidx
  on public.pattern_insights (user_id, week_start);

create unique index if not exists identity_mirror_user_month_uidx
  on public.identity_mirror (user_id, month_start);
