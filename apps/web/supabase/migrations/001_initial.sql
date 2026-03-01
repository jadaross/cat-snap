-- ============================================================
-- Cat Snap — Initial Database Migration
-- Run this in the Supabase SQL editor (Dashboard → SQL Editor)
-- ============================================================

-- 0. Enable required extensions
create extension if not exists "postgis";
create extension if not exists "uuid-ossp";

-- ============================================================
-- 1. USERS
-- Public profile that extends Supabase Auth's auth.users table
-- ============================================================
create table public.users (
  id            uuid primary key references auth.users(id) on delete cascade,
  username      text unique not null,
  display_name  text,
  avatar_url    text,
  bio           text,
  city          text,
  created_at    timestamptz default now()
);

-- Auto-create a user profile when someone signs up
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  base_username text;
  final_username text;
  counter int := 0;
begin
  -- Prefer metadata username > email prefix > random
  base_username := coalesce(
    new.raw_user_meta_data->>'username',
    split_part(new.email, '@', 1),
    'cat_lover'
  );
  -- Sanitise: lowercase, only alphanum + underscore, max 20 chars
  base_username := lower(regexp_replace(base_username, '[^a-z0-9_]', '_', 'g'));
  base_username := substring(base_username, 1, 20);
  final_username := base_username;

  -- Ensure uniqueness
  while exists (select 1 from public.users where username = final_username) loop
    counter := counter + 1;
    final_username := substring(base_username, 1, 17) || counter::text;
  end loop;

  insert into public.users (id, username, display_name, avatar_url)
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
-- 2. CATS
-- ============================================================
create table public.cats (
  id                uuid primary key default gen_random_uuid(),
  created_by        uuid references public.users(id) on delete set null,
  name              text,
  description       text,
  primary_photo_url text,
  is_tnr            boolean default false,
  has_caretaker     boolean default false,
  created_at        timestamptz default now(),
  updated_at        timestamptz default now()
);

-- Auto-update updated_at
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

create trigger cats_updated_at
  before update on public.cats
  for each row execute procedure public.set_updated_at();

-- ============================================================
-- 3. SIGHTINGS
-- ============================================================
create table public.sightings (
  id              uuid primary key default gen_random_uuid(),
  cat_id          uuid not null references public.cats(id) on delete cascade,
  user_id         uuid references public.users(id) on delete set null,
  photo_url       text not null,
  location        geography(Point, 4326) not null,
  location_label  text,
  notes           text,
  visibility      text default 'public' check (visibility in ('public', 'friends', 'private')),
  seen_at         timestamptz default now(),
  created_at      timestamptz default now()
);

create index sightings_location_idx on public.sightings using gist(location);
create index sightings_cat_id_idx   on public.sightings(cat_id);
create index sightings_user_id_idx  on public.sightings(user_id);
create index sightings_seen_at_idx  on public.sightings(seen_at desc);

-- ============================================================
-- 4. SIGHTING TAGS
-- ============================================================
create table public.sighting_tags (
  id          uuid primary key default gen_random_uuid(),
  sighting_id uuid not null references public.sightings(id) on delete cascade,
  tag         text not null
);

create index sighting_tags_sighting_idx on public.sighting_tags(sighting_id);
create index sighting_tags_tag_idx      on public.sighting_tags(tag);

-- ============================================================
-- 5. FRIENDSHIPS
-- ============================================================
create table public.friendships (
  id            uuid primary key default gen_random_uuid(),
  requester_id  uuid not null references public.users(id) on delete cascade,
  addressee_id  uuid not null references public.users(id) on delete cascade,
  status        text default 'pending' check (status in ('pending', 'accepted', 'blocked')),
  created_at    timestamptz default now(),
  unique(requester_id, addressee_id)
);

create index friendships_requester_idx on public.friendships(requester_id);
create index friendships_addressee_idx on public.friendships(addressee_id);

-- ============================================================
-- 6. CAT FOLLOWS
-- ============================================================
create table public.cat_follows (
  user_id    uuid not null references public.users(id) on delete cascade,
  cat_id     uuid not null references public.cats(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (user_id, cat_id)
);

-- ============================================================
-- 7. REACTIONS
-- ============================================================
create table public.reactions (
  id          uuid primary key default gen_random_uuid(),
  sighting_id uuid not null references public.sightings(id) on delete cascade,
  user_id     uuid not null references public.users(id) on delete cascade,
  emoji       text not null,
  created_at  timestamptz default now(),
  unique(sighting_id, user_id, emoji)
);

create index reactions_sighting_idx on public.reactions(sighting_id);

-- ============================================================
-- 8. COMMENTS
-- ============================================================
create table public.comments (
  id          uuid primary key default gen_random_uuid(),
  sighting_id uuid not null references public.sightings(id) on delete cascade,
  user_id     uuid references public.users(id) on delete set null,
  body        text not null,
  created_at  timestamptz default now()
);

create index comments_sighting_idx on public.comments(sighting_id);

-- ============================================================
-- 9. RPC: sightings_near
-- Called from /api/sightings?lat=&lng=&radius=
-- ============================================================
create or replace function public.sightings_near(
  p_lat    double precision,
  p_lng    double precision,
  p_radius integer default 5000,
  p_limit  integer default 50
)
returns table (
  id              uuid,
  cat_id          uuid,
  user_id         uuid,
  photo_url       text,
  location_label  text,
  notes           text,
  visibility      text,
  seen_at         timestamptz,
  cat_name        text,
  cat_photo_url   text,
  username        text,
  display_name    text,
  avatar_url      text,
  distance_m      double precision
)
language sql stable as $$
  select
    s.id,
    s.cat_id,
    s.user_id,
    s.photo_url,
    s.location_label,
    s.notes,
    s.visibility,
    s.seen_at,
    c.name        as cat_name,
    c.primary_photo_url as cat_photo_url,
    u.username,
    u.display_name,
    u.avatar_url,
    ST_Distance(s.location, ST_MakePoint(p_lng, p_lat)::geography) as distance_m
  from public.sightings s
  join public.cats c on c.id = s.cat_id
  left join public.users u on u.id = s.user_id
  where
    s.visibility = 'public'
    and ST_DWithin(
      s.location,
      ST_MakePoint(p_lng, p_lat)::geography,
      p_radius
    )
  order by s.seen_at desc
  limit p_limit;
$$;

-- ============================================================
-- 10. ROW LEVEL SECURITY
-- ============================================================

-- Users
alter table public.users enable row level security;
create policy "Public profiles are viewable by everyone" on public.users for select using (true);
create policy "Users can update their own profile" on public.users for update using (auth.uid() = id);

-- Cats
alter table public.cats enable row level security;
create policy "Cats are viewable by everyone" on public.cats for select using (true);
create policy "Authenticated users can create cats" on public.cats for insert with check (auth.uid() is not null);
create policy "Creators can update their cats" on public.cats for update using (auth.uid() = created_by);

-- Sightings
alter table public.sightings enable row level security;
create policy "Public sightings viewable by everyone" on public.sightings
  for select using (visibility = 'public');
create policy "Authenticated users can create sightings" on public.sightings
  for insert with check (auth.uid() is not null);
create policy "Users can update their sightings" on public.sightings
  for update using (auth.uid() = user_id);
create policy "Users can delete their sightings" on public.sightings
  for delete using (auth.uid() = user_id);

-- Sighting tags
alter table public.sighting_tags enable row level security;
create policy "Tags viewable by everyone" on public.sighting_tags for select using (true);
create policy "Auth users can add tags" on public.sighting_tags for insert with check (auth.uid() is not null);

-- Friendships
alter table public.friendships enable row level security;
create policy "Users can view their own friendships" on public.friendships
  for select using (auth.uid() = requester_id or auth.uid() = addressee_id);
create policy "Users can send friend requests" on public.friendships
  for insert with check (auth.uid() = requester_id);
create policy "Users can update their friendships" on public.friendships
  for update using (auth.uid() = requester_id or auth.uid() = addressee_id);
create policy "Users can delete their friendships" on public.friendships
  for delete using (auth.uid() = requester_id or auth.uid() = addressee_id);

-- Cat follows
alter table public.cat_follows enable row level security;
create policy "Cat follows viewable by everyone" on public.cat_follows for select using (true);
create policy "Auth users can follow cats" on public.cat_follows for insert with check (auth.uid() = user_id);
create policy "Users can unfollow cats" on public.cat_follows for delete using (auth.uid() = user_id);

-- Reactions
alter table public.reactions enable row level security;
create policy "Reactions viewable by everyone" on public.reactions for select using (true);
create policy "Auth users can react" on public.reactions for insert with check (auth.uid() = user_id);
create policy "Users can remove their reactions" on public.reactions for delete using (auth.uid() = user_id);

-- Comments
alter table public.comments enable row level security;
create policy "Comments viewable by everyone" on public.comments for select using (true);
create policy "Auth users can comment" on public.comments for insert with check (auth.uid() = user_id);
create policy "Users can delete their comments" on public.comments for delete using (auth.uid() = user_id);

-- ============================================================
-- 11. STORAGE BUCKETS
-- (Create these in Supabase Dashboard → Storage, or via CLI)
-- ============================================================
-- bucket: sighting-photos  (public)
-- bucket: avatars          (public)
