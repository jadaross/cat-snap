-- ============================================================
-- 0001_blocks_and_reports
-- App Store review gate (Guideline 1.2): UGC apps need block + report.
-- ============================================================

-- ------------------------------------------------------------
-- blocks: directed table; the app filters symmetrically through
-- the RPCs amended in 0002, so neither party sees the other.
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- reports: append-only from clients, triaged by admins via dashboard.
-- ------------------------------------------------------------
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

-- Admin read/triage happens via the service role (no client policy needed).
