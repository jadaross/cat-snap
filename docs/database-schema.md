# Database Schema

Cat Snap uses **Supabase** (PostgreSQL with PostGIS extension) for all data storage.

---

## Tables

### `users`
Extends Supabase Auth's `auth.users` table with a public profile.

```sql
create table public.users (
  id          uuid primary key references auth.users(id) on delete cascade,
  username    text unique not null,
  display_name text,
  avatar_url  text,
  bio         text,
  city        text,
  created_at  timestamptz default now()
);
```

---

### `cats`
A cat profile, representing a unique individual street cat. Created when a user submits the first sighting of a cat, or when sightings are later merged.

```sql
create table public.cats (
  id            uuid primary key default gen_random_uuid(),
  created_by    uuid references public.users(id),
  name          text,                        -- community nickname, e.g. "Whiskers"
  description   text,
  primary_photo_url text,
  is_tnr        boolean default false,       -- trap-neuter-returned
  has_caretaker boolean default false,
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);
```

---

### `sightings`
Each time a user sees a cat and logs it. The core data unit of the app.

```sql
create table public.sightings (
  id          uuid primary key default gen_random_uuid(),
  cat_id      uuid references public.cats(id) on delete cascade,
  user_id     uuid references public.users(id) on delete set null,
  photo_url   text not null,
  location    geography(Point, 4326) not null,   -- PostGIS point (lng, lat)
  location_label text,                           -- human-readable address
  notes       text,
  visibility  text default 'public' check (visibility in ('public', 'friends', 'private')),
  seen_at     timestamptz default now(),
  created_at  timestamptz default now()
);

-- Spatial index for map queries
create index sightings_location_idx on public.sightings using gist(location);

-- Recent sightings index
create index sightings_seen_at_idx on public.sightings(seen_at desc);
```

---

### `sighting_tags`
Flexible tags on a sighting (friendly, shy, fluffy, orange tabby, etc.).

```sql
create table public.sighting_tags (
  id          uuid primary key default gen_random_uuid(),
  sighting_id uuid references public.sightings(id) on delete cascade,
  tag         text not null
);

create index sighting_tags_sighting_idx on public.sighting_tags(sighting_id);
create index sighting_tags_tag_idx on public.sighting_tags(tag);
```

---

### `friendships`
Bidirectional friend relationships with a pending/accepted state.

```sql
create table public.friendships (
  id          uuid primary key default gen_random_uuid(),
  requester_id uuid references public.users(id) on delete cascade,
  addressee_id uuid references public.users(id) on delete cascade,
  status      text default 'pending' check (status in ('pending', 'accepted', 'blocked')),
  created_at  timestamptz default now(),
  unique(requester_id, addressee_id)
);
```

---

### `cat_follows`
Users can follow specific cats to be notified of new sightings.

```sql
create table public.cat_follows (
  user_id   uuid references public.users(id) on delete cascade,
  cat_id    uuid references public.cats(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (user_id, cat_id)
);
```

---

### `reactions`
Emoji reactions on sightings.

```sql
create table public.reactions (
  id          uuid primary key default gen_random_uuid(),
  sighting_id uuid references public.sightings(id) on delete cascade,
  user_id     uuid references public.users(id) on delete cascade,
  emoji       text not null,   -- e.g. "❤️", "😮", "😂"
  created_at  timestamptz default now(),
  unique(sighting_id, user_id, emoji)
);
```

---

### `comments`
Comments on sightings.

```sql
create table public.comments (
  id          uuid primary key default gen_random_uuid(),
  sighting_id uuid references public.sightings(id) on delete cascade,
  user_id     uuid references public.users(id) on delete set null,
  body        text not null,
  created_at  timestamptz default now()
);
```

---

## Key Queries

### Cats near a location (map view)
```sql
select
  c.id, c.name, c.primary_photo_url,
  s.location, s.seen_at, s.location_label
from sightings s
join cats c on c.id = s.cat_id
where ST_DWithin(
  s.location,
  ST_MakePoint($lng, $lat)::geography,
  $radius_meters   -- e.g. 5000 for 5km
)
and s.seen_at > now() - interval '30 days'
order by s.seen_at desc;
```

### Friend activity feed
```sql
select s.*, c.name as cat_name, u.username, u.avatar_url
from sightings s
join cats c on c.id = s.cat_id
join users u on u.id = s.user_id
where s.user_id in (
  -- friends of the current user
  select case
    when requester_id = $my_id then addressee_id
    else requester_id
  end
  from friendships
  where (requester_id = $my_id or addressee_id = $my_id)
  and status = 'accepted'
)
and s.visibility in ('public', 'friends')
order by s.seen_at desc
limit 50;
```

### A cat's full sighting history
```sql
select s.*, u.username, u.avatar_url
from sightings s
join users u on u.id = s.user_id
where s.cat_id = $cat_id
order by s.seen_at desc;
```

---

## Storage Buckets (Supabase Storage)

| Bucket | Contents | Access |
|--------|----------|--------|
| `sighting-photos` | Cat photos from sightings | Public read, auth write |
| `avatars` | User profile photos | Public read, auth write |

---

## Row Level Security (RLS) Notes

- Sightings: `public` visibility → readable by all; `friends` → readable by confirmed friends; `private` → readable by owner only
- Users can only insert/update/delete their own sightings, reactions, comments
- Friendships: both parties can read; only requester can create; either party can update status or delete
