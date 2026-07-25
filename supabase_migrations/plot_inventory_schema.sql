-- =====================================================================
--  PEP LANDBANK — Plot inventory (v2)
--  Run this in Supabase → SQL Editor. Safe to re-run, and safe to run
--  even if you already ran the old plot_inventory_schema.sql — it
--  upgrades the status list and does NOT insert any fake/sample plots.
--  You add your real plots from the app's Plots tab (one at a time, or
--  paste a bulk list of plot numbers to add many at once).
-- =====================================================================

create table if not exists public.plots (
  id           uuid primary key default gen_random_uuid(),
  site         text not null default 'Royal Palm Enclave, Tsopoli',
  plot_number  text not null,
  plot_type    text default 'Full Plot' check (plot_type in ('Full Plot','Half Plot')),
  status       text not null default 'Available',
  price        numeric,
  client_name    text,
  client_contact text,
  agent_key      text,
  notes        text,
  created_at   timestamptz default now(),
  updated_at   timestamptz default now(),
  unique (site, plot_number)
);

update public.plots set status='Running Search' where status='Reserved';
update public.plots set status='Allocated' where status='Sold';

alter table public.plots drop constraint if exists plots_status_check;
alter table public.plots add constraint plots_status_check
  check (status in ('Available','Running Search','Allocated'));

alter table public.plots enable row level security;

-- Elias and Emmanuel manage the plot inventory alongside Management (per
-- your instruction). Other agents get availability only, EXCEPT for plots
-- they personally sold, where they should see the full details.
drop policy if exists plots_sel on public.plots;
drop policy if exists plots_ins on public.plots;
drop policy if exists plots_upd on public.plots;
drop policy if exists plots_del on public.plots;
create policy plots_sel on public.plots for select using ( public.my_role() = 'manager' or public.my_key() in ('elias','emmanuel') );
create policy plots_ins on public.plots for insert with check ( public.my_role() = 'manager' or public.my_key() in ('elias','emmanuel') );
create policy plots_upd on public.plots for update using ( public.my_role() = 'manager' or public.my_key() in ('elias','emmanuel') );
create policy plots_del on public.plots for delete using ( public.my_role() = 'manager' or public.my_key() in ('elias','emmanuel') );

create or replace view public.plots_availability as
  select id, site, plot_number, plot_type, status, price, updated_at from public.plots;
grant select on public.plots_availability to authenticated;

-- Any agent can see full details of ONLY the plots they personally sold —
-- not anyone else's. Runs as owner (bypasses the manager-only policy above
-- on purpose) but is filtered to the caller's own agent_key either way.
create or replace view public.plots_my_sales as
  select * from public.plots where agent_key = public.my_key();
grant select on public.plots_my_sales to authenticated;

-- Seeds the REAL inventory: 403 plots across Blocks A-O, exactly matching
-- the counts on your surveyor's legend (Block A=40 ... Block O=8). Numbered
-- A1..A40, B1..B52, etc. to match the site plan. All start as Available —
-- update each one's status/client/agent as real allocations happen.
-- Safe to re-run (skips any plot number that already exists).

insert into public.plots (site, plot_number, plot_type, status)
select 'Royal Palm Enclave, Tsopoli', 'A' || n, 'Full Plot', 'Available'
from generate_series(1, 40) as n
on conflict (site, plot_number) do nothing;

insert into public.plots (site, plot_number, plot_type, status)
select 'Royal Palm Enclave, Tsopoli', 'B' || n, 'Full Plot', 'Available'
from generate_series(1, 52) as n
on conflict (site, plot_number) do nothing;

insert into public.plots (site, plot_number, plot_type, status)
select 'Royal Palm Enclave, Tsopoli', 'C' || n, 'Full Plot', 'Available'
from generate_series(1, 22) as n
on conflict (site, plot_number) do nothing;

insert into public.plots (site, plot_number, plot_type, status)
select 'Royal Palm Enclave, Tsopoli', 'D' || n, 'Full Plot', 'Available'
from generate_series(1, 22) as n
on conflict (site, plot_number) do nothing;

insert into public.plots (site, plot_number, plot_type, status)
select 'Royal Palm Enclave, Tsopoli', 'E' || n, 'Full Plot', 'Available'
from generate_series(1, 22) as n
on conflict (site, plot_number) do nothing;

insert into public.plots (site, plot_number, plot_type, status)
select 'Royal Palm Enclave, Tsopoli', 'F' || n, 'Full Plot', 'Available'
from generate_series(1, 25) as n
on conflict (site, plot_number) do nothing;

insert into public.plots (site, plot_number, plot_type, status)
select 'Royal Palm Enclave, Tsopoli', 'G' || n, 'Full Plot', 'Available'
from generate_series(1, 26) as n
on conflict (site, plot_number) do nothing;

insert into public.plots (site, plot_number, plot_type, status)
select 'Royal Palm Enclave, Tsopoli', 'H' || n, 'Full Plot', 'Available'
from generate_series(1, 26) as n
on conflict (site, plot_number) do nothing;

insert into public.plots (site, plot_number, plot_type, status)
select 'Royal Palm Enclave, Tsopoli', 'I' || n, 'Full Plot', 'Available'
from generate_series(1, 26) as n
on conflict (site, plot_number) do nothing;

insert into public.plots (site, plot_number, plot_type, status)
select 'Royal Palm Enclave, Tsopoli', 'J' || n, 'Full Plot', 'Available'
from generate_series(1, 28) as n
on conflict (site, plot_number) do nothing;

insert into public.plots (site, plot_number, plot_type, status)
select 'Royal Palm Enclave, Tsopoli', 'K' || n, 'Full Plot', 'Available'
from generate_series(1, 28) as n
on conflict (site, plot_number) do nothing;

insert into public.plots (site, plot_number, plot_type, status)
select 'Royal Palm Enclave, Tsopoli', 'L' || n, 'Full Plot', 'Available'
from generate_series(1, 27) as n
on conflict (site, plot_number) do nothing;

insert into public.plots (site, plot_number, plot_type, status)
select 'Royal Palm Enclave, Tsopoli', 'M' || n, 'Full Plot', 'Available'
from generate_series(1, 26) as n
on conflict (site, plot_number) do nothing;

insert into public.plots (site, plot_number, plot_type, status)
select 'Royal Palm Enclave, Tsopoli', 'N' || n, 'Full Plot', 'Available'
from generate_series(1, 25) as n
on conflict (site, plot_number) do nothing;

insert into public.plots (site, plot_number, plot_type, status)
select 'Royal Palm Enclave, Tsopoli', 'O' || n, 'Full Plot', 'Available'
from generate_series(1, 8) as n
on conflict (site, plot_number) do nothing;
