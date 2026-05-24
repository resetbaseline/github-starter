-- Support tickets submitted from the in-app help flow

create table if not exists public.support_tickets (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users (id) on delete cascade,
  category text not null,
  message text not null,
  resolved_by_bot boolean default false,
  device_info jsonb,
  app_version text,
  created_at timestamptz default now()
);

alter table public.support_tickets enable row level security;

create policy "support_tickets_insert_own"
  on public.support_tickets
  for insert
  with check (auth.uid() = user_id);
