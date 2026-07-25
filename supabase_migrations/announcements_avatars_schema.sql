-- =====================================================================
--  PEP LANDBANK — announcements/flyers + agent profile pictures
--  Run once. Safe to re-run.
-- =====================================================================

create table if not exists public.announcements (
  id         uuid primary key default gen_random_uuid(),
  title      text not null,
  body       text,
  image_b64  text,           -- optional flyer image, base64-encoded (keep under ~500KB)
  active     boolean not null default true,
  created_by text,
  created_at timestamptz default now()
);

alter table public.announcements enable row level security;

drop policy if exists announce_sel on public.announcements;
drop policy if exists announce_ins on public.announcements;
drop policy if exists announce_upd on public.announcements;
drop policy if exists announce_del on public.announcements;
create policy announce_sel on public.announcements for select using ( auth.uid() is not null );
create policy announce_ins on public.announcements for insert with check ( public.my_role() = 'manager' );
create policy announce_upd on public.announcements for update using ( public.my_role() = 'manager' );
create policy announce_del on public.announcements for delete using ( public.my_role() = 'manager' );

-- Profile pictures: each agent can set their own; management can set anyone's.
alter table public.profiles add column if not exists avatar text; -- base64 image, small (resized client-side before upload)

drop policy if exists p_profiles_upd on public.profiles;
create policy p_profiles_upd on public.profiles for update
  using ( id = auth.uid() or public.my_role() = 'manager' );

-- =====================================================================
--  Announcement comments (for the new floating popup — agents can
--  reply to an announcement, visible to everyone). Run once too.
-- =====================================================================
create table if not exists public.announcement_comments (
  id               uuid primary key default gen_random_uuid(),
  announcement_id  uuid references public.announcements(id) on delete cascade,
  author_key       text not null,
  author_name      text not null,
  body             text not null,
  created_at       timestamptz default now()
);

alter table public.announcement_comments enable row level security;

drop policy if exists ancom_sel on public.announcement_comments;
drop policy if exists ancom_ins on public.announcement_comments;
create policy ancom_sel on public.announcement_comments for select using ( auth.uid() is not null );
create policy ancom_ins on public.announcement_comments for insert with check ( auth.uid() is not null and author_key = public.my_key() );
