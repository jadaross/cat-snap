-- ============================================================
-- 0005_cat_search_and_cat_map
--
-- Two read-side RPCs, plus the indexes that make them fast.
--
--   search_cats        type-ahead over cats.name for the Submit form's NAME
--                      field, so a second sighting of "Marmalade" attaches to
--                      the existing cat instead of minting a duplicate. Until
--                      now the client had no way to look a cat up by name, so
--                      every tab-bar Snap created a brand-new row.
--
--   sightings_for_cat  every sighting of one cat, with lat/lng projected out
--                      of the geography column. Feeds the cat-profile
--                      territory map, its sightings grid, and its spotters
--                      list from a single round-trip.
--
-- Why sightings_near can't do the second job: it has no p_cat_id, it filters
-- by ST_DWithin around a centre, and it applies p_limit globally — so
-- filtering its results by cat client-side both misses cats outside the
-- radius and truncates unpredictably.
--
-- Why PostgREST can't do it either: sightings.location is geography(Point,
-- 4326) with no lat/lng columns, and a plain select returns it as WKB hex.
--
-- Conventions follow 0002/0003: security definer, pinned search_path, the
-- symmetric blocks filter every read RPC owes (see CLAUDE.md), revoke from
-- public then grant explicitly.
--
-- NOTE on LIKE escaping: search_profiles (0002) interpolates its argument
-- straight into a LIKE pattern, so a query of '%' matches every profile.
-- search_cats escapes \ % _ and passes an explicit ESCAPE. Don't copy 0002.
-- ============================================================

-- ------------------------------------------------------------
-- 1. Indexes
-- ------------------------------------------------------------

-- gin_trgm_ops supports the unanchored ILIKE that type-ahead needs; a plain
-- btree index can't be used for a leading-wildcard match.
create extension if not exists pg_trgm with schema extensions;

create index if not exists cats_name_trgm_idx
  on public.cats
  using gin (name extensions.gin_trgm_ops);

-- sightings_cat_id_idx already exists; this adds the seen_at ordering so the
-- per-cat read is a plain index scan.
create index if not exists sightings_cat_id_seen_at_idx
  on public.sightings (cat_id, seen_at desc);

-- ------------------------------------------------------------
-- 2. search_cats — NAME field type-ahead
-- ------------------------------------------------------------

create or replace function public.search_cats(
  p_query text,
  p_limit integer default 8
)
returns table (
  cat_id            uuid,
  cat_name          text,
  primary_photo_url text,
  rarity            text,
  sighting_count    bigint,
  last_seen_at      timestamptz,
  last_photo_url    text
)
language sql
stable
security definer
set search_path to 'public', 'pg_temp'
as $$
  with q as (
    select
      btrim(coalesce(p_query, '')) as raw,
      -- Backslash first, or it re-escapes the escapes.
      replace(
        replace(
          replace(btrim(coalesce(p_query, '')), '\', '\\'),
        '%', '\%'),
      '_', '\_') as esc
  ),
  matched as (
    select c.id, c.name, c.primary_photo_url, c.rarity
    from public.cats c
    cross join q
    -- Under two characters this matches most of the table, so short-circuit
    -- rather than let the client's first keystroke scan everything.
    where length(q.raw) >= 2
      and c.name is not null
      and c.name ilike '%' || q.esc || '%' escape '\'
      -- Cats carry no authored content of their own, but created_by is a
      -- person. Keep cats minted by someone in a block pair with the caller
      -- out of their suggestions, as every other read RPC would.
      and not exists (
        select 1 from public.blocks b
        where (b.blocker_id = (select auth.uid()) and b.blocked_id = c.created_by)
           or (b.blocker_id = c.created_by and b.blocked_id = (select auth.uid()))
      )
  ),
  agg as (
    select
      s.cat_id                         as agg_cat_id,
      count(*)::bigint                 as agg_count,
      max(s.seen_at)                   as agg_last_seen,
      (array_agg(s.photo_url order by s.seen_at desc nulls last)
         filter (where s.photo_url is not null))[1] as agg_last_photo
    from public.sightings s
    join matched m on m.id = s.cat_id
    where not exists (
      select 1 from public.blocks b
      where (b.blocker_id = (select auth.uid()) and b.blocked_id = s.user_id)
         or (b.blocker_id = s.user_id and b.blocked_id = (select auth.uid()))
    )
    group by s.cat_id
  )
  select
    m.id,
    m.name,
    m.primary_photo_url,
    m.rarity,
    coalesce(a.agg_count, 0),
    a.agg_last_seen,
    coalesce(m.primary_photo_url, a.agg_last_photo)
  from matched m
  cross join q
  left join agg a on a.agg_cat_id = m.id
  order by
    (lower(m.name) = lower(q.raw)) desc,              -- exact match wins
    (m.name ilike q.esc || '%' escape '\') desc,      -- then prefix
    coalesce(a.agg_count, 0) desc,                    -- then best-known
    m.name asc
  limit greatest(coalesce(p_limit, 8), 1);
$$;

revoke all on function public.search_cats(text, integer) from public;
grant execute on function public.search_cats(text, integer) to authenticated, anon;

comment on function public.search_cats is
  'Type-ahead over cats.name for the Submit form. Escapes LIKE metacharacters, applies the symmetric blocks filter, orders exact > prefix > most-spotted.';

-- ------------------------------------------------------------
-- 3. sightings_for_cat — one cat's sightings, with coordinates
-- ------------------------------------------------------------

create or replace function public.sightings_for_cat(
  p_cat_id uuid,
  p_limit  integer default 500
)
returns table (
  id             uuid,
  user_id        uuid,
  cat_id         uuid,
  photo_url      text,
  location_label text,
  notes          text,
  seen_at        timestamptz,
  created_at     timestamptz,
  lat            double precision,
  lng            double precision,
  username       text,
  display_name   text,
  avatar_url     text
)
language sql
stable
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
    s.created_at,
    -- location is NOT NULL, so these are never null.
    st_y(s.location::geometry) as lat,
    st_x(s.location::geometry) as lng,
    -- Left-joined: a deleted account can leave user_id dangling, and the row
    -- is still a real sighting of the cat.
    p.username,
    p.display_name,
    p.avatar_url
  from public.sightings s
  left join public.profiles p on p.id = s.user_id
  where s.cat_id = p_cat_id
    and not exists (
      select 1 from public.blocks b
      where (b.blocker_id = (select auth.uid()) and b.blocked_id = s.user_id)
         or (b.blocker_id = s.user_id and b.blocked_id = (select auth.uid()))
    )
  order by s.seen_at desc
  limit greatest(coalesce(p_limit, 500), 1);
$$;

revoke all on function public.sightings_for_cat(uuid, integer) from public;
grant execute on function public.sightings_for_cat(uuid, integer) to authenticated, anon;

comment on function public.sightings_for_cat is
  'All sightings of one cat with ST_Y/ST_X coordinates and the spotter profile. Replaces the plain PostgREST select behind the cat profile, which could return no usable coordinates and applied no block filter.';

-- ------------------------------------------------------------
-- 4. PostgREST schema cache
-- ------------------------------------------------------------
notify pgrst, 'reload schema';
