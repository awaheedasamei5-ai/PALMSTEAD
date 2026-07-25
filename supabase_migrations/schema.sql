-- =====================================================================
--  PEP LANDBANK SALES PORTAL — Supabase schema
--  Run this FIRST in Supabase → SQL Editor (paste all, click Run)
-- =====================================================================

-- ---- PROFILES (one row per staff login) ----
create table if not exists public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  email      text unique not null,
  name       text not null,
  role       text not null default 'agent' check (role in ('agent','manager')),
  agent_key  text unique,
  active     boolean not null default true,
  created_at timestamptz default now()
);

-- Security-definer helpers (avoid RLS recursion on profiles)
create or replace function public.my_role() returns text
  language sql security definer stable set search_path = public as
$$ select role from public.profiles where id = auth.uid() $$;

create or replace function public.my_key() returns text
  language sql security definer stable set search_path = public as
$$ select agent_key from public.profiles where id = auth.uid() $$;

-- ---- ALLOWED EMAILS (invite list — only these emails may self-register) ----
create table if not exists public.allowed_emails (
  email      text primary key,
  name       text,
  invited_by text,
  created_at timestamptz default now()
);

-- security-definer check: lets the profiles INSERT policy verify an email is on
-- the invite list without needing to grant the new (not-yet-a-manager) user
-- direct read access to the allowed_emails table.
create or replace function public.email_is_allowed(check_email text) returns boolean
  language sql security definer stable set search_path = public as
$$ select exists (select 1 from public.allowed_emails a where lower(a.email) = lower(check_email)) $$;

-- ---- LEADS (the pipeline) ----
create table if not exists public.leads (
  id           uuid primary key default gen_random_uuid(),
  agent_key    text not null,
  name         text not null,
  contact      text,
  date_added   date default current_date,
  stage        text,
  plot_type    text,
  no_plots     numeric,
  unit_price   numeric,
  discount     numeric,
  net_total    numeric,
  payment_plan text,
  grand_total  numeric,
  site_visit   text,
  priority     text,
  amt_paid     numeric default 0,
  balance      numeric,
  next_action  text,
  notes        text,
  created_at   timestamptz default now()
);

-- ---- ENQUIRIES ----
create table if not exists public.enquiries (
  id uuid primary key default gen_random_uuid(),
  agent_key text not null, agent_name text,
  name text, contact text, location text,
  types text, plot text, source text, details text,
  follow text, follow_date date,
  created_at timestamptz default now()
);

-- ---- COMPLAINTS ----
create table if not exists public.complaints (
  id uuid primary key default gen_random_uuid(),
  agent_key text not null, agent_name text,
  name text, contact text, plot text, category text, details text,
  owner text, priority text, resolution text,
  status text default 'Open',
  created_at timestamptz default now()
);

-- ---- SITE VISITS ----
create table if not exists public.site_visits (
  id uuid primary key default gen_random_uuid(),
  agent_key text not null, agent_name text,
  name text, contact text, plot text, site text,
  visit_date date, visit_time text, people numeric, transport text, pickup text, notes text,
  status text default 'Pending',
  created_at timestamptz default now()
);

-- ---- ACTIVITY LOG ----
create table if not exists public.activity_log (
  id uuid primary key default gen_random_uuid(),
  agent_key text not null, agent_name text,
  client text, action text, detail text, note text, method text, follow date,
  created_at timestamptz default now()
);

-- ---- APP CONFIG (plot pricing, interest, monthly targets — single row) ----
create table if not exists public.app_config (
  id             int primary key default 1,
  full_price     numeric default 48000,
  half_price     numeric default 26500,
  full_discount  numeric default 8000,
  half_discount  numeric default 6500,
  int_3          numeric default 750,
  int_6          numeric default 1500,
  int_9          numeric default 2250,
  int_12         numeric default 3000,
  targets        jsonb default '{}'::jsonb,
  note           text default '',
  updated_at     timestamptz default now(),
  constraint app_config_single_row check (id = 1)
);
insert into public.app_config (id) values (1) on conflict (id) do nothing;

-- =====================  ROW LEVEL SECURITY  =====================
alter table public.profiles     enable row level security;
alter table public.leads        enable row level security;
alter table public.enquiries    enable row level security;
alter table public.complaints   enable row level security;
alter table public.site_visits  enable row level security;
alter table public.activity_log enable row level security;
alter table public.app_config   enable row level security;
alter table public.allowed_emails enable row level security;

-- allowed_emails: only managers can view/add/remove invited emails.
-- (New self-signups don't need direct access to this table — email_is_allowed()
-- checks it for them via a security-definer function, above.)
drop policy if exists p_allow_sel on public.allowed_emails;
drop policy if exists p_allow_ins on public.allowed_emails;
drop policy if exists p_allow_del on public.allowed_emails;
create policy p_allow_sel on public.allowed_emails for select using ( public.my_role() = 'manager' );
create policy p_allow_ins on public.allowed_emails for insert with check ( public.my_role() = 'manager' );
create policy p_allow_del on public.allowed_emails for delete using ( public.my_role() = 'manager' );

-- profiles: readable by anyone (even signed-out visitors) so the sign-in screen can
-- show a live list of registered staff. Only name/email/role/agent_key/active are stored here —
-- nothing sensitive — passwords live separately and securely in Supabase Auth.
drop policy if exists p_profiles_sel on public.profiles;
create policy p_profiles_sel on public.profiles for select using ( true );

-- self-registration: a newly signed-up user may create their OWN profile row, but only
-- as role 'agent', and only if management has invited their email — this is enforced by
-- Postgres, not just the app, so nobody can grant themselves Management access or join
-- without being invited by calling the API directly.
drop policy if exists p_profiles_ins on public.profiles;
create policy p_profiles_ins on public.profiles for insert
  with check ( id = auth.uid() and role = 'agent' and public.email_is_allowed(email) );

-- you can update your own profile; a manager can update anyone's (e.g. to deactivate them)
drop policy if exists p_profiles_upd on public.profiles;
create policy p_profiles_upd on public.profiles for update
  using ( id = auth.uid() or public.my_role() = 'manager' );

-- app_config: everyone signed in can read (so pricing shows on new-lead forms);
-- only managers can create/update it (pricing & targets are a management decision)
drop policy if exists p_config_sel on public.app_config;
drop policy if exists p_config_ins on public.app_config;
drop policy if exists p_config_upd on public.app_config;
create policy p_config_sel on public.app_config for select using ( auth.uid() is not null );
create policy p_config_ins on public.app_config for insert with check ( public.my_role() = 'manager' );
create policy p_config_upd on public.app_config for update using ( public.my_role() = 'manager' );

-- generic pattern: own rows by agent_key, managers see/edit all.
-- leads, enquiries, complaints, site_visits can be deleted (by the owning agent or a manager).
-- activity_log is kept insert/select-only on purpose — it's the audit trail and is never deleted.
do $$
declare t text;
begin
  foreach t in array array['leads','enquiries','complaints','site_visits'] loop
    execute format('drop policy if exists %I_sel on public.%I;', t, t);
    execute format('drop policy if exists %I_ins on public.%I;', t, t);
    execute format('drop policy if exists %I_upd on public.%I;', t, t);
    execute format('drop policy if exists %I_del on public.%I;', t, t);
    execute format($f$create policy %I_sel on public.%I for select
        using (agent_key = public.my_key() or public.my_role() = 'manager');$f$, t, t);
    execute format($f$create policy %I_ins on public.%I for insert
        with check (agent_key = public.my_key());$f$, t, t);
    execute format($f$create policy %I_upd on public.%I for update
        using (agent_key = public.my_key() or public.my_role() = 'manager');$f$, t, t);
    execute format($f$create policy %I_del on public.%I for delete
        using (agent_key = public.my_key() or public.my_role() = 'manager');$f$, t, t);
  end loop;

  -- activity_log: select/insert only, no update, no delete — permanent audit trail
  execute 'drop policy if exists activity_log_sel on public.activity_log;';
  execute 'drop policy if exists activity_log_ins on public.activity_log;';
  execute $f$create policy activity_log_sel on public.activity_log for select
      using (agent_key = public.my_key() or public.my_role() = 'manager');$f$;
  execute $f$create policy activity_log_ins on public.activity_log for insert
      with check (agent_key = public.my_key());$f$;
end $$;
