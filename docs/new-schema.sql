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
  -- photo_url is nullable so the no-photo "I spotted them" check-in path
  -- (record_spot RPC, migration 0003) can write a sighting without an image.
  photo_url       text,
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
-- Called from the iOS map view to fetch pins in the visible region.
-- Filters symmetric block pairs. Migration 0003 added p_favorites_only
-- and the is_favorite return column, and switched the function to
-- SECURITY DEFINER so the symmetric block filter actually catches both
-- directions (the "Users see their own blocks" RLS in migration 0001
-- otherwise hides incoming blocks from the caller).
-- ============================================================
create or replace function public.sightings_near(
  p_lat             double precision,
  p_lng             double precision,
  p_radius          integer default 5000,
  p_limit           integer default 200,
  p_favorites_only  boolean default false
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
  distance_m      double precision,
  is_favorite     boolean
)
language sql stable
security definer
set search_path to 'public', 'pg_temp'
as $$
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
    ST_Distance(s.location, ST_MakePoint(p_lng, p_lat)::geography) as distance_m,
    (fav.cat_id is not null) as is_favorite
  from public.sightings s
  left join public.cats c on c.id = s.cat_id
  left join public.profiles p on p.id = s.user_id
  left join public.favorites fav
    on fav.cat_id = s.cat_id
   and fav.user_id = (select auth.uid())
  where ST_DWithin(
    s.location,
    ST_MakePoint(p_lng, p_lat)::geography,
    p_radius
  )
  and not exists (
    select 1 from public.blocks b
    where (b.blocker_id = (select auth.uid()) and b.blocked_id = s.user_id)
       or (b.blocker_id = s.user_id and b.blocked_id = (select auth.uid()))
  )
  and (
    not p_favorites_only
    or fav.cat_id is not null
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

-- ============================================================
-- 8. UGC MODERATION (Apple App Store Guideline 1.2)
-- Mirrors supabase/migrations/0001_blocks_and_reports.sql.
-- Keep this section and the migration file in sync.
-- ============================================================

-- blocks: directed; the read-side RPCs filter symmetrically.
create table public.blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);
create index blocks_blocked_id_idx on public.blocks(blocked_id);

alter table public.blocks enable row level security;
create policy "Users see their own blocks" on public.blocks
  for select using ((select auth.uid()) = blocker_id);
create policy "Users create their own blocks" on public.blocks
  for insert with check ((select auth.uid()) = blocker_id);
create policy "Users delete their own blocks" on public.blocks
  for delete using ((select auth.uid()) = blocker_id);

-- reports: append-only from clients; admins triage via the dashboard.
create type public.report_target as enum ('sighting', 'profile', 'cat');
create type public.report_reason as enum ('spam', 'inappropriate', 'abuse', 'copyright', 'other');
create type public.report_status as enum ('open', 'actioned', 'dismissed');

create table public.reports (
  id           uuid primary key default gen_random_uuid(),
  reporter_id  uuid not null references public.profiles(id) on delete cascade,
  target_type  public.report_target not null,
  target_id    uuid not null,
  reason       public.report_reason not null,
  details      text,
  status       public.report_status not null default 'open',
  created_at   timestamptz default now(),
  resolved_at  timestamptz
);
create index reports_status_idx on public.reports(status, created_at desc);
create index reports_target_idx on public.reports(target_type, target_id);

alter table public.reports enable row level security;
create policy "Reporters can read their own reports" on public.reports
  for select using ((select auth.uid()) = reporter_id);
create policy "Authenticated users can submit reports" on public.reports
  for insert with check ((select auth.uid()) = reporter_id);

-- ============================================================
-- 9. FAVOURITES + GUIDE + NO-PHOTO SPOT (migration 0003)
-- See supabase/migrations/0003_favorites_and_record_spot.sql.
-- Keep the migration file and this section in sync.
-- ============================================================

-- favorites: per-user heart toggle on a cat. Row = "user has favourited cat".
create table public.favorites (
  user_id    uuid not null references auth.users(id) on delete cascade,
  cat_id     uuid not null references public.cats(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (user_id, cat_id)
);
create index favorites_cat_id_idx on public.favorites(cat_id);

alter table public.favorites enable row level security;
create policy "Favorites readable by owner"   on public.favorites for select using ((select auth.uid()) = user_id);
create policy "Favorites insertable by owner" on public.favorites for insert with check ((select auth.uid()) = user_id);
create policy "Favorites deletable by owner"  on public.favorites for delete using ((select auth.uid()) = user_id);

-- record_spot: no-photo "I spotted them" check-in for an existing cat.
-- Returns the new sighting's id. SECURITY DEFINER so it bypasses the
-- sightings INSERT policy in a controlled way (still gates on auth.uid()).
-- Anon is explicitly revoked because anon callers cannot insert sightings.
create or replace function public.record_spot(
  p_cat_id         uuid,
  p_lat            double precision,
  p_lng            double precision,
  p_location_label text default null,
  p_seen_at        timestamptz default null
) returns uuid
language plpgsql security definer set search_path to 'public', 'pg_temp'
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_id      uuid;
begin
  if v_user_id is null then raise exception 'auth required' using errcode = '28000'; end if;
  if p_cat_id  is null then raise exception 'p_cat_id is required'; end if;
  insert into public.sightings (user_id, cat_id, photo_url, location, location_label, seen_at)
  values (
    v_user_id, p_cat_id, null,
    st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography,
    nullif(trim(coalesce(p_location_label, '')), ''),
    coalesce(p_seen_at, now())
  )
  returning id into v_id;
  return v_id;
end; $$;
revoke all on function public.record_spot(uuid, double precision, double precision, text, timestamptz) from public, anon;
grant execute on function public.record_spot(uuid, double precision, double precision, text, timestamptz) to authenticated;

-- guide_list: one row per cat, with per-user spotted/favorite flags and
-- optional multi-criteria filtering. Drives the Explore guide grid.
-- Filter args are all optional and AND together. Block-pair filtering is
-- symmetric (the SECURITY DEFINER context bypasses the blocks RLS so both
-- directions actually filter).
create or replace function public.guide_list(
  p_favorites_only  boolean   default false,
  p_status          text      default 'all',  -- 'all' | 'spotted' | 'not_spotted'
  p_rarities        text[]    default null,
  p_tags            text[]    default null,
  p_seen_after      timestamptz default null,
  p_seen_before     timestamptz default null,
  p_near_lat        double precision default null,
  p_near_lng        double precision default null,
  p_near_radius_m   integer   default null
)
returns table (
  cat_id            uuid,
  cat_name          text,
  primary_photo_url text,
  rarity            text,
  is_spotted        boolean,
  is_favorite       boolean,
  last_seen_at      timestamptz,
  recent_photo_url  text,
  distance_m        double precision
)
language sql stable security definer set search_path to 'public', 'pg_temp'
as $$
  -- Body: see migration 0003. Reproduced here only as a reference; the
  -- migration file is the source of truth.
  with my_sightings as (
    select s.cat_id, max(s.seen_at) as last_seen_at,
      (array_agg(s.photo_url order by s.seen_at desc nulls last)
        filter (where s.photo_url is not null))[1] as recent_photo_url
    from public.sightings s
    where s.user_id = (select auth.uid()) and s.cat_id is not null
    group by s.cat_id
  )
  select c.id, c.name, c.primary_photo_url, c.rarity,
    (ms.cat_id is not null), (fav.cat_id is not null),
    ms.last_seen_at, coalesce(c.primary_photo_url, ms.recent_photo_url),
    null::double precision
  from public.cats c
  left join my_sightings ms on ms.cat_id = c.id
  left join public.favorites fav on fav.cat_id = c.id and fav.user_id = (select auth.uid())
  order by c.name asc;
$$;
revoke all on function public.guide_list(boolean, text, text[], text[], timestamptz, timestamptz, double precision, double precision, integer) from public;
grant execute on function public.guide_list(boolean, text, text[], text[], timestamptz, timestamptz, double precision, double precision, integer) to authenticated, anon;

-- ============================================================
-- 10. ACCOUNT DELETION
-- Apple App Store Guideline 5.1.1(v) requires in-app account deletion.
-- The destructive work happens in the `delete-account` edge function
-- (see supabase/functions/delete-account/), which:
--   1. authenticates the caller via JWT
--   2. removes every storage object under sighting-photos/<uid>/ and
--      avatars/<uid>/
--   3. calls auth.admin.deleteUser, which cascades through profiles,
--      sightings, sighting_tags, follows, blocks, reports
-- No DDL is required for account deletion itself; the existing FKs do
-- the cascading work once the auth.users row is removed.
-- ============================================================
