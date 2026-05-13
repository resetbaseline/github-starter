-- ============================================================
-- BASELINE — C1: Database Schema & Migrations
-- File: 001_initial_schema.sql
-- Run this entire file in Supabase SQL Editor in one shot.
-- Order: extensions → enums → tables → indexes → RLS → triggers → seed
--
-- Notes (this revision):
-- - message_delivery_status is used on messages_to_self.delivery_status.
-- - RLS WITH CHECK / USING ties day_id (and coach day_id when set) to auth user.
-- - notification_tokens: client may UPDATE last_verified_at (policy added).
-- - pg_net: not required by this schema; enable in Dashboard → Extensions if you add HTTP-from-SQL later.
-- ============================================================


-- ============================================================
-- EXTENSIONS
-- ============================================================

create extension if not exists "uuid-ossp";


-- ============================================================
-- ENUMS
-- ============================================================

create type day_status           as enum ('in_progress', 'won', 'lost', 'skipped');
create type coach_strictness     as enum ('subtle', 'standard', 'direct');
create type goal_source          as enum ('user', 'coach', 'carry_forward');
create type timer_type           as enum ('pomodoro', 'freeform');
create type coach_context_type   as enum ('checkin', 'stuck', 'planning', 'freeform', 'insight');
create type coach_role           as enum ('user', 'assistant');
create type stuck_situation      as enum ('cant_start', 'overwhelmed', 'scrolling');
create type reflection_input_type   as enum ('text', 'fast_select');
create type reflection_question_type as enum ('won', 'lost', 'universal');
create type message_delivery_status as enum ('pending', 'delivered');


-- ============================================================
-- TABLE: users
-- Extended profile. One row per auth.users entry.
-- Created automatically via handle_new_user trigger on signup.
-- ============================================================

create table public.users (
  id                    uuid        primary key references auth.users(id) on delete cascade,
  name                  text,
  wake_time             time        not null default '07:00:00',
  checkin_time          time        not null default '21:00:00',
  timezone              text        not null default 'America/Los_Angeles',
  coach_strictness      coach_strictness not null default 'standard',
  notifications_enabled boolean     not null default true,
  haptics_enabled       boolean     not null default true,
  onboarding_complete   boolean     not null default false,
  apns_token            text,
  created_at            timestamptz not null default now(),
  last_active_at        timestamptz not null default now()
);

comment on table  public.users is 'Extended user profile. One record per auth.users row.';
comment on column public.users.timezone is 'IANA timezone string e.g. America/Los_Angeles. Set from device on first launch.';
comment on column public.users.apns_token is 'Deprecated — use notification_tokens table for multi-device support.';


-- ============================================================
-- TABLE: days
-- One row per user per calendar date. Core unit of Baseline.
-- ============================================================

create table public.days (
  id                    uuid        primary key default uuid_generate_v4(),
  user_id               uuid        not null references public.users(id) on delete cascade,
  date                  date        not null,
  status                day_status  not null default 'in_progress',
  first_hour_complete   boolean     not null default false,
  goals_count           integer     not null default 0,
  goals_completed       integer     not null default 0,
  reflection_data       jsonb,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
  unique(user_id, date)
);

comment on table  public.days is 'Daily state tracking. One row per user per day.';
comment on column public.days.reflection_data is 'Stores submitted check-in answers as JSONB for quick read without joining reflections table.';


-- ============================================================
-- TABLE: goals
-- User goals for a specific day.
-- ============================================================

create table public.goals (
  id            uuid        primary key default uuid_generate_v4(),
  user_id       uuid        not null references public.users(id) on delete cascade,
  day_id        uuid        not null references public.days(id) on delete cascade,
  text          text        not null,
  category      text        not null default 'work',
  status        text        not null default 'pending',
  priority      integer     default 3,
  source        goal_source default 'user',
  order_index   integer     default 0,
  created_at    timestamptz not null default now(),
  completed_at  timestamptz
);

comment on table public.goals is 'User goals for a specific day.';


-- ============================================================
-- TABLE: reflections
-- Nightly check-in answers linked to a day.
-- ============================================================

create table public.reflections (
  id          uuid        primary key default uuid_generate_v4(),
  user_id     uuid        not null references public.users(id) on delete cascade,
  day_id      uuid        not null references public.days(id) on delete cascade,
  question    text        not null,
  answer      text,
  category    text        not null,
  created_at  timestamptz not null default now()
);

comment on table public.reflections is 'Nightly reflection answers keyed to a day.';


-- ============================================================
-- TABLE: timers
-- Focus (pomodoro/freeform) and dopamine reset sessions.
-- ============================================================

create table public.timers (
  id                uuid        primary key default uuid_generate_v4(),
  user_id           uuid        not null references public.users(id) on delete cascade,
  day_id            uuid        not null references public.days(id) on delete cascade,
  type              timer_type  not null,
  duration_minutes  integer     not null,
  elapsed_minutes   integer     not null default 0,
  status            text        not null default 'pending',
  started_at        timestamptz,
  completed_at      timestamptz,
  created_at        timestamptz not null default now()
);

comment on table public.timers is 'Focus and reset timer sessions per day.';


-- ============================================================
-- TABLE: streaks
-- Cached streak counter. One row per user, updated post check-in.
-- Written only via service role (edge functions), never by client.
-- ============================================================

create table public.streaks (
  id            uuid        primary key default uuid_generate_v4(),
  user_id       uuid        not null unique references public.users(id) on delete cascade,
  start_date    date        not null,
  end_date      date,
  current_count integer     not null default 1,
  max_count     integer     not null default 1,
  active        boolean     not null default true,
  created_at    timestamptz not null default now()
);

comment on table  public.streaks is 'Cached streak state per user. Read-fast, write-rare.';
comment on column public.streaks.end_date is 'Null while streak is active. Set when streak breaks.';


-- ============================================================
-- TABLE: messages_to_self
-- User-composed messages with optional photo, delivered on future date.
-- ============================================================

create table public.messages_to_self (
  id               uuid                     primary key default uuid_generate_v4(),
  user_id          uuid                     not null references public.users(id) on delete cascade,
  day_id           uuid                     not null references public.days(id) on delete cascade,
  content          text                     not null,
  photo_url        text,
  scheduled_for    timestamptz              not null,
  delivery_status  message_delivery_status not null default 'pending',
  delivered_at     timestamptz,
  created_at       timestamptz              not null default now()
);

comment on table  public.messages_to_self is 'Scheduled messages from the user to their future self.';
comment on column public.messages_to_self.photo_url is 'Path in message-photos Supabase Storage bucket.';
comment on column public.messages_to_self.delivery_status is 'pending until processed; delivered when shown to user.';


-- ============================================================
-- TABLE: coach_messages
-- Full conversation history with Claude Coach.
-- ============================================================

create table public.coach_messages (
  id            uuid                primary key default uuid_generate_v4(),
  user_id       uuid                not null references public.users(id) on delete cascade,
  day_id        uuid                references public.days(id) on delete set null,
  session_type  coach_context_type  not null,
  role          coach_role          not null,
  message       text                not null,
  context       jsonb,
  tokens_used   integer,
  created_at    timestamptz         not null default now()
);

comment on table public.coach_messages is 'Turn-by-turn conversation history with Claude Coach.';


-- ============================================================
-- TABLE: notification_tokens
-- APNs tokens per device. Supports multi-device per user.
-- ============================================================

create table public.notification_tokens (
  id                uuid        primary key default uuid_generate_v4(),
  user_id           uuid        not null references public.users(id) on delete cascade,
  apns_token        text        not null unique,
  device_id         text,
  device_model      text,
  os_version        text,
  created_at        timestamptz not null default now(),
  last_verified_at  timestamptz
);

comment on table public.notification_tokens is 'APNs device tokens. One row per device, multiple per user.';


-- ============================================================
-- TABLE: reflection_questions
-- Seed data — question bank shared across all users. Read-only.
-- ============================================================

create table public.reflection_questions (
  id            uuid                    primary key default uuid_generate_v4(),
  question_text text                    not null unique,
  type          reflection_question_type not null,
  input_type    reflection_input_type   not null default 'text',
  choices       jsonb,
  display_order integer,
  created_at    timestamptz             not null default now()
);

comment on table public.reflection_questions is 'Question bank for nightly check-ins. Seeded once, read by all users.';


-- ============================================================
-- TABLE: first_hour_items
-- User-configured first-hour checklist items.
-- ============================================================

create table public.first_hour_items (
  id          uuid        primary key default uuid_generate_v4(),
  user_id     uuid        not null references public.users(id) on delete cascade,
  text        text        not null,
  order_index integer     default 0,
  active      boolean     not null default true,
  created_at  timestamptz not null default now()
);

comment on table public.first_hour_items is 'Items in the user first-hour morning checklist.';


-- ============================================================
-- TABLE: first_hour_completions
-- Daily completion records for first_hour_items.
-- ============================================================

create table public.first_hour_completions (
  id           uuid        primary key default uuid_generate_v4(),
  day_id       uuid        not null references public.days(id) on delete cascade,
  item_id      uuid        not null references public.first_hour_items(id) on delete cascade,
  completed_at timestamptz not null default now(),
  unique(day_id, item_id)
);

comment on table public.first_hour_completions is 'Tracks which first_hour_items were completed on a given day.';


-- ============================================================
-- INDEXES
-- Tuned for real app query patterns.
-- ============================================================

-- users
create index idx_users_created_at           on public.users(created_at);

-- days — most queries are user + date
create index idx_days_user_id               on public.days(user_id);
create index idx_days_user_date             on public.days(user_id, date desc);
create index idx_days_status               on public.days(user_id, status);

-- goals — always fetched by day
create index idx_goals_day_id              on public.goals(day_id);
create index idx_goals_user_id             on public.goals(user_id);

-- timers
create index idx_timers_user_day           on public.timers(user_id, day_id);

-- first hour
create index idx_first_hour_items_user     on public.first_hour_items(user_id);
create index idx_first_hour_completions_day on public.first_hour_completions(day_id);

-- coach messages — always ordered by time
create index idx_coach_messages_user_time  on public.coach_messages(user_id, created_at desc);

-- messages to self — delivery job scans pending only
create index idx_messages_delivery         on public.messages_to_self(scheduled_for, delivery_status)
  where delivery_status = 'pending';

-- streaks
create index idx_streaks_user_active       on public.streaks(user_id, active);

-- notification tokens
create index idx_notification_tokens_user  on public.notification_tokens(user_id);


-- ============================================================
-- ROW LEVEL SECURITY — enable on every table
-- ============================================================

alter table public.users                enable row level security;
alter table public.days                 enable row level security;
alter table public.goals                enable row level security;
alter table public.reflections          enable row level security;
alter table public.timers               enable row level security;
alter table public.streaks              enable row level security;
alter table public.messages_to_self     enable row level security;
alter table public.coach_messages       enable row level security;
alter table public.notification_tokens  enable row level security;
alter table public.first_hour_items     enable row level security;
alter table public.first_hour_completions enable row level security;
alter table public.reflection_questions enable row level security;


-- ============================================================
-- RLS POLICIES — users
-- ============================================================

create policy "users: read own"   on public.users for select using (auth.uid() = id);
create policy "users: update own" on public.users for update using (auth.uid() = id);


-- ============================================================
-- RLS POLICIES — days
-- ============================================================

create policy "days: read own"   on public.days for select using (auth.uid() = user_id);
create policy "days: insert own" on public.days for insert with check (auth.uid() = user_id);
create policy "days: update own" on public.days for update using (auth.uid() = user_id);


-- ============================================================
-- RLS POLICIES — goals (day_id must belong to caller)
-- ============================================================

create policy "goals: read own"
  on public.goals for select
  using (
    auth.uid() = user_id
    and exists (
      select 1 from public.days d
      where d.id = day_id and d.user_id = auth.uid()
    )
  );

create policy "goals: insert own"
  on public.goals for insert
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.days d
      where d.id = day_id and d.user_id = auth.uid()
    )
  );

create policy "goals: update own"
  on public.goals for update
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.days d
      where d.id = day_id and d.user_id = auth.uid()
    )
  );

create policy "goals: delete own"
  on public.goals for delete
  using (
    auth.uid() = user_id
    and exists (
      select 1 from public.days d
      where d.id = day_id and d.user_id = auth.uid()
    )
  );


-- ============================================================
-- RLS POLICIES — reflections (day_id must belong to caller)
-- Append-only by policy: no update/delete.
-- ============================================================

create policy "reflections: read own"
  on public.reflections for select
  using (
    auth.uid() = user_id
    and exists (
      select 1 from public.days d
      where d.id = day_id and d.user_id = auth.uid()
    )
  );

create policy "reflections: insert own"
  on public.reflections for insert
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.days d
      where d.id = day_id and d.user_id = auth.uid()
    )
  );


-- ============================================================
-- RLS POLICIES — timers (day_id must belong to caller)
-- ============================================================

create policy "timers: read own"
  on public.timers for select
  using (
    auth.uid() = user_id
    and exists (
      select 1 from public.days d
      where d.id = day_id and d.user_id = auth.uid()
    )
  );

create policy "timers: insert own"
  on public.timers for insert
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.days d
      where d.id = day_id and d.user_id = auth.uid()
    )
  );

create policy "timers: update own"
  on public.timers for update
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.days d
      where d.id = day_id and d.user_id = auth.uid()
    )
  );


-- ============================================================
-- RLS POLICIES — streaks
-- Client can only read. Writes go through service role only.
-- ============================================================

create policy "streaks: read own" on public.streaks for select using (auth.uid() = user_id);


-- ============================================================
-- RLS POLICIES — messages_to_self (day_id must belong to caller)
-- ============================================================

create policy "messages: read own"
  on public.messages_to_self for select
  using (
    auth.uid() = user_id
    and exists (
      select 1 from public.days d
      where d.id = day_id and d.user_id = auth.uid()
    )
  );

create policy "messages: insert own"
  on public.messages_to_self for insert
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.days d
      where d.id = day_id and d.user_id = auth.uid()
    )
  );

create policy "messages: update own"
  on public.messages_to_self for update
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.days d
      where d.id = day_id and d.user_id = auth.uid()
    )
  );

create policy "messages: delete own"
  on public.messages_to_self for delete
  using (
    auth.uid() = user_id
    and exists (
      select 1 from public.days d
      where d.id = day_id and d.user_id = auth.uid()
    )
  );


-- ============================================================
-- RLS POLICIES — coach_messages
-- When day_id is set, it must belong to the caller.
-- Append-only by policy: no update/delete.
-- ============================================================

create policy "coach: read own"
  on public.coach_messages for select
  using (
    auth.uid() = user_id
    and (
      day_id is null
      or exists (
        select 1 from public.days d
        where d.id = day_id and d.user_id = auth.uid()
      )
    )
  );

create policy "coach: insert own"
  on public.coach_messages for insert
  with check (
    auth.uid() = user_id
    and (
      day_id is null
      or exists (
        select 1 from public.days d
        where d.id = day_id and d.user_id = auth.uid()
      )
    )
  );


-- ============================================================
-- RLS POLICIES — notification_tokens
-- ============================================================

create policy "tokens: read own"
  on public.notification_tokens for select using (auth.uid() = user_id);

create policy "tokens: insert own"
  on public.notification_tokens for insert with check (auth.uid() = user_id);

create policy "tokens: update own"
  on public.notification_tokens for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "tokens: delete own"
  on public.notification_tokens for delete using (auth.uid() = user_id);


-- ============================================================
-- RLS POLICIES — first_hour_items
-- ============================================================

create policy "fh_items: read own"   on public.first_hour_items for select using (auth.uid() = user_id);
create policy "fh_items: insert own" on public.first_hour_items for insert with check (auth.uid() = user_id);
create policy "fh_items: update own" on public.first_hour_items for update using (auth.uid() = user_id);
create policy "fh_items: delete own" on public.first_hour_items for delete using (auth.uid() = user_id);


-- ============================================================
-- RLS POLICIES — first_hour_completions
-- Day and checklist item must both belong to caller.
-- ============================================================

create policy "fh_completions: read own"
  on public.first_hour_completions for select
  using (
    exists (
      select 1 from public.days d
      where d.id = day_id and d.user_id = auth.uid()
    )
    and exists (
      select 1 from public.first_hour_items i
      where i.id = item_id and i.user_id = auth.uid()
    )
  );

create policy "fh_completions: insert own"
  on public.first_hour_completions for insert
  with check (
    exists (
      select 1 from public.days d
      where d.id = day_id and d.user_id = auth.uid()
    )
    and exists (
      select 1 from public.first_hour_items i
      where i.id = item_id and i.user_id = auth.uid()
    )
  );

create policy "fh_completions: delete own"
  on public.first_hour_completions for delete
  using (
    exists (
      select 1 from public.days d
      where d.id = day_id and d.user_id = auth.uid()
    )
    and exists (
      select 1 from public.first_hour_items i
      where i.id = item_id and i.user_id = auth.uid()
    )
  );


-- ============================================================
-- RLS POLICIES — reflection_questions
-- Public read. No user should ever write to this table.
-- ============================================================

create policy "questions: public read"
  on public.reflection_questions for select
  using (true);


-- ============================================================
-- TRIGGER: handle_new_user
-- Fires after Supabase creates an auth.users row on signup.
-- Auto-creates: public.users profile + empty streaks row.
-- This means app code never manually creates these — they
-- exist the instant signup completes.
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
  values (new.id, now()::date)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();


-- ============================================================
-- SEED DATA — reflection_questions
-- 8 questions across 3 types: universal, won, lost.
-- Shown during nightly check-in. Seeded once, never modified.
-- ============================================================

insert into public.reflection_questions
  (question_text, type, input_type, choices, display_order)
values
  (
    'Did you doomscroll today?',
    'universal', 'fast_select',
    '["Not really", "A little", "Yes, quite a bit", "It took over"]'::jsonb,
    1
  ),
  (
    'What distracted you most today?',
    'universal', 'text', null, 2
  ),
  (
    'What made today easier or harder than expected?',
    'universal', 'text', null, 3
  ),
  (
    'What helped you win today?',
    'won', 'text', null, 1
  ),
  (
    'What would make tomorrow even cleaner?',
    'won', 'text', null, 2
  ),
  (
    'What got in the way?',
    'lost', 'fast_select',
    '["Doomscrolling", "Low energy", "Avoidance", "External interruptions", "Goals were too big"]'::jsonb,
    1
  ),
  (
    'Were you avoidant today?',
    'lost', 'fast_select',
    '["No", "Somewhat", "Yes"]'::jsonb,
    2
  ),
  (
    'What should change tomorrow?',
    'lost', 'text', null, 3
  );


-- ============================================================
-- VERIFY
-- Run these two queries after migration to confirm success.
--
-- 1. Check all 12 tables exist:
--    select table_name from information_schema.tables
--    where table_schema = 'public' order by table_name;
--
-- 2. Check seed data:
--    select type, count(*) from reflection_questions group by type;
--    Expected: lost=3, universal=3, won=2
-- ============================================================
