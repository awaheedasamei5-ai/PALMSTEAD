-- =====================================================================
--  PEP LANDBANK — cleanup old fake plot numbers
--  Run this ONCE if your Plot Inventory still shows RP-001, TS-001, etc.
--  Those were placeholder numbers from an earlier version of this system
--  and were never real. This deletes them. It does NOT touch your real
--  leads, enquiries, complaints, or site visits — only the "plots" table,
--  and only rows matching the old RP-/TS- naming pattern.
-- =====================================================================

delete from public.plots where plot_number like 'RP-%' or plot_number like 'TS-%';

-- Confirms what's left — should show only real A1..O8 style numbers.
select site, plot_number, status from public.plots order by plot_number;
