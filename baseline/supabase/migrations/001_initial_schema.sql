-- ============================================================
-- BASELINE — C1: Database schema & migrations
-- Order: extensions → enums → tables → indexes → RLS → triggers → seed
-- ============================================================

-- ============================================================
-- EXTENSIONS
-- ============================================================

create extension if not exists "uuid-ossp";
create extension if not exists "pg_net";

-- ============================================================
-- ENUMS
-- ============================================================

create type day_status as enum ('in_progress', 'won', 'lost', 'skipped');
create type coach_strictness as enum ('subtle', 'standard', 'direct');
create type goal_source as enum ('user', 'coach', 'carry_forward');
create type timer_type as enum ('pomodoro', 'freeform');
create type coach_session_type as enum ('checkin', 'stuck', 'planning', 'freeform', 'insight', 'gate');
create type coach_role as enum ('user', 'assistant');
create type reflection_input_type as enum ('text', 'fast_select');
create type reflection_question_type as enum ('won', 'lost', 'universal');
create type gate_trigger_outcome as enum ('dismissed', 'timed_access', 'focus_block_active');
create type notification_type as enum (
  'checkin_reminder',
  'morning',
  'timeblock_start',
  'streak_alert',
  'reengagement',
  'coach_nudge',
  'planning_reminder'
);

-- ============================================================
-- TABLE: users
-- ============================================================

create table public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  name text,
  identity_type text,
  wake_time time not null default '07:00:00',
  checkin_time time not null default '21:00:00',
  timezone text not null default 'America/Los_Angeles',
  coach_strictness coach_strictness not null default 'standard',
  notifications_enabled boolean not null default true,
  haptics_enabled boolean not null default true,
  onboarding_complete boolean not null default false,
  pro boolean not null default false,
  gate_daily_unlock_budget integer not null default 3,
  streak_freeze_count integer not null default 1,
  streak_freeze_used_this_month integer not null default 0,
  created_at timestamptz not null default now(),
  last_active_at timestamptz not null default now()
);

comment on column public.users.pro is 'Subscription tier: pro users get unlimited coach sessions; free users are rate-limited.';

-- ============================================================
-- TABLE: user_goals
-- ============================================================

create table public.user_goals (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users (id) on delete cascade,
  category text not null,
  goal_name text not null,
  goal_detail text,
  current_status text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- ============================================================
-- TABLE: days
-- ============================================================

create table public.days (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users (id) on delete cascade,
  date date not null,
  status day_status not null default 'in_progress',
  first_hour_complete boolean not null default false,
  goals_count integer not null default 0,
  goals_completed integer not null default 0,
  focus_minutes_total integer not null default 0,
  gate_triggers integer not null default 0,
  gate_dismissals integer not null default 0,
  reflection_data jsonb,
  tomorrow_intention text,
  coach_check_in_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, date)
);

-- ============================================================
-- TABLE: goals (daily goals)
-- ============================================================

create table public.goals (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users (id) on delete cascade,
  day_id uuid not null references public.days (id) on delete cascade,
  text text not null,
  category text not null default 'work',
  status text not null default 'pending',
  priority integer default 3,
  source goal_source default 'user',
  order_index integer default 0,
  is_non_negotiable boolean not null default false,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

-- ============================================================
-- TABLE: schedule_blocks
-- ============================================================

create table public.schedule_blocks (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users (id) on delete cascade,
  name text not null,
  start_time time not null,
  end_time time not null,
  days_active integer[] not null default '{1,2,3,4,5}',
  blocked_apps text[] not null default '{}',
  custom_message text,
  color_hex text not null default '7C5CBF',
  enabled boolean not null default false,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- TABLE: gate_triggers (append-only; writes via service role)
-- ============================================================

create table public.gate_triggers (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users (id) on delete cascade,
  day_id uuid not null references public.days (id) on delete cascade,
  app_bundle_id text not null,
  app_name text not null,
  trigger_source text not null,
  trigger_count_today integer not null default 1,
  stated_reason text,
  reason_word_count integer,
  coach_response text,
  time_granted_seconds integer,
  time_used_seconds integer,
  usage_ratio double precision,
  outcome gate_trigger_outcome,
  mismatch_flagged boolean not null default false,
  active_non_negotiable text,
  streak_at_trigger integer not null default 0,
  fired_at timestamptz not null default now(),
  resolved_at timestamptz
);

-- ============================================================
-- TABLE: timers
-- ============================================================

create table public.timers (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users (id) on delete cascade,
  day_id uuid not null references public.days (id) on delete cascade,
  type timer_type not null,
  duration_minutes integer not null,
  elapsed_minutes integer not null default 0,
  linked_goal_id uuid references public.goals (id) on delete set null,
  status text not null default 'pending',
  hard_lock_active boolean not null default false,
  started_at timestamptz,
  completed_at timestamptz,
  cancelled_at timestamptz,
  cancellation_reason text,
  created_at timestamptz not null default now()
);

-- ============================================================
-- TABLE: streaks (writes via service role)
-- ============================================================

create table public.streaks (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null unique references public.users (id) on delete cascade,
  start_date date not null,
  end_date date,
  current_count integer not null default 1,
  max_count integer not null default 1,
  active boolean not null default true,
  perfect_day_count integer not null default 0,
  perfect_days_this_month integer not null default 0,
  last_updated_date date,
  created_at timestamptz not null default now()
);

-- ============================================================
-- TABLE: coach_memory_profile (writes via service role)
-- ============================================================

create table public.coach_memory_profile (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null unique references public.users (id) on delete cascade,
  identity_summary text,
  goals_summary jsonb,
  top_struggles text[],
  focus_window_best text,
  highest_risk_window text,
  gate_pattern_summary text,
  coach_notes text[],
  wins_recent text[],
  current_streak integer not null default 0,
  last_updated timestamptz not null default now()
);

-- ============================================================
-- TABLE: coach_session_journal
-- ============================================================

create table public.coach_session_journal (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users (id) on delete cascade,
  day_id uuid references public.days (id) on delete set null,
  session_type coach_session_type not null,
  summary text not null,
  emotional_tone text,
  key_facts_updated jsonb,
  compressed boolean not null default false,
  compression_summary text,
  created_at timestamptz not null default now()
);

-- ============================================================
-- TABLE: coach_messages
-- ============================================================

create table public.coach_messages (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users (id) on delete cascade,
  session_id uuid not null,
  day_id uuid references public.days (id) on delete set null,
  session_type coach_session_type not null,
  role coach_role not null,
  message text not null,
  tokens_used integer,
  model_used text,
  created_at timestamptz not null default now()
);

-- ============================================================
-- TABLE: check_ins
-- ============================================================

create table public.check_ins (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users (id) on delete cascade,
  day_id uuid not null unique references public.days (id) on delete cascade,
  non_negotiables_reviewed boolean not null default false,
  reflection_answers jsonb,
  tomorrow_intention text,
  tomorrow_timeblocks jsonb,
  gate_summary_shown boolean not null default false,
  streak_freeze_used boolean not null default false,
  submitted_at timestamptz,
  created_at timestamptz not null default now()
);

-- ============================================================
-- TABLE: time_blocks
-- ============================================================

create table public.time_blocks (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users (id) on delete cascade,
  day_id uuid not null references public.days (id) on delete cascade,
  title text not null,
  start_time time not null,
  end_time time not null,
  color_hex text not null default '7C5CBF',
  linked_goal_id uuid references public.goals (id) on delete set null,
  completed boolean not null default false,
  created_at timestamptz not null default now()
);

-- ============================================================
-- TABLE: reflection_questions (seeded; read-only for users)
-- ============================================================

create table public.reflection_questions (
  id uuid primary key default uuid_generate_v4(),
  question_text text unique not null,
  type reflection_question_type not null,
  input_type reflection_input_type not null default 'text',
  choices jsonb,
  display_order integer,
  created_at timestamptz not null default now()
);

-- ============================================================
-- TABLE: messages_to_self
-- ============================================================

create table public.messages_to_self (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users (id) on delete cascade,
  day_id uuid not null references public.days (id) on delete cascade,
  content text not null,
  photo_url text,
  scheduled_for timestamptz not null,
  delivered boolean not null default false,
  delivered_at timestamptz,
  created_at timestamptz not null default now()
);

-- ============================================================
-- TABLE: notification_tokens
-- ============================================================

create table public.notification_tokens (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users (id) on delete cascade,
  apns_token text unique not null,
  device_model text,
  os_version text,
  created_at timestamptz not null default now(),
  last_verified_at timestamptz
);

-- ============================================================
-- TABLE: first_hour_items
-- ============================================================

create table public.first_hour_items (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users (id) on delete cascade,
  text text not null,
  order_index integer default 0,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- ============================================================
-- TABLE: first_hour_completions
-- ============================================================

create table public.first_hour_completions (
  id uuid primary key default uuid_generate_v4(),
  day_id uuid not null references public.days (id) on delete cascade,
  item_id uuid not null references public.first_hour_items (id) on delete cascade,
  completed_at timestamptz not null default now(),
  unique (day_id, item_id)
);

-- ============================================================
-- TABLE: pattern_insights (writes via service role)
-- ============================================================

create table public.pattern_insights (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users (id) on delete cascade,
  insight_text text not null,
  week_start date not null,
  delivered boolean not null default false,
  created_at timestamptz not null default now()
);

-- ============================================================
-- TABLE: identity_mirror (writes via service role)
-- ============================================================

create table public.identity_mirror (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users (id) on delete cascade,
  portrait_text text not null,
  stats_summary jsonb,
  month_start date not null,
  delivered boolean not null default false,
  created_at timestamptz not null default now()
);

-- ============================================================
-- INDEXES
-- ============================================================

create index idx_days_user_date on public.days (user_id, date desc);
create index idx_days_user_status on public.days (user_id, status);

create index idx_goals_day_id on public.goals (day_id);
create index idx_goals_user_created on public.goals (user_id, created_at);

create index idx_gate_triggers_user_fired on public.gate_triggers (user_id, fired_at desc);
create index idx_gate_triggers_user_app on public.gate_triggers (user_id, app_bundle_id);

create index idx_coach_journal_user_created on public.coach_session_journal (user_id, created_at desc);
create index idx_coach_journal_user_compressed on public.coach_session_journal (user_id, compressed);

create index idx_coach_messages_session_created on public.coach_messages (session_id, created_at);

create index idx_time_blocks_day_id on public.time_blocks (day_id);

create index idx_messages_delivery_pending on public.messages_to_self (scheduled_for, delivered)
  where delivered = false;

create index idx_notification_tokens_user on public.notification_tokens (user_id);

create index idx_schedule_blocks_user_enabled on public.schedule_blocks (user_id, enabled);

create index idx_pattern_insights_user_created on public.pattern_insights (user_id, created_at desc);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table public.users enable row level security;
alter table public.user_goals enable row level security;
alter table public.days enable row level security;
alter table public.goals enable row level security;
alter table public.schedule_blocks enable row level security;
alter table public.gate_triggers enable row level security;
alter table public.timers enable row level security;
alter table public.streaks enable row level security;
alter table public.coach_memory_profile enable row level security;
alter table public.coach_session_journal enable row level security;
alter table public.coach_messages enable row level security;
alter table public.check_ins enable row level security;
alter table public.time_blocks enable row level security;
alter table public.reflection_questions enable row level security;
alter table public.messages_to_self enable row level security;
alter table public.notification_tokens enable row level security;
alter table public.first_hour_items enable row level security;
alter table public.first_hour_completions enable row level security;
alter table public.pattern_insights enable row level security;
alter table public.identity_mirror enable row level security;

-- ============================================================
-- RLS POLICIES — users
-- ============================================================

create policy "users_select_own" on public.users for select using (auth.uid() = id);

create policy "users_update_own" on public.users for update using (auth.uid() = id);

-- ============================================================
-- RLS POLICIES — user_goals
-- ============================================================

create policy "user_goals_select_own" on public.user_goals for select using (auth.uid() = user_id);

create policy "user_goals_insert_own" on public.user_goals for insert with check (auth.uid() = user_id);

create policy "user_goals_update_own" on public.user_goals for update using (auth.uid() = user_id);

create policy "user_goals_delete_own" on public.user_goals for delete using (auth.uid() = user_id);

-- ============================================================
-- RLS POLICIES — days
-- ============================================================

create policy "days_select_own" on public.days for select using (auth.uid() = user_id);

create policy "days_insert_own" on public.days for insert with check (auth.uid() = user_id);

create policy "days_update_own" on public.days for update using (auth.uid() = user_id);

create policy "days_delete_own" on public.days for delete using (auth.uid() = user_id);

-- ============================================================
-- RLS POLICIES — goals
-- ============================================================

create policy "goals_select_own" on public.goals for select using (auth.uid() = user_id);

create policy "goals_insert_own" on public.goals for insert with check (auth.uid() = user_id);

create policy "goals_update_own" on public.goals for update using (auth.uid() = user_id);

create policy "goals_delete_own" on public.goals for delete using (auth.uid() = user_id);

-- ============================================================
-- RLS POLICIES — schedule_blocks
-- ============================================================

create policy "schedule_blocks_select_own" on public.schedule_blocks for select using (auth.uid() = user_id);

create policy "schedule_blocks_insert_own" on public.schedule_blocks for insert with check (auth.uid() = user_id);

create policy "schedule_blocks_update_own" on public.schedule_blocks for update using (auth.uid() = user_id);

create policy "schedule_blocks_delete_own" on public.schedule_blocks for delete using (auth.uid() = user_id);

-- ============================================================
-- RLS POLICIES — gate_triggers (SELECT only)
-- ============================================================

create policy "gate_triggers_select_own" on public.gate_triggers for select using (auth.uid() = user_id);

-- ============================================================
-- RLS POLICIES — timers
-- ============================================================

create policy "timers_select_own" on public.timers for select using (auth.uid() = user_id);

create policy "timers_insert_own" on public.timers for insert with check (auth.uid() = user_id);

create policy "timers_update_own" on public.timers for update using (auth.uid() = user_id);

create policy "timers_delete_own" on public.timers for delete using (auth.uid() = user_id);

-- ============================================================
-- RLS POLICIES — streaks (SELECT only)
-- ============================================================

create policy "streaks_select_own" on public.streaks for select using (auth.uid() = user_id);

-- ============================================================
-- RLS POLICIES — coach_memory_profile (SELECT only)
-- ============================================================

create policy "coach_memory_profile_select_own" on public.coach_memory_profile for select using (auth.uid() = user_id);

-- ============================================================
-- RLS POLICIES — coach_session_journal (SELECT + INSERT)
-- ============================================================

create policy "coach_journal_select_own" on public.coach_session_journal for select using (auth.uid() = user_id);

create policy "coach_journal_insert_own" on public.coach_session_journal for insert with check (auth.uid() = user_id);

-- ============================================================
-- RLS POLICIES — coach_messages
-- ============================================================

create policy "coach_messages_select_own" on public.coach_messages for select using (auth.uid() = user_id);

create policy "coach_messages_insert_own" on public.coach_messages for insert with check (auth.uid() = user_id);

create policy "coach_messages_update_own" on public.coach_messages for update using (auth.uid() = user_id);

create policy "coach_messages_delete_own" on public.coach_messages for delete using (auth.uid() = user_id);

-- ============================================================
-- RLS POLICIES — check_ins
-- ============================================================

create policy "check_ins_select_own" on public.check_ins for select using (auth.uid() = user_id);

create policy "check_ins_insert_own" on public.check_ins for insert with check (auth.uid() = user_id);

create policy "check_ins_update_own" on public.check_ins for update using (auth.uid() = user_id);

create policy "check_ins_delete_own" on public.check_ins for delete using (auth.uid() = user_id);

-- ============================================================
-- RLS POLICIES — time_blocks
-- ============================================================

create policy "time_blocks_select_own" on public.time_blocks for select using (auth.uid() = user_id);

create policy "time_blocks_insert_own" on public.time_blocks for insert with check (auth.uid() = user_id);

create policy "time_blocks_update_own" on public.time_blocks for update using (auth.uid() = user_id);

create policy "time_blocks_delete_own" on public.time_blocks for delete using (auth.uid() = user_id);

-- ============================================================
-- RLS POLICIES — reflection_questions (public read)
-- ============================================================

create policy "reflection_questions_public_read" on public.reflection_questions for select using (true);

-- ============================================================
-- RLS POLICIES — messages_to_self
-- ============================================================

create policy "messages_to_self_select_own" on public.messages_to_self for select using (auth.uid() = user_id);

create policy "messages_to_self_insert_own" on public.messages_to_self for insert with check (auth.uid() = user_id);

create policy "messages_to_self_update_own" on public.messages_to_self for update using (auth.uid() = user_id);

create policy "messages_to_self_delete_own" on public.messages_to_self for delete using (auth.uid() = user_id);

-- ============================================================
-- RLS POLICIES — notification_tokens
-- ============================================================

create policy "notification_tokens_select_own" on public.notification_tokens for select using (auth.uid() = user_id);

create policy "notification_tokens_insert_own" on public.notification_tokens for insert with check (auth.uid() = user_id);

create policy "notification_tokens_update_own" on public.notification_tokens for update using (auth.uid() = user_id);

create policy "notification_tokens_delete_own" on public.notification_tokens for delete using (auth.uid() = user_id);

-- ============================================================
-- RLS POLICIES — first_hour_items
-- ============================================================

create policy "first_hour_items_select_own" on public.first_hour_items for select using (auth.uid() = user_id);

create policy "first_hour_items_insert_own" on public.first_hour_items for insert with check (auth.uid() = user_id);

create policy "first_hour_items_update_own" on public.first_hour_items for update using (auth.uid() = user_id);

create policy "first_hour_items_delete_own" on public.first_hour_items for delete using (auth.uid() = user_id);

-- ============================================================
-- RLS POLICIES — first_hour_completions (via day ownership)
-- ============================================================

create policy "first_hour_completions_select_own" on public.first_hour_completions for select
  using (exists (select 1 from public.days d where d.id = day_id and d.user_id = auth.uid()));

create policy "first_hour_completions_insert_own" on public.first_hour_completions for insert
  with check (exists (select 1 from public.days d where d.id = day_id and d.user_id = auth.uid()));

create policy "first_hour_completions_delete_own" on public.first_hour_completions for delete
  using (exists (select 1 from public.days d where d.id = day_id and d.user_id = auth.uid()));

-- ============================================================
-- RLS POLICIES — pattern_insights (SELECT only)
-- ============================================================

create policy "pattern_insights_select_own" on public.pattern_insights for select using (auth.uid() = user_id);

-- ============================================================
-- RLS POLICIES — identity_mirror (SELECT only)
-- ============================================================

create policy "identity_mirror_select_own" on public.identity_mirror for select using (auth.uid() = user_id);

-- ============================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, name)
  values (new.id, new.raw_user_meta_data->>'name')
  on conflict (id) do nothing;

  insert into public.streaks (user_id, start_date)
  values (new.id, current_date)
  on conflict (user_id) do nothing;

  insert into public.coach_memory_profile (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.update_day_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger days_set_updated_at
  before update on public.days
  for each row execute function public.update_day_updated_at();

create or replace function public.recalculate_day_goal_counts()
returns trigger
language plpgsql
as $$
declare
  day_ids uuid[];
  d_id uuid;
begin
  if tg_op = 'DELETE' then
    day_ids := array[old.day_id];
  elsif tg_op = 'UPDATE' and old.day_id is distinct from new.day_id then
    day_ids := array[old.day_id, new.day_id];
  else
    day_ids := array[coalesce(new.day_id, old.day_id)];
  end if;

  for d_id in
    select distinct x from unnest(day_ids) as t(x) where x is not null
  loop
    update public.days d
    set
      goals_count = (select count(*)::int from public.goals g where g.day_id = d.id),
      goals_completed = (
        select count(*)::int from public.goals g where g.day_id = d.id and g.status = 'completed'
      )
    where d.id = d_id;
  end loop;

  return coalesce(new, old);
end;
$$;

create trigger goals_recalc_counts
  after insert or update or delete on public.goals
  for each row execute function public.recalculate_day_goal_counts();

create or replace function public.add_completed_focus_minutes()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'completed' and old.status is distinct from 'completed' then
    update public.days
    set focus_minutes_total = focus_minutes_total + coalesce(new.elapsed_minutes, 0)
    where id = new.day_id;
  end if;
  return new;
end;
$$;

create trigger timers_add_focus_minutes
  after update on public.timers
  for each row execute function public.add_completed_focus_minutes();

-- ============================================================
-- SEED: reflection_questions
-- ============================================================

insert into public.reflection_questions (question_text, type, input_type, choices, display_order)
values
  (
    'Did you doomscroll today?',
    'universal',
    'fast_select',
    '["Not really", "A little", "Yes, quite a bit", "It took over"]'::jsonb,
    1
  ),
  (
    'What distracted you most today?',
    'universal',
    'text',
    null,
    2
  ),
  (
    'What made today easier or harder than expected?',
    'universal',
    'text',
    null,
    3
  ),
  (
    'What helped you win today?',
    'won',
    'text',
    null,
    1
  ),
  (
    'What would make tomorrow even cleaner?',
    'won',
    'text',
    null,
    2
  ),
  (
    'What got in the way?',
    'lost',
    'fast_select',
    '["Doomscrolling", "Low energy", "Avoidance", "External interruptions", "Goals were too big"]'::jsonb,
    1
  ),
  (
    'Were you avoidant today?',
    'lost',
    'fast_select',
    '["No", "Somewhat", "Yes"]'::jsonb,
    2
  ),
  (
    'What should change tomorrow?',
    'lost',
    'text',
    null,
    3
  );
