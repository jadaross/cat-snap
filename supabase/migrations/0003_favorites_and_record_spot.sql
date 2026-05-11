-- ============================================================
-- 0003_favorites_and_record_spot
--
-- Pre-launch product changes (launch checklist Section 1):
--   1. Allow no-photo sightings (relaxes sightings.photo_url to nullable).
--   2. New table public.favorites + RLS for the heart toggle.
--   3. New RPC public.record_spot — no-photo "I spotted them" check-ins.
--   4. New RPC public.guide_list — multi-criteria cat-row guide.
--   5. Amended public.sightings_near — adds optional p_favorites_only flag
--      and an is_favorite column on every row.
--
-- Block-pair filtering: every read-side RPC filters symmetric blocks. To
-- make the symmetry actually work (the policy "Users see their own blocks"
-- in 0001 only exposes the calling user's outgoing blocks) the read RPCs
-- here are SECURITY DEFINER with `set search_path to 'public', 'pg_temp'`.
-- This brings sightings_near into line with that approach as we replace it.
-- ============================================================

-- ------------------------------------------------------------
-- 1. Allow no-photo sightings
-- ------------------------------------------------------------
alter table public.sightings alter column photo_url drop not null;

-- ------------------------------------------------------------
-- 2. favorites table
-- ------------------------------------------------------------
create table if not exists public.favorites (
  user_id    uuid not null references auth.users(id) on delete cascade,
  cat_id     uuid not null references public.cats(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (user_id, cat_id)
);

create index if not exists favorites_cat_id_idx on public.favorites(cat_id);

alter table public.favorites enable row level security;

drop policy if exists "Favorites readable by owner"   on public.favorites;
drop policy if exists "Favorites insertable by owner" on public.favorites;
drop policy if exists "Favorites deletable by owner"  on public.favorites;

create policy "Favorites readable by owner"
  on public.favorites for select
  using ((select auth.uid()) = user_id);

create policy "Favorites insertable by owner"
  on public.favorites for insert
  with check ((select auth.uid()) = user_id);

create policy "Favorites deletable by owner"
  on public.favorites for delete
  using ((select auth.uid()) = user_id);

-- ------------------------------------------------------------
-- 3. record_spot — no-photo check-in for an existing cat
-- ------------------------------------------------------------
create or replace function public.record_spot(
  p_cat_id         uuid,
  p_lat            double precision,
  p_lng            double precision,
  p_location_label text default null,
  p_seen_at        timestamptz default null
)
returns uuid
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_id      uuid;
begin
  if v_user_id is null then
    raise exception 'auth required' using errcode = '28000';
  end if;

  if p_cat_id is null then
    raise exception 'p_cat_id is required';
  end if;

  insert into public.sightings (user_id, cat_id, photo_url, location, location_label, seen_at)
  values (
    v_user_id,
    p_cat_id,
    null,
    st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography,
    nullif(trim(coalesce(p_location_label, '')), ''),
    coalesce(p_seen_at, now())
  )
  returning id into v_id;

  return v_id;
end;
$$;

revoke all on function public.record_spot(uuid, double precision, double precision, text, timestamptz) from public, anon;
grant execute on function public.record_spot(uuid, double precision, double precision, text, timestamptz) to authenticated;

-- ------------------------------------------------------------
-- 4. amend sightings_near — adds p_favorites_only + is_favorite column
-- The signature changes (extra trailing arg, extra return column) so we
-- drop the old function before recreating.
-- ------------------------------------------------------------
drop function if exists public.sightings_near(double precision, double precision, integer, integer);

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
    st_y(s.location::geometry) as lat,
    st_x(s.location::geometry) as lng,
    c.name              as cat_name,
    c.primary_photo_url as cat_photo_url,
    c.rarity            as cat_rarity,
    p.username,
    p.display_name,
    p.avatar_url,
    st_distance(s.location, st_makepoint(p_lng, p_lat)::geography) as distance_m,
    (fav.cat_id is not null) as is_favorite
  from public.sightings s
  left join public.cats c on c.id = s.cat_id
  left join public.profiles p on p.id = s.user_id
  left join public.favorites fav
    on fav.cat_id = s.cat_id
   and fav.user_id = (select auth.uid())
  where st_dwithin(
    s.location,
    st_makepoint(p_lng, p_lat)::geography,
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

revoke all on function public.sightings_near(double precision, double precision, integer, integer, boolean) from public;
grant execute on function public.sightings_near(double precision, double precision, integer, integer, boolean) to authenticated, anon;

-- ------------------------------------------------------------
-- 5. guide_list — one row per cat with per-user spotted/favorite state
-- and optional multi-criteria filtering (status, rarity, tags, time, area).
-- ------------------------------------------------------------
create or replace function public.guide_list(
  p_favorites_only  boolean   default false,
  p_status          text      default 'all',  -- 'all' | 'spotted' | 'not_spotted'
  p_rarities        text[]    default null,   -- null = no rarity filter
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
language sql stable
security definer
set search_path to 'public', 'pg_temp'
as $$
  with my_sightings as (
    -- per-cat: did *I* spot it, when last, what's my latest photo?
    select
      s.cat_id,
      max(s.seen_at) as last_seen_at,
      (array_agg(s.photo_url order by s.seen_at desc nulls last)
        filter (where s.photo_url is not null)
      )[1] as recent_photo_url
    from public.sightings s
    where s.user_id = (select auth.uid())
      and s.cat_id is not null
    group by s.cat_id
  ),
  near_matches as (
    -- per-cat: minimum distance to the reference point across any sighting
    -- (any user, blocks filtered). Empty when no location filter active.
    select
      s.cat_id,
      min(st_distance(s.location, st_makepoint(p_near_lng, p_near_lat)::geography)) as distance_m
    from public.sightings s
    where p_near_lat       is not null
      and p_near_lng       is not null
      and p_near_radius_m  is not null
      and s.cat_id is not null
      and st_dwithin(
        s.location,
        st_makepoint(p_near_lng, p_near_lat)::geography,
        p_near_radius_m
      )
      and not exists (
        select 1 from public.blocks b
        where (b.blocker_id = (select auth.uid()) and b.blocked_id = s.user_id)
           or (b.blocker_id = s.user_id and b.blocked_id = (select auth.uid()))
      )
    group by s.cat_id
  ),
  tag_matches as (
    -- cats with at least one sighting carrying any requested tag.
    -- Empty when no tag filter active.
    select distinct s.cat_id
    from public.sightings s
    join public.sighting_tags t on t.sighting_id = s.id
    where p_tags is not null
      and t.tag = any(p_tags)
      and s.cat_id is not null
      and not exists (
        select 1 from public.blocks b
        where (b.blocker_id = (select auth.uid()) and b.blocked_id = s.user_id)
           or (b.blocker_id = s.user_id and b.blocked_id = (select auth.uid()))
      )
  )
  select
    c.id                       as cat_id,
    c.name                     as cat_name,
    c.primary_photo_url        as primary_photo_url,
    c.rarity                   as rarity,
    (ms.cat_id is not null)    as is_spotted,
    (fav.cat_id is not null)   as is_favorite,
    ms.last_seen_at            as last_seen_at,
    coalesce(c.primary_photo_url, ms.recent_photo_url) as recent_photo_url,
    nm.distance_m              as distance_m
  from public.cats c
  left join my_sightings ms on ms.cat_id = c.id
  left join public.favorites fav
    on fav.cat_id = c.id
   and fav.user_id = (select auth.uid())
  left join near_matches nm on nm.cat_id = c.id
  where (
      not p_favorites_only
      or fav.cat_id is not null
    )
    and (
      p_status = 'all'
      or (p_status = 'spotted'     and ms.cat_id is not null)
      or (p_status = 'not_spotted' and ms.cat_id is null)
    )
    and (
      p_rarities is null
      or c.rarity = any(p_rarities)
    )
    and (
      p_tags is null
      or c.id in (select tm.cat_id from tag_matches tm)
    )
    and (
      (p_seen_after is null and p_seen_before is null)
      or exists (
        select 1
        from public.sightings s2
        where s2.cat_id = c.id
          and (p_seen_after  is null or s2.seen_at >= p_seen_after)
          and (p_seen_before is null or s2.seen_at <= p_seen_before)
          and not exists (
            select 1 from public.blocks b
            where (b.blocker_id = (select auth.uid()) and b.blocked_id = s2.user_id)
               or (b.blocker_id = s2.user_id and b.blocked_id = (select auth.uid()))
          )
      )
    )
    and (
      p_near_lat is null
      or p_near_lng is null
      or p_near_radius_m is null
      or nm.cat_id is not null
    )
  order by c.name asc;
$$;

revoke all on function public.guide_list(boolean, text, text[], text[], timestamptz, timestamptz, double precision, double precision, integer) from public;
grant execute on function public.guide_list(boolean, text, text[], text[], timestamptz, timestamptz, double precision, double precision, integer) to authenticated, anon;
