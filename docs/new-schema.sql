-- ============================================================
-- Cat-Snap iOS Rebuild — Initial Schema (v1)
-- Run this in the new Supabase project's SQL Editor.
--
-- Differences from legacy v1.0.2 schema (docs/legacy-schema.sql):
--   - "users" renamed to "profiles" (Supabase convention)
--   - "cat_id" on sightings is now NULLABLE — sightings exist without
--     being linked to a cat (you might log a sighting before deciding
--     it's the same as an existing cat)
--   - is_admin flag added to profiles for moderation features
--   - rarity column on cats (common/uncommon/rare/legendary) — design uses
--     this on cat profiles, badges, and feed items
--   - DEFERRED until v2 (not in this migration):
--       friendships, cat_follows, reactions, comments, merge_requests,
--       sighting visibility (public/friends/private), is_tnr/has_caretaker
--       on cats, badges, streaks. The design implies these exist; they're
--       intentionally cut from v1 to keep the first ship small. Add when
--       building the relevant feature.
-- ============================================================

-- 0. Extensions
create extension if not exists "postgis";
create extension if not exists "uuid-ossp";

-- ============================================================
-- 1. PROFILES — extends auth.users
-- ============================================================
create table public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  username      text unique not null,
  display_name  text,
  avatar_url    text,
  bio           text,
  is_admin      boolean default false,
  created_at    timestamptz default now()
);

-- Auto-create a profile when someone signs up
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  base_username text;
  final_username text;
  counter int := 0;
begin
  base_username := coalesce(
    new.raw_user_meta_data->>'username',
    split_part(new.email, '@', 1),
    'cat_lover'
  );
  base_username := lower(regexp_replace(base_username, '[^a-z0-9_]', '_', 'g'));
  base_username := substring(base_username, 1, 20);
  final_username := base_username;

  while exists (select 1 from public.profiles where username = final_username) loop
    counter := counter + 1;
    final_username := substring(base_username, 1, 17) || counter::text;
  end loop;

  insert into public.profiles (id, username, display_name, avatar_url)
  values (
    new.id,
    final_username,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name'),
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================================
-- 2. CATS — optional grouping for sightings
-- ============================================================
create table public.cats (
  id                uuid primary key default gen_random_uuid(),
  created_by        uuid references public.profiles(id) on delete set null,
  name              text,
  description       text,
  primary_photo_url text,
  rarity            text default 'common'
                    check (rarity in ('common', 'uncommon', 'rare', 'legendary')),
  created_at        timestamptz default now(),
  updated_at        timestamptz default now()
);

create index cats_rarity_idx on public.cats(rarity);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

create trigger cats_updated_at
  before update on public.cats
  for each row execute procedure public.set_updated_at();

-- ============================================================
-- 3. SIGHTINGS — the core record
-- cat_id is nullable: a sighting can exist before being linked to a cat
-- ============================================================
create table public.sightings (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references public.profiles(id) on delete cascade,
  cat_id          uuid references public.cats(id) on delete set null,
  photo_url       text not null,
  location        geography(Point, 4326) not null,
  location_label  text,
  notes           text,
  seen_at         timestamptz default now(),
  created_at      timestamptz default now()
);

create index sightings_location_idx on public.sightings using gist(location);
create index sightings_cat_id_idx   on public.sightings(cat_id);
create index sightings_user_id_idx  on public.sightings(user_id);
create index sightings_seen_at_idx  on public.sightings(seen_at desc);

-- ============================================================
-- 4. SIGHTING TAGS
-- Flat tags on a sighting (e.g. "friendly", "shy", "orange tabby")
-- ============================================================
create table public.sighting_tags (
  sighting_id uuid not null references public.sightings(id) on delete cascade,
  tag         text not null,
  primary key (sighting_id, tag)
);

create index sighting_tags_tag_idx on public.sighting_tags(tag);

-- ============================================================
-- 5. RPC: sightings_near
-- Called from the iOS map view to fetch pins in the visible region
-- ============================================================
create or replace function public.sightings_near(
  p_lat    double precision,
  p_lng    double precision,
  p_radius integer default 5000,
  p_limit  integer default 200
)
returns table (
  id              uuid,
  user_id         uuid,
  cat_id          uuid,
  photo_url       text,
  location_label  text,
  notes           text,
  seen_at         timestamptz,
  lat             double precision,
  lng             double precision,
  cat_name        text,
  cat_photo_url   text,
  cat_rarity      text,
  username        text,
  display_name    text,
  avatar_url      text,
  distance_m      double precision
)
language sql stable as $$
  select
    s.id,
    s.user_id,
    s.cat_id,
    s.photo_url,
    s.location_label,
    s.notes,
    s.seen_at,
    ST_Y(s.location::geometry) as lat,
    ST_X(s.location::geometry) as lng,
    c.name              as cat_name,
    c.primary_photo_url as cat_photo_url,
    c.rarity            as cat_rarity,
    p.username,
    p.display_name,
    p.avatar_url,
    ST_Distance(s.location, ST_MakePoint(p_lng, p_lat)::geography) as distance_m
  from public.sightings s
  left join public.cats c on c.id = s.cat_id
  left join public.profiles p on p.id = s.user_id
  where ST_DWithin(
    s.location,
    ST_MakePoint(p_lng, p_lat)::geography,
    p_radius
  )
  order by s.seen_at desc
  limit p_limit;
$$;

-- ============================================================
-- 6. ROW LEVEL SECURITY
-- ============================================================

-- Profiles
alter table public.profiles enable row level security;
create policy "Profiles are viewable by everyone" on public.profiles
  for select using (true);
create policy "Users can update their own profile" on public.profiles
  for update using (auth.uid() = id);

-- Cats
alter table public.cats enable row level security;
create policy "Cats are viewable by everyone" on public.cats
  for select using (true);
create policy "Authenticated users can create cats" on public.cats
  for insert with check (auth.uid() is not null);
create policy "Creators can update their cats" on public.cats
  for update using (auth.uid() = created_by);
create policy "Admins can delete cats" on public.cats
  for delete using (
    exists (select 1 from public.profiles where id = auth.uid() and is_admin = true)
  );

-- Sightings
alter table public.sightings enable row level security;
create policy "Sightings are viewable by everyone" on public.sightings
  for select using (true);
create policy "Authenticated users can create sightings" on public.sightings
  for insert with check (auth.uid() = user_id);
create policy "Users can update their own sightings" on public.sightings
  for update using (auth.uid() = user_id);
create policy "Users and admins can delete sightings" on public.sightings
  for delete using (
    auth.uid() = user_id
    or exists (select 1 from public.profiles where id = auth.uid() and is_admin = true)
  );

-- Sighting tags
alter table public.sighting_tags enable row level security;
create policy "Tags viewable by everyone" on public.sighting_tags
  for select using (true);
create policy "Sighting owner can add tags" on public.sighting_tags
  for insert with check (
    exists (select 1 from public.sightings where id = sighting_id and user_id = auth.uid())
  );
create policy "Sighting owner can delete tags" on public.sighting_tags
  for delete using (
    exists (select 1 from public.sightings where id = sighting_id and user_id = auth.uid())
  );

-- ============================================================
-- 7. STORAGE BUCKETS
-- Create these via the Supabase Dashboard (Storage → New bucket):
--   - sighting-photos  (public read, authenticated write)
--   - avatars          (public read, authenticated write)
-- After creating, add storage policies in the Dashboard:
--   sighting-photos:
--     SELECT: true
--     INSERT: auth.role() = 'authenticated'
--     UPDATE/DELETE: owner = auth.uid()
-- ============================================================
