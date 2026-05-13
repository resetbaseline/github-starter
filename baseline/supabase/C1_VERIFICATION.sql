-- ============================================================
-- C1 verification — run in Supabase SQL Editor after migration
-- ============================================================

-- 1) Extensions
select extname from pg_extension where extname in ('uuid-ossp', 'pg_net') order by extname;

-- 2) All public tables (expect 20)
select table_name
from information_schema.tables
where table_schema = 'public' and table_type = 'BASE TABLE'
order by table_name;

-- 3) Enum types (expect 10 custom types; filter app enums)
select t.typname
from pg_type t
join pg_namespace n on n.oid = t.typnamespace
where n.nspname = 'public' and t.typtype = 'e'
order by t.typname;

-- 4) Indexes (subset: named idx_* from migration)
select indexname, tablename
from pg_indexes
where schemaname = 'public' and indexname like 'idx_%'
order by tablename, indexname;

-- 5) RLS enabled on every public table
select c.relname as table_name, c.relrowsecurity as rls_enabled
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'r' and c.relname not like 'pg_%'
order by c.relname;

-- 6) Policy counts per table
select tablename, count(*) as policy_count
from pg_policies
where schemaname = 'public'
group by tablename
order by tablename;

-- 7) Triggers on auth.users and app tables
select event_object_table as table_name, trigger_name, action_timing, event_manipulation
from information_schema.triggers
where trigger_schema = 'public' or event_object_schema = 'auth'
order by event_object_table, trigger_name;

-- 8) Seed: reflection_questions counts by type (expect universal=3, won=2, lost=3)
select type, count(*) from public.reflection_questions group by type order by type;

-- 9) Seed: total rows (expect 8)
select count(*) as reflection_question_rows from public.reflection_questions;

-- 10) users.pro column exists (coach rate limit)
select column_name, data_type, column_default
from information_schema.columns
where table_schema = 'public' and table_name = 'users' and column_name = 'pro';

-- 11) gate_triggers.mismatch_flagged exists
select column_name, data_type, column_default
from information_schema.columns
where table_schema = 'public' and table_name = 'gate_triggers' and column_name = 'mismatch_flagged';
