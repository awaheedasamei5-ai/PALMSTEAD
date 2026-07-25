-- =====================================================================
--  PEP LANDBANK — allocation requests (30% payment trigger)
--  When a client crosses 30% paid, this creates a request for Elias,
--  Emmanuel, or Management to allocate a plot. Once allocated, the
--  originating agent is notified. Run once. Safe to re-run.
-- =====================================================================

create table if not exists public.allocation_requests (
  id           uuid primary key default gen_random_uuid(),
  lead_id      uuid references public.leads(id) on delete cascade,
  client_name  text not null,
  agent_key    text not null,
  agent_name   text,
  percent_paid numeric,
  grand_total  numeric,
  amt_paid     numeric,
  status       text not null default 'Pending' check (status in ('Pending','Allocated')),
  plot_number  text,
  note         text,
  allocated_by text,
  agent_seen   boolean not null default false,
  created_at   timestamptz default now(),
  resolved_at  timestamptz
);

alter table public.allocation_requests enable row level security;

drop policy if exists alloc_sel on public.allocation_requests;
drop policy if exists alloc_ins on public.allocation_requests;
drop policy if exists alloc_upd on public.allocation_requests;
create policy alloc_sel on public.allocation_requests for select
  using ( agent_key = public.my_key() or public.my_role()='manager' or public.my_key() in ('elias','emmanuel') );
create policy alloc_ins on public.allocation_requests for insert
  with check ( agent_key = public.my_key() or public.my_role()='manager' or public.my_key() in ('elias','emmanuel') );
create policy alloc_upd on public.allocation_requests for update
  using ( public.my_role()='manager' or public.my_key() in ('elias','emmanuel') or agent_key = public.my_key() );

-- =====================================================================
--  Offline authorization workflow for Elias/Emmanuel (site managers).
--  Adds a middle "Awaiting Authorization" step: they suggest 3 candidate
--  plots, download a signable PDF, get it physically signed by
--  Management, then come back and confirm which one was approved.
--  Run once. Safe to re-run.
-- =====================================================================
alter table public.allocation_requests add column if not exists suggested_plots text; -- comma-separated plot numbers
alter table public.allocation_requests drop constraint if exists allocation_requests_status_check;
alter table public.allocation_requests add constraint allocation_requests_status_check
  check (status in ('Pending','Awaiting Authorization','Allocated'));
