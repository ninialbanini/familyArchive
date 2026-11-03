-- Family Voice Archive: one-time Supabase setup.
-- Paste this whole file into Supabase → SQL Editor → New query, change the
-- email on the last line to your own, and click Run. Safe to run again.

-- Who may come in, and what they may do.
create table if not exists public.members (
  email    text primary key,
  role     text not null default 'viewer' check (role in ('viewer', 'editor')),
  added_at timestamptz not null default now()
);

-- One row per voice note, photo or video. The details live in `data`.
create table if not exists public.items (
  id         text primary key,
  data       jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.members enable row level security;
alter table public.items   enable row level security;

-- The signed-in person's role, or null if they're not on the family list.
create or replace function public.my_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.members
  where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
$$;
grant execute on function public.my_role() to authenticated;

-- members: you can see your own row; editors see and manage everyone.
drop policy if exists "members: read own or editor"   on public.members;
drop policy if exists "members: editors insert"        on public.members;
drop policy if exists "members: editors update"        on public.members;
drop policy if exists "members: editors delete"        on public.members;
create policy "members: read own or editor" on public.members for select to authenticated
  using (lower(email) = lower(coalesce(auth.jwt() ->> 'email', '')) or public.my_role() = 'editor');
create policy "members: editors insert" on public.members for insert to authenticated
  with check (public.my_role() = 'editor');
create policy "members: editors update" on public.members for update to authenticated
  using (public.my_role() = 'editor') with check (public.my_role() = 'editor');
create policy "members: editors delete" on public.members for delete to authenticated
  using (public.my_role() = 'editor');

-- items: everyone on the list reads; only editors write.
drop policy if exists "items: family reads"    on public.items;
drop policy if exists "items: editors insert"  on public.items;
drop policy if exists "items: editors update"  on public.items;
drop policy if exists "items: editors delete"  on public.items;
create policy "items: family reads" on public.items for select to authenticated
  using (public.my_role() in ('viewer', 'editor'));
create policy "items: editors insert" on public.items for insert to authenticated
  with check (public.my_role() = 'editor');
create policy "items: editors update" on public.items for update to authenticated
  using (public.my_role() = 'editor') with check (public.my_role() = 'editor');
create policy "items: editors delete" on public.items for delete to authenticated
  using (public.my_role() = 'editor');

-- Private storage for the recordings and photos (50 MB per file).
insert into storage.buckets (id, name, public, file_size_limit)
values ('media', 'media', false, 52428800)
on conflict (id) do update set public = false, file_size_limit = 52428800;

drop policy if exists "media: family reads"    on storage.objects;
drop policy if exists "media: editors upload"  on storage.objects;
drop policy if exists "media: editors delete"  on storage.objects;
create policy "media: family reads" on storage.objects for select to authenticated
  using (bucket_id = 'media' and public.my_role() in ('viewer', 'editor'));
create policy "media: editors upload" on storage.objects for insert to authenticated
  with check (bucket_id = 'media' and public.my_role() = 'editor');
create policy "media: editors delete" on storage.objects for delete to authenticated
  using (bucket_id = 'media' and public.my_role() = 'editor');

-- Live updates when someone else adds or edits an item.
do $$
begin
  alter publication supabase_realtime add table public.items;
exception when duplicate_object then null;
end $$;

-- You: the first editor. Change this to the email you'll sign in with.
insert into public.members (email, role)
values (lower('YOUR_EMAIL@example.com'), 'editor')
on conflict (email) do update set role = 'editor';
