-- =====================================================================
--  SECURITY FIX: client_portal_link_auth account-hijack.
--
--  client_portal_link_auth() is SECURITY DEFINER (it has to be -- RLS on
--  client_portal_access requires auth_uid = auth.uid(), which is exactly
--  what hasn't been set yet on someone's very first login). But the old
--  version trusted p_access_id blindly: it set
--    auth_uid = auth.uid() where id = p_access_id
--  with no check that the caller actually owned that row. Any authenticated
--  client (having legitimately signed in as themselves first) could call
--  this RPC with a DIFFERENT client's access_id and re-point that other
--  client's row to their own session -- reading their leads/payments and
--  locking the real owner out.
--
--  Fixed to only link a row that is unclaimed (auth_uid is null) or already
--  belongs to the caller (a harmless repeat login). Safe to re-run.
-- =====================================================================
create or replace function public.client_portal_link_auth(p_access_id uuid)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare v_current uuid;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  select auth_uid into v_current from public.client_portal_access where id = p_access_id;
  if v_current is null then
    update public.client_portal_access set auth_uid = auth.uid() where id = p_access_id;
  elsif v_current <> auth.uid() then
    raise exception 'already_linked';
  end if;
  -- v_current = auth.uid() already: no-op, this is just a repeat login.
end;
$function$;
