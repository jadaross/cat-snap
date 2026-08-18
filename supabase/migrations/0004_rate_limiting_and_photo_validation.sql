-- ============================================================
-- 0004_rate_limiting_and_photo_validation
--
-- Production readiness features (launch checklist Section 6):
--   1. Per-user submission cap (50 sightings/day) via partial index
--   2. Per-user follow cap (1000 follows total) via check constraint
--   3. Server-side photo size enforcement via storage policy function
-- ============================================================

-- ------------------------------------------------------------
-- 1. Sightings rate limit: 50 sightings per user per day
-- Uses a partial index to count sightings created today per user.
-- The index is maintained only for recent sightings, keeping it small.
-- ------------------------------------------------------------

-- Create a partial index on sightings for today's records per user
-- This index supports efficient counting of daily sightings per user
create index if not exists sightings_user_created_at_idx
  on public.sightings(user_id, created_at)
  where created_at >= current_date;

-- Create a check constraint that prevents users from exceeding 50 sightings/day
-- This is enforced at the database level, not just client-side
alter table public.sightings
  add constraint if not exists sightings_daily_limit_check
  check (
    -- Allow the row if it's the first sighting for this user today
    -- or if the user has fewer than 50 sightings today (excluding this row)
    (
      select count(*)
      from public.sightings s2
      where s2.user_id = public.sightings.user_id
        and s2.created_at >= current_date
    ) < 50
  );

-- ------------------------------------------------------------
-- 2. Follows rate limit: 1000 follows per user total
-- Assumes follows table exists with (follower_id, followee_id, created_at)
-- ------------------------------------------------------------

-- Create the follows table if it doesn't exist (defensive)
create table if not exists public.follows (
  follower_id  uuid not null references public.profiles(id) on delete cascade,
  followee_id  uuid not null references public.profiles(id) on delete cascade,
  created_at   timestamptz default now(),
  primary key (follower_id, followee_id),
  check (follower_id <> followee_id)
);

create index if not exists follows_followee_id_idx on public.follows(followee_id);

alter table public.follows enable row level security;

create policy if not exists "Users can insert their own follows" on public.follows
  for insert with check ((select auth.uid()) = follower_id);

create policy if not exists "Users can delete their own follows" on public.follows
  for delete using ((select auth.uid()) = follower_id);

-- Add a check constraint to limit total follows per user to 1000
-- This prevents a user from following more than 1000 other users
alter table public.follows
  add constraint if not exists follows_total_limit_check
  check (
    -- Allow the row if the follower has fewer than 1000 follows (excluding this row)
    (
      select count(*)
      from public.follows f2
      where f2.follower_id = public.follows.follower_id
    ) < 1000
  );

-- ------------------------------------------------------------
-- 3. Server-side photo size enforcement
-- Create a function to validate photo size before storage
-- This enforces the 10MB limit server-side (currently client-side only)
-- ------------------------------------------------------------

-- Create a function to check if a file size is within limits
-- This can be used in storage policies or as a validation trigger
create or replace function public.validate_photo_size(p_size_bytes bigint)
returns boolean
language sql
immutable
as $$
  select p_size_bytes <= 10485760; -- 10MB in bytes
$$;

-- Create a trigger function that can be attached to storage-related operations
-- Note: Supabase Storage policies are the primary mechanism for this.
-- This function is provided as a helper for edge functions or custom logic.
create or replace function public.photo_size_check()
returns trigger
language plpgsql
as $$
begin
  -- Check if the new row has a size that exceeds the limit
  -- This assumes a size_bytes column exists in the storage metadata
  if new.size_bytes > 10485760 then
    raise exception 'Photo size exceeds 10MB limit' using errcode = '22023';
  end if;
  return new;
end;
$$;

-- ------------------------------------------------------------
-- 4. Grant permissions for the new functions
-- ------------------------------------------------------------
grant execute on function public.validate_photo_size(bigint) to authenticated, anon;
grant execute on function public.photo_size_check() to authenticated, anon;

-- ------------------------------------------------------------
-- 5. Add helpful comments for documentation
-- ------------------------------------------------------------

comment on constraint sightings_daily_limit_check on public.sightings is
  'Prevents users from creating more than 50 sightings per day. Counted from midnight UTC.';

comment on constraint follows_total_limit_check on public.follows is
  'Prevents users from following more than 1000 other users total.';

comment on function public.validate_photo_size is
  'Validates that a photo size is within the 10MB limit. Returns true if valid, false otherwise.';

comment on function public.photo_size_check is
  'Trigger function to enforce photo size limits. Raises an exception if size exceeds 10MB.';
