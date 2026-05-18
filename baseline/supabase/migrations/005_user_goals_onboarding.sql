-- Onboarding / outcome-level fields for user_goals (idempotent adds).

do $$
begin
  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'user_goals'
      and column_name = 'long_term_goal'
  ) then
    alter table public.user_goals add column long_term_goal text;
    update public.user_goals
    set long_term_goal = coalesce(goal_name, '')
    where long_term_goal is null;
    alter table public.user_goals alter column long_term_goal set not null;
  end if;
end $$;

alter table public.user_goals add column if not exists target_date date;

alter table public.user_goals add column if not exists daily_action_suggestion text;

alter table public.user_goals add column if not exists order_index integer not null default 0;

comment on column public.user_goals.long_term_goal is 'Outcome-level ambition in the user''s own words.';
comment on column public.user_goals.target_date is 'Optional target completion date.';
comment on column public.user_goals.daily_action_suggestion is 'Coach-generated small daily action; populated by edge function.';
comment on column public.user_goals.order_index is 'Display order among active goals for the user.';
