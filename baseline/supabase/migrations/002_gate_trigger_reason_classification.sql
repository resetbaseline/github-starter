-- Persist Haiku classification for gate-resolve mismatch_flagged logic.
alter table public.gate_triggers
  add column if not exists reason_classification text;

comment on column public.gate_triggers.reason_classification is
  'Haiku label from gate-validate: specific_legitimate | plausible | vague | low_legitimacy. Null for focus_block / unknown.';
