-- =====================================================================
--  PEP LANDBANK — payments ledger
--  Needed for accurate month-by-month "Collected" figures. Without this,
--  the system only has a running total per client, not a per-payment
--  history, so it cannot correctly say "GHS X was collected in March"
--  once April happens — it can only say "GHS X paid so far, total."
--  Run this once. Safe to re-run.
-- =====================================================================

create table if not exists public.payments (
  id           uuid primary key default gen_random_uuid(),
  lead_id      uuid references public.leads(id) on delete set null,
  agent_key    text not null,
  client_name  text not null,
  amount       numeric not null check (amount > 0),
  payment_date date not null default current_date,
  note         text,
  created_at   timestamptz default now()
);

alter table public.payments enable row level security;

drop policy if exists payments_sel on public.payments;
drop policy if exists payments_ins on public.payments;
create policy payments_sel on public.payments for select
  using ( agent_key = public.my_key() or public.my_role() = 'manager' );
create policy payments_ins on public.payments for insert
  with check ( agent_key = public.my_key() or public.my_role() = 'manager' );

-- One-time backfill: turns each existing lead's current "amount paid"
-- into a single opening payment record, dated to when the lead was added,
-- so your Monthly Collected view isn't empty for money already collected
-- before this table existed. Safe to run once; skips leads with nothing paid.
insert into public.payments (lead_id, agent_key, client_name, amount, payment_date, note)
select id, agent_key, name, amt_paid, coalesce(date_added, current_date), 'Opening balance (recorded before payment history was tracked)'
from public.leads
where amt_paid is not null and amt_paid > 0;
