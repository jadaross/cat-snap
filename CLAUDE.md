# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Cat-Snap is a native SwiftUI iOS app (iOS 17+) for spotting and tracking street cats. The repo also holds the design spec, brand reference, and database schema. Backend is Supabase (Postgres + PostGIS + Auth + Storage) — project ID `wgtjtvxpxalyeukgxbpo` in eu-central-2 (Zurich).

The previous Next.js web app was retired and lives at git tag `v1.0.2-web-final`. The iOS rebuild started fresh — new Supabase project, new schema, new branding.

The canonical roadmap is `docs/ios-rebuild.md`. Phase 2 (auth + first round-trip) is done and on `main`. Phase 3 (MVP: map, submit-sighting, profiles) is next.

## Build & run

- **Normal flow**: open `CatSnap/CatSnap.xcodeproj` in Xcode and press ⌘R. The Xcode project lives one level deep inside a wrapper `CatSnap/` folder, not at the repo root.
- **CLI build** (occasional, e.g. CI smoke check):
  ```
  xcodebuild -project CatSnap/CatSnap.xcodeproj -scheme CatSnap \
    -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
  ```
- No tests are written yet. The test target was scaffolded but is empty.

## Layout that isn't obvious from the file tree

- The Xcode project's source folders (`Core/`, `Features/`, `Resources/`) are **synchronized folder references** (yellow folders in Xcode 16+). Files written into them on disk auto-appear in the build — no drag-into-Xcode step needed when adding new Swift files.
- Sub-folders by intent: `Core/UI/` (brand primitives), `Core/Supabase/` (client + auth session), `Core/Models/` (Codable structs), `Features/<Feature>/` (per-feature views and view models).
- `docs/new-schema.sql` is the authoritative DB schema. Models in `Core/Models/` mirror it field-for-field with snake_case `CodingKeys`.

## Supabase wiring

- A module-level `let supabase: SupabaseClient` is defined in `Core/Supabase/SupabaseClient.swift`. Don't make a second one — call it directly from anywhere.
- `SUPABASE_URL` and `SUPABASE_ANON_KEY` flow at runtime from `CatSnap/CatSnap/CatSnap.xcconfig` (gitignored) → Info.plist `$(VAR)` substitution → `Bundle.main.object(forInfoDictionaryKey:)`. The `.example.xcconfig` next to it is the committed template.
- The xcconfig file lives inside the synced source folder so Xcode picks it up automatically; if it ever moves to the repo root, the project's `Info → Configurations` references break.
- Calls that chain into the PostgREST submodule (`.rpc(...)`, `.execute().value`) need `import PostgREST` alongside `import Supabase` in the calling file.
- The PostGIS `location geography(Point, 4326)` column on `sightings` is intentionally **not** modeled in Swift. Reads go through the `sightings_near` RPC (modeled as `NearbySighting` with separate `lat`/`lng` doubles); writes will use a typed insert that builds the point server-side.

## Auth state

- `AuthSession` (`Core/Supabase/AuthSession.swift`) is `@Observable @MainActor`. It subscribes to `supabase.auth.authStateChanges` and exposes a three-state enum: `.loading`, `.signedOut`, `.signedIn(User)`.
- It's instantiated once in `CatSnapApp` and injected via `.environment(session)`. Views consume it with `@Environment(AuthSession.self)`. Don't construct a second session anywhere.
- `ContentView` is the auth gate: routes `.loading` → `BrandSplash`, `.signedOut` → `AuthView`, `.signedIn` → `SightingsListView`.
- `emitLocalSessionAsInitialSession: true` is set in client config — opts into supabase-swift v3 behavior so the restored local session is always emitted on launch.

## Brand discipline

`docs/brand.md` is the source of truth and intentionally restrictive:

- **Light only in v1** — no dark mode. Don't add `Color(.systemBackground)` or `.preferredColorScheme(.dark)`.
- **Fraunces is wordmark-only.** Only `BlackItalic` is bundled. New headline moments need a new `.ttf` registered in Info.plist `UIAppFonts` *plus* a helper added to `BrandFonts.swift`.
- **Yellow/sage are highlights only** — never on the wordmark, never as a large surface.
- The cat-window mark (`CatWindowMark.swift`) is ported from the JSX `Window` component in `~/Downloads/cat-snap-branding-and-design/CatSnap Brand System.html` (lines 33–56) on a 200-unit grid. If retouching the silhouette, update from that source rather than eyeballing.

## Schema and RLS

- v1 migrations are applied to the live project. Tables: `profiles`, `cats`, `sightings`, `sighting_tags`. RLS is on; anon reads everywhere, writes require `auth.uid()`.
- `cats.rarity` is constrained to `('common','uncommon','rare','legendary')` — match this in `Cat.Rarity` if changing.
- A trigger auto-creates a profile row when `auth.users` gets a new entry; don't insert into `profiles` directly from the client.
- Storage buckets `sighting-photos` and `avatars` are public-read, authenticated-write only.
- Features deferred to v2 (don't add tables for these without checking): friendships, follows, reactions, comments, merge_requests, badges, streaks, sighting visibility flags.

## Things commonly mistaken

- `import Supabase` alone is **not enough** for query chains — the methods returning `PostgrestResponse` are defined in the `PostgREST` module and need an explicit second import.
- The Xcode project name `CatSnap` (PascalCase) was deliberate — Swift module names can't contain hyphens. Don't rename to `cat-snap`.
- The `cat_snap` web schema (legacy, on the retired Vercel project) is **not** what `docs/new-schema.sql` describes. The new schema is simpler (no friends, follows, reactions) and is the only one that matters now.
- The branch `main` is what ships; there is no `develop` or `staging`. PRs aren't required for solo dev work but commits should be clean and prefixed with the area touched.
