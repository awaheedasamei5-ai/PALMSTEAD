-- =====================================================================
--  PEP LANDBANK — link staff logins to profiles
--  Run this SECOND, AFTER you have created the 5 users in
--  Supabase -> Authentication -> Users -> Add user (same emails below).
--  It matches each auth user to their profile automatically by email.
-- =====================================================================
insert into public.profiles (id, email, name, role, agent_key)
select u.id, x.email, x.name, x.role, x.agent_key
from auth.users u
join ( values
  ('executiveassistant@landbankghana.com','Elizabeth Misiame','agent','elizabeth'),
  ('opsofficer@landbankghana.com','Elias Torgbuivi','agent','elias'),
  ('digitalopsofficer@landbankghana.com','Adams','agent','adams'),
  ('operations@landbankghana.com','Emmanuel Anane','agent','emmanuel'),
  ('fapeprah@landbankghana.com','Management','manager','manager')
) as x(email,name,role,agent_key) on lower(x.email) = lower(u.email)
on conflict (id) do update
  set name = excluded.name, role = excluded.role, agent_key = excluded.agent_key;

select email, name, role, agent_key from public.profiles order by role, name;
