-- Dedup accidental duplicate focus-session submissions (client retries / double invokes).
-- A client-supplied session id makes process-focus-complete idempotent: the same
-- completion replayed reuses the id and is rejected by the partial unique index.

alter table public.focus_sessions
  add column if not exists client_session_id uuid;

create unique index if not exists focus_sessions_user_client_session_idx
  on public.focus_sessions (user_id, client_session_id)
  where client_session_id is not null;
