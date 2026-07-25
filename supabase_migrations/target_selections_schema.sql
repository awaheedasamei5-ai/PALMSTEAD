-- =====================================================================
--  PEP LANDBANK — monthly target selections (expected revenue tracking)
--  Run once. Safe to re-run.
-- =====================================================================
create table if not exists public.target_selections (
  id             uuid primary key default gen_random_uuid(),
  agent_key      text not null,
  month          text not null,
  lead_id        uuid references public.leads(id) on delete cascade,
  client_name    text not null,
  payment_type   text not null check (payment_type in ('30% Deposit','Outright','Partial')),
  expected_amount numeric not null default 0,
  created_at     timestamptz default now()
);

alter table public.target_selections enable row level security;

drop policy if exists target_sel_sel on public.target_selections;
drop policy if exists target_sel_ins on public.target_selections;
drop policy if exists target_sel_upd on public.target_selections;
drop policy if exists target_sel_del on public.target_selections;
create policy target_sel_sel on public.target_selections for select using ( agent_key = my_key() or my_role()='manager' );
create policy target_sel_ins on public.target_selections for insert with check ( agent_key = my_key() );
create policy target_sel_upd on public.target_selections for update using ( agent_key = my_key() );
create policy target_sel_del on public.target_selections for delete using ( agent_key = my_key() );

alter table public.app_config add column if not exists target_plots_per_month numeric default 2;
