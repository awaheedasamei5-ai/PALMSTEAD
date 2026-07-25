-- =====================================================================
--  Site visit form fields — matching your real TSOPOLI SITE VISIT
--  REQUEST FORM exactly. Run this once too. Safe to re-run.
-- =====================================================================
alter table public.site_visits add column if not exists place_of_work text;
alter table public.site_visits add column if not exists position text;
alter table public.site_visits add column if not exists nationality text;
alter table public.site_visits add column if not exists purpose text;
alter table public.site_visits add column if not exists discussion_so_far text;
alter table public.site_visits add column if not exists key_understanding text;
alter table public.site_visits add column if not exists feedback_after text;
alter table public.site_visits add column if not exists key_next_steps text;
