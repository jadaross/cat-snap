# iOS Rebuild — In-Repo Reference

The plan for rebuilding Cat-Snap as a native SwiftUI iOS app. The full master plan lives at `~/.claude/plans/goofy-seeking-flame.md`; this file is the in-repo companion that's checked into history.

## Decision summary

- **Native SwiftUI iOS app** (iOS 17+), not React Native, not Capacitor.
- **Full restart**, not migration: new Supabase project, new schema, new branding.
- **Web app retired** — preserved at git tag `v1.0.2-web-final`; `apps/web/` deleted from working tree.
- **Apple MapKit**, not Mapbox.
- **Supabase Swift SDK** for auth, DB, storage. No other networking deps.
- **AI cat-matching path** (v3): on-device Vision feature prints + pgvector, fallback to CLIP via Edge Function.

## Roadmap

| Phase | What | State |
|-------|------|-------|
| 0 | Preserve spec, archive web app | ✅ Done |
| 1 | Foundations: branding, new Supabase, repo cleanup | ✅ Done |
| 2 | Walking skeleton: SwiftUI + Supabase auth + one API call | **← here** |
| 3 | MVP feature parity: map, submit, profiles | Next |
| 4 | TestFlight | Last |

## Phase 1 — Done

- Git tag `v1.0.2-web-final` preserves the entire Next.js web app in history.
- Web app + Vercel/Next.js root config deleted from the working tree.
- Web-specific docs deleted — superseded by the iOS plan + new schema.
- Branding extracted from `~/Downloads/cat-snap-branding-and-design/` into `docs/brand.md` (cream/ink/coral palette, Plus Jakarta Sans + Fraunces, "cat at the window" mark, "spot every cat." tagline).
- New schema designed at `docs/new-schema.sql` — simpler than v1.0.2 + adds `rarity` on cats. Social/gamification tables deferred to v2.
- `docs/design-reference.md` indexes the external design folder.
- `README.md` rewritten as a pointer to the docs.

### Supabase project state (live)

| | |
|---|---|
| **Project URL** | `https://wgtjtvxpxalyeukgxbpo.supabase.co` |
| **Region** | eu-central-2 (Zurich) — ~20ms latency to UK |
| **Project ID** | `wgtjtvxpxalyeukgxbpo` |
| **Dashboard** | https://supabase.com/dashboard/project/wgtjtvxpxalyeukgxbpo |
| **Publishable key** | Saved in your password manager (NOT in this repo) |

Migrations applied:
- `v1_initial` — extensions, profiles + cats + sightings + sighting_tags tables, `sightings_near` PostGIS RPC, RLS policies, auto-create-profile trigger.
- `v1_hardening` — `(select auth.uid())` perf optimization on RLS, locked function `search_path`, revoked `EXECUTE` on `handle_new_user`, indexed `cats.created_by` FK.
- `v1_storage_policy_tightening` — dropped overly broad SELECT policies on `avatars` and `sighting-photos` buckets. Public URL access still works via CDN.

Storage buckets (created previously, kept):
- `sighting-photos` — public, authenticated INSERT only
- `avatars` — public, authenticated INSERT only

Auth providers:
- Email — enabled by default
- Sign in with Apple — to be enabled when you have an Apple Developer account ($99/yr); needed before App Store submission, can defer until Phase 4

## Phase 2 — Walking skeleton (in Xcode)

Goal: a SwiftUI app that signs in via Supabase and fetches one list of sightings. No map, no submit. Proves the data round-trip works end-to-end.

### Step 1: Create the Xcode project (you do — GUI only)

Open Xcode. **File → New → Project**, then:

| Setting | Value |
|---------|-------|
| Template | iOS → **App** |
| Product Name | **CatSnap** (PascalCase, no hyphen — Xcode generates Swift class names from this) |
| Team | Your Apple ID (or "None" until you have a Developer account) |
| Organization Identifier | `com.jadaross` |
| Bundle Identifier | (auto-fills to `com.jadaross.CatSnap`) |
| Interface | **SwiftUI** |
| Language | **Swift** |
| Storage | **None** (we use Supabase, not SwiftData) |
| Include Tests | ✓ leave on |

When prompted for save location, choose `/Users/jada/Desktop/repos/cat-snap/` and **uncheck "Create Git repository"** (this is already a git repo). The Xcode project will save as `CatSnap.xcodeproj` at the repo root.

### Step 2: Set deployment target to iOS 17

1. In Xcode, click the project file at the top of the file navigator
2. Select the **CatSnap** target → **General** tab
3. Set **Minimum Deployments → iOS** to `17.0`

### Step 3: Add the Supabase Swift SDK

1. **File → Add Package Dependencies**
2. URL: `https://github.com/supabase/supabase-swift`
3. Dependency rule: **Up to Next Major Version** from `2.0.0`
4. Add the `Supabase` product to the `CatSnap` target

### Step 4: Add brand fonts

1. Download from Google Fonts:
   - [Plus Jakarta Sans](https://fonts.google.com/specimen/Plus+Jakarta+Sans) (weights 400–800)
   - [Fraunces](https://fonts.google.com/specimen/Fraunces) (italic 900)
   - [JetBrains Mono](https://fonts.google.com/specimen/JetBrains+Mono) (400, 500, 700)
2. Drop the `.ttf` files into a new `Resources/Fonts/` folder in the project
3. Add to `Info.plist` under `Fonts provided by application` (UIAppFonts)

### Step 5: Tell Claude "Xcode project created"

Once steps 1–4 are done, Claude will scaffold:
- `Core/UI/BrandColors.swift` — `Color` extensions for the cream/ink/coral palette
- `Core/UI/BrandFonts.swift` — `Font.custom` helpers
- `Core/UI/CatWindowMark.swift` — SwiftUI `Shape` ported from the SVG mark in `design-canvas.jsx`
- `Core/Supabase/SupabaseClient.swift` — singleton client + URL/key config
- `Core/Models/Sighting.swift`, `Cat.swift`, `Profile.swift` — Codable structs matching the DB schema
- `App/CatSnapApp.swift` — `@main` entry with auth gating
- `Features/Auth/AuthView.swift` — email sign-in / sign-up form
- `Features/Sightings/SightingsListView.swift` — first round-trip: fetch and display sightings
- `.xcconfig` for Supabase URL + key (gitignored)
- Updated `.gitignore` for Xcode artifacts

## Phase 3 — MVP feature parity (preview)

Build the core loop, in this order:

1. **Map view** with **MapKit** — pins from `sightings_near()` RPC.
2. **Submit sighting flow** — PhotosPicker or camera → on-device JPEG compression → CoreLocation → Supabase Storage upload → DB insert.
3. **Cat profile + sightings list per cat.**
4. **User profile screen** — edit display name, avatar.
5. **Tag display + filter.**
6. **Rarity badges** on cat cards (already in schema).

Cut from MVP (defer to v2): friend system, reactions/comments, admin merge requests, push notifications, badges, streaks, leaderboard, follows.

## Phase 4 — TestFlight (preview)

1. Apple Developer account ($99/yr).
2. Configure signing & capabilities (Sign in with Apple, Push Notifications later).
3. Create app record in App Store Connect.
4. Archive + upload via Xcode → TestFlight.
5. Invite friends to use it for real.

## Tech stack (locked)

| Layer | Choice |
|-------|--------|
| App framework | SwiftUI (iOS 17+) |
| Language | Swift 5.9+ |
| Backend | Supabase (project: `wgtjtvxpxalyeukgxbpo`) |
| Auth | Supabase Auth + Sign in with Apple (Phase 4) |
| DB | Postgres + PostGIS |
| Storage | Supabase Storage |
| Maps | Apple MapKit |
| Location | CoreLocation |
| Photos/camera | PhotosPicker / UIImagePickerController |
| State | `@Observable` (iOS 17) |
| Networking | Supabase Swift SDK only |
| Fonts | Plus Jakarta Sans, Fraunces, JetBrains Mono (bundled `.ttf`) |

## Outstanding optional dashboard tasks

- **Enable leaked password protection** — Authentication → Policies → toggle on. One click.
- **Delete the orphaned `auth.users` row** from the legacy setup (1 row). Authentication → Users → delete. Or leave it — harmless.
- **Push the git tag** when convenient: `git push origin v1.0.2-web-final`.
