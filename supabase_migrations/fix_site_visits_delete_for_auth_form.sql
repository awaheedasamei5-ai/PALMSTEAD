-- =====================================================================
--  FIX: site_visits_del was scoped to a visit's own assigned agent only,
--  so Elizabeth/Management deleting another agent's visit from the weekly
--  Site Visit Authorization form silently deleted 0 rows (RLS just filters,
--  it doesn't error) -- the UI reported success but the row reappeared on
--  refresh. Now also allows manager + elias/emmanuel/elizabeth, matching
--  who can already see this screen (canViewClientDatabase()). Safe to re-run.
-- =====================================================================
drop policy if exists site_visits_del on public.site_visits;
create policy site_visits_del on public.site_visits for delete
  using (agent_key = my_key() or my_role() = 'manager' or my_key() in ('elias','emmanuel','elizabeth'));
