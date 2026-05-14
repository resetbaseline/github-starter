-- Extend day_status with new labels (strong / solid / light / rest).
-- Legacy values (in_progress, won, lost, skipped) remain for backwards compatibility with existing rows.

alter type day_status add value if not exists 'strong';
alter type day_status add value if not exists 'solid';
alter type day_status add value if not exists 'light';
alter type day_status add value if not exists 'rest';
