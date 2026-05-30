-- Phase 1: goal next actions, timer debrief, optional goal category column shape

alter table public.goals
  add column if not exists next_action text;

-- Timers table: persisted coach debrief after focus sessions
alter table public.timers
  add column if not exists debrief_text text;

-- Phase 2 prep — allow nullable category (was NOT NULL DEFAULT 'work')
alter table public.goals
  alter column category drop not null;

comment on column public.goals.next_action is 'Optional concrete first step toward the daily goal shown in Gate / focus debrief.';
comment on column public.timers.debrief_text is 'Haiku-generated 2–3 sentence session debrief; written by generate-focus-debrief.';
comment on column public.goals.category is 'Optional thematic bucket (nullable post–Phase 1 migration).';
