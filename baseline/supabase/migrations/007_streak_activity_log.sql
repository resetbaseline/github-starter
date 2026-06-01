-- RES-65: one streak increment per calendar day from check-in, anchor, or focus session (10+ min)

create table public.streak_activity_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  activity_date date not null,
  activity_type text not null check (activity_type in ('check_in', 'anchor', 'focus_session')),
  created_at timestamptz not null default now(),
  unique (user_id, activity_date)
);

comment on table public.streak_activity_log is 'At most one streak-counting activity per user per calendar day; activity_type records which signal fired first.';

alter table public.streak_activity_log enable row level security;

create policy "Users can read own streak activity"
  on public.streak_activity_log for select
  using (auth.uid() = user_id);

create policy "Users can insert own streak activity"
  on public.streak_activity_log for insert
  with check (auth.uid() = user_id);

-- Daily anchors (home / onboarding completion)
create table public.daily_anchors (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  anchor_text text not null,
  activity_date date not null default (current_date),
  completed boolean not null default false,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create index daily_anchors_user_date_idx on public.daily_anchors (user_id, activity_date);

alter table public.daily_anchors enable row level security;

create policy "Users can read own daily anchors"
  on public.daily_anchors for select
  using (auth.uid() = user_id);

create policy "Users can update own daily anchors"
  on public.daily_anchors for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can insert own daily anchors"
  on public.daily_anchors for insert
  with check (auth.uid() = user_id);

-- Focus sessions (10+ minutes count toward streak via edge function)
create table public.focus_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  duration_minutes integer not null check (duration_minutes > 0),
  completed_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index focus_sessions_user_completed_idx on public.focus_sessions (user_id, completed_at desc);

alter table public.focus_sessions enable row level security;

create policy "Users can read own focus sessions"
  on public.focus_sessions for select
  using (auth.uid() = user_id);

create policy "Users can insert own focus sessions"
  on public.focus_sessions for insert
  with check (auth.uid() = user_id);
