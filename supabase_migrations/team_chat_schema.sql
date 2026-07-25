-- =====================================================================
--  PEP LANDBANK — private team chat (1-on-1, WhatsApp-style)
--  Replaces the earlier single-group-channel version. Run once.
--  Safe to re-run even if you ran the old version before.
-- =====================================================================

create table if not exists public.messages (
  id             uuid primary key default gen_random_uuid(),
  sender_key     text not null,
  sender_name    text not null,
  recipient_key  text not null,
  body           text not null,
  read           boolean not null default false,
  created_at     timestamptz default now()
);

alter table public.messages add column if not exists recipient_key text;
alter table public.messages add column if not exists read boolean not null default false;

alter table public.messages enable row level security;

drop policy if exists messages_sel on public.messages;
drop policy if exists messages_ins on public.messages;
create policy messages_sel on public.messages for select
  using ( sender_key = public.my_key() or recipient_key = public.my_key() );
create policy messages_ins on public.messages for insert
  with check ( auth.uid() is not null and sender_key = public.my_key() );

-- Enables live delivery (Supabase Realtime) for this table.
alter publication supabase_realtime add table public.messages;

-- =====================================================================
--  Chat attachments (images, documents) — run once, appended to the
--  private-chat schema above. Safe to re-run.
-- =====================================================================
alter table public.messages add column if not exists attachment_data text;   -- base64
alter table public.messages add column if not exists attachment_type text;   -- 'image' | 'file'
alter table public.messages add column if not exists attachment_name text;   -- original filename

-- Delete permission — sender can delete their own messages. Run once too.
drop policy if exists messages_del on public.messages;
create policy messages_del on public.messages for delete using ( sender_key = my_key() );
