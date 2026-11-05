-- Optional: remove the first, single-family version of the archive's tables.
-- Only run this if you ran an earlier setup.sql and haven't saved anything
-- you want to keep there. It deletes the old "members" and "items" tables.
drop table if exists public.items cascade;
drop table if exists public.members cascade;
drop function if exists public.my_role();
