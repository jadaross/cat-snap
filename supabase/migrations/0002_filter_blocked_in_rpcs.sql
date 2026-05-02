-- ============================================================
-- 0002_filter_blocked_in_rpcs
-- Amend the four read-side RPCs so blocked pairs disappear from each
-- other. Symmetry: a row is hidden if EITHER party blocked the OTHER.
-- Write RPCs (e.g. create_sighting_with_cat) are intentionally untouched.
-- ============================================================

-- ------------------------------------------------------------
-- sightings_near — map fetch
-- ------------------------------------------------------------
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
language sql stable
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
    ST_Distance(s.location, ST_MakePoint(p_lng, p_lat)::geography) as distance_m
  from public.sightings s
  left join public.cats c on c.id = s.cat_id
  left join public.profiles p on p.id = s.user_id
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
  order by s.seen_at desc
  limit p_limit;
$$;

-- ------------------------------------------------------------
-- friend_activity — friends feed
-- ------------------------------------------------------------
create or replace function public.friend_activity(p_limit integer default 50)
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
language sql stable
set search_path to 'public', 'pg_temp'
as $$
  select
    s.id,
    s.user_id,
    s.cat_id,
    s.photo_url::text,
    s.location_label,
    s.notes,
    s.seen_at,
    st_y(s.location::geometry) as lat,
    st_x(s.location::geometry) as lng,
    c.name as cat_name,
    c.primary_photo_url::text as cat_photo_url,
    c.rarity::text as cat_rarity,
    p.username,
    p.display_name,
    p.avatar_url::text,
    0::double precision as distance_m
  from public.sightings s
  join public.follows f on f.followee_id = s.user_id
  left join public.cats c on c.id = s.cat_id
  left join public.profiles p on p.id = s.user_id
  where f.follower_id = (select auth.uid())
    and not exists (
      select 1 from public.blocks b
      where (b.blocker_id = (select auth.uid()) and b.blocked_id = s.user_id)
         or (b.blocker_id = s.user_id and b.blocked_id = (select auth.uid()))
    )
  order by s.seen_at desc
  limit p_limit;
$$;

-- ------------------------------------------------------------
-- my_friends — list of people I follow
-- A friend who blocked me (or whom I blocked) shouldn't appear here.
-- ------------------------------------------------------------
create or replace function public.my_friends()
returns table (
  user_id      uuid,
  username     text,
  display_name text,
  avatar_url   text,
  followed_at  timestamptz
)
language sql stable
set search_path to 'public', 'pg_temp'
as $$
  select
    p.id as user_id,
    p.username,
    p.display_name,
    p.avatar_url::text,
    f.created_at as followed_at
  from public.follows f
  join public.profiles p on p.id = f.followee_id
  where f.follower_id = (select auth.uid())
    and not exists (
      select 1 from public.blocks b
      where (b.blocker_id = (select auth.uid()) and b.blocked_id = p.id)
         or (b.blocker_id = p.id and b.blocked_id = (select auth.uid()))
    )
  order by f.created_at desc;
$$;

-- ------------------------------------------------------------
-- search_profiles — Add Friends search
-- ------------------------------------------------------------
create or replace function public.search_profiles(p_query text, p_limit integer default 20)
returns table (
  user_id      uuid,
  username     text,
  display_name text,
  avatar_url   text,
  is_following boolean
)
language sql stable
set search_path to 'public', 'pg_temp'
as $$
  select
    p.id as user_id,
    p.username,
    p.display_name,
    p.avatar_url::text,
    exists (
      select 1
      from public.follows f
      where f.follower_id = (select auth.uid()) and f.followee_id = p.id
    ) as is_following
  from public.profiles p
  where p.id <> coalesce((select auth.uid()), '00000000-0000-0000-0000-000000000000'::uuid)
    and (
      p.username ilike '%' || p_query || '%'
      or coalesce(p.display_name, '') ilike '%' || p_query || '%'
    )
    and not exists (
      select 1 from public.blocks b
      where (b.blocker_id = (select auth.uid()) and b.blocked_id = p.id)
         or (b.blocker_id = p.id and b.blocked_id = (select auth.uid()))
    )
  order by p.username
  limit p_limit;
$$;
