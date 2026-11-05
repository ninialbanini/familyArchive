-- Family Voice Archive: setup for many private families.
-- Paste this whole file into Supabase → SQL Editor → New query and click Run.
-- Safe to run again; it never deletes anything.
--
-- How it works: anyone can make an account (email sign-in link). A signed-in
-- person can START a family archive, choosing a family name and a family
-- password, and becomes its keeper. Relatives JOIN by typing that family name
-- and password. Each family only ever sees its own recordings and photos.

create extension if not exists pgcrypto with schema extensions;

-- ---------- tables ----------
create table if not exists public.families (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);
create unique index if not exists families_name_key on public.families (lower(name));

-- Family passwords, stored only as bcrypt hashes. No one can read this table
-- directly; only the functions below use it.
create table if not exists public.family_secrets (
  family_id     uuid primary key references public.families(id) on delete cascade,
  password_hash text not null
);

-- keeper: started the family (or was made keeper); can change the family
-- password and manage members. member: can listen, upload, edit and delete.
create table if not exists public.family_members (
  family_id    uuid not null references public.families(id) on delete cascade,
  user_id      uuid not null references auth.users(id) on delete cascade,
  email        text,
  display_name text,
  role         text not null default 'member' check (role in ('keeper', 'member')),
  joined_at    timestamptz not null default now(),
  primary key (family_id, user_id)
);

-- One row per voice note, photo or video, belonging to one family.
create table if not exists public.archive_items (
  family_id  uuid not null references public.families(id) on delete cascade,
  id         text not null,
  data       jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (family_id, id)
);

-- Wrong family-password attempts, to slow down guessing.
create table if not exists public.join_attempts (
  user_id uuid not null,
  at      timestamptz not null default now()
);
create index if not exists join_attempts_user_at on public.join_attempts (user_id, at);

alter table public.families       enable row level security;
alter table public.family_secrets enable row level security;
alter table public.family_members enable row level security;
alter table public.archive_items  enable row level security;
alter table public.join_attempts  enable row level security;

-- ---------- helper checks ----------
create or replace function public.is_member(fid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.family_members where family_id = fid and user_id = auth.uid())
$$;

create or replace function public.is_keeper(fid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.family_members where family_id = fid and user_id = auth.uid() and role = 'keeper')
$$;

-- Storage files live under "<family id>/<file>".
create or replace function public.is_member_path(p text)
returns boolean language plpgsql stable security definer set search_path = public as $$
begin
  return public.is_member(split_part(p, '/', 1)::uuid);
exception when others then
  return false;
end $$;

-- ---------- actions ----------
create or replace function public.create_family(p_name text, p_password text, p_display_name text)
returns uuid language plpgsql security definer set search_path = public, extensions as $$
declare
  uid uuid := auth.uid();
  n   text := btrim(coalesce(p_name, ''));
  fid uuid;
begin
  if uid is null then raise exception 'not signed in'; end if;
  if length(n) < 2 then raise exception 'family name too short'; end if;
  if length(coalesce(p_password, '')) < 8 then raise exception 'password too short'; end if;
  if exists (select 1 from public.families where lower(name) = lower(n)) then raise exception 'family name taken'; end if;
  insert into public.families (name, created_by) values (n, uid) returning id into fid;
  insert into public.family_secrets (family_id, password_hash) values (fid, crypt(p_password, gen_salt('bf')));
  insert into public.family_members (family_id, user_id, email, display_name, role)
  values (fid, uid, auth.jwt() ->> 'email', nullif(btrim(coalesce(p_display_name, '')), ''), 'keeper');
  return fid;
end $$;

-- Returns the family's id, or null if the name or password is wrong.
create or replace function public.join_family(p_name text, p_password text, p_display_name text)
returns uuid language plpgsql security definer set search_path = public, extensions as $$
declare
  uid uuid := auth.uid();
  fid uuid;
  h   text;
begin
  if uid is null then raise exception 'not signed in'; end if;
  if (select count(*) from public.join_attempts where user_id = uid and at > now() - interval '15 minutes') >= 8 then
    raise exception 'too many attempts';
  end if;
  select f.id, s.password_hash into fid, h
  from public.families f join public.family_secrets s on s.family_id = f.id
  where lower(f.name) = lower(btrim(coalesce(p_name, '')));
  if fid is null or crypt(coalesce(p_password, ''), h) is distinct from h then
    insert into public.join_attempts (user_id) values (uid);
    return null;
  end if;
  insert into public.family_members (family_id, user_id, email, display_name, role)
  values (fid, uid, auth.jwt() ->> 'email', nullif(btrim(coalesce(p_display_name, '')), ''), 'member')
  on conflict (family_id, user_id) do update
    set display_name = coalesce(excluded.display_name, public.family_members.display_name);
  return fid;
end $$;

create or replace function public.set_family_password(p_family uuid, p_password text)
returns void language plpgsql security definer set search_path = public, extensions as $$
begin
  if not public.is_keeper(p_family) then raise exception 'only keepers can change the family password'; end if;
  if length(coalesce(p_password, '')) < 8 then raise exception 'password too short'; end if;
  update public.family_secrets set password_hash = crypt(p_password, gen_salt('bf')) where family_id = p_family;
end $$;

create or replace function public.set_my_name(p_family uuid, p_name text)
returns void language sql security definer set search_path = public as $$
  update public.family_members set display_name = nullif(btrim(coalesce(p_name, '')), '')
  where family_id = p_family and user_id = auth.uid()
$$;

grant execute on function public.is_member(uuid), public.is_keeper(uuid), public.is_member_path(text),
  public.create_family(text, text, text), public.join_family(text, text, text),
  public.set_family_password(uuid, text), public.set_my_name(uuid, text) to authenticated;

-- ---------- who can see and change what ----------
drop policy if exists "families: members read"     on public.families;
drop policy if exists "families: keepers rename"   on public.families;
create policy "families: members read" on public.families for select to authenticated
  using (public.is_member(id));
create policy "families: keepers rename" on public.families for update to authenticated
  using (public.is_keeper(id)) with check (public.is_keeper(id));

drop policy if exists "members: family reads"          on public.family_members;
drop policy if exists "members: keepers change roles"  on public.family_members;
drop policy if exists "members: keepers remove, or leave" on public.family_members;
create policy "members: family reads" on public.family_members for select to authenticated
  using (public.is_member(family_id));
create policy "members: keepers change roles" on public.family_members for update to authenticated
  using (public.is_keeper(family_id)) with check (public.is_keeper(family_id));
create policy "members: keepers remove, or leave" on public.family_members for delete to authenticated
  using (public.is_keeper(family_id) or user_id = auth.uid());

drop policy if exists "items: family reads"   on public.archive_items;
drop policy if exists "items: family adds"    on public.archive_items;
drop policy if exists "items: family edits"   on public.archive_items;
drop policy if exists "items: family deletes" on public.archive_items;
create policy "items: family reads" on public.archive_items for select to authenticated
  using (public.is_member(family_id));
create policy "items: family adds" on public.archive_items for insert to authenticated
  with check (public.is_member(family_id));
create policy "items: family edits" on public.archive_items for update to authenticated
  using (public.is_member(family_id)) with check (public.is_member(family_id));
create policy "items: family deletes" on public.archive_items for delete to authenticated
  using (public.is_member(family_id));

-- ---------- private file storage ----------
insert into storage.buckets (id, name, public, file_size_limit)
values ('media', 'media', false, 52428800)
on conflict (id) do update set public = false, file_size_limit = 52428800;

-- (older single-family rules, if an earlier setup was run)
drop policy if exists "media: family reads"    on storage.objects;
drop policy if exists "media: editors upload"  on storage.objects;
drop policy if exists "media: editors delete"  on storage.objects;

drop policy if exists "media: own family reads"   on storage.objects;
drop policy if exists "media: own family uploads" on storage.objects;
drop policy if exists "media: own family deletes" on storage.objects;
create policy "media: own family reads" on storage.objects for select to authenticated
  using (bucket_id = 'media' and public.is_member_path(name));
create policy "media: own family uploads" on storage.objects for insert to authenticated
  with check (bucket_id = 'media' and public.is_member_path(name));
create policy "media: own family deletes" on storage.objects for delete to authenticated
  using (bucket_id = 'media' and public.is_member_path(name));

-- Live updates when someone else in the family adds or edits something.
do $$
begin
  alter publication supabase_realtime add table public.archive_items;
exception when duplicate_object then null;
end $$;
