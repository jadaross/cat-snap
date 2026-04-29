# iOS Rebuild — In-Repo Reference

The plan for rebuilding Cat-Snap as a native SwiftUI iOS app — checked into history as the in-repo companion to the per-session plans in `~/.claude/plans/`.

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
| 2 | Walking skeleton: SwiftUI + Supabase auth + first round-trip | ✅ Done |
| 3 | MVP feature parity: map, submit, profiles | ✅ Done |
| 4 | TestFlight | **← here** |

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
- `find_or_create_cat_rpc` — case-insensitive cat-name → cat-id resolution. Currently unused (subsumed by `create_sighting_with_cat`); kept as a small reusable building block.
- `create_sighting_with_cat_rpc` — atomic single-call RPC for the submit flow: resolves cat by id-or-name (creating if missing), inserts the sighting with a server-built geography point, inserts tags. Replaced the three-call client sequence and fixed the orphan-cats failure mode.

Storage buckets:
- `sighting-photos` — public read via CDN, authenticated INSERT only
- `avatars` — public read via CDN, authenticated INSERT only

Auth providers:
- Email — enabled (email confirmation toggled OFF for dev; re-enable before TestFlight + configure SMTP)
- Sign in with Apple — to be enabled in Phase 4 once an Apple Developer account is in place

## Phase 2 — Done

A signed-in walking skeleton that proves the data round-trip end-to-end.

Shipped:
- Xcode project at `CatSnap/CatSnap.xcodeproj` (synchronized folder layout — files inside `CatSnap/CatSnap/` auto-appear in the build).
- `Supabase` Swift SDK linked, plus `PostgREST`, `Storage`, `Auth` sub-products.
- `CatSnap.xcconfig` (gitignored) → Info.plist `$(VAR)` substitution for `SUPABASE_URL` and `SUPABASE_ANON_KEY`. The `.example.xcconfig` is committed as a template.
- Brand primitives — `BrandColors`, `BrandFonts`, `CatWindowMark` (SVG ported on the 200-unit grid), `Wordmark`. Six `.ttf` files bundled (one Fraunces black-italic, four Plus Jakarta weights, one JetBrains Mono regular).
- Codable models matching the schema field-for-field with snake_case `CodingKeys`. PostGIS `location` column intentionally not modelled in Swift; reads go via the `sightings_near` RPC's `NearbySighting` shape.
- Module-level `let supabase: SupabaseClient` global. `emitLocalSessionAsInitialSession: true` opts into supabase-swift v3 init behavior.
- `AuthSession` (`@Observable @MainActor`) subscribes to `authStateChanges` and exposes a `.loading` / `.signedOut` / `.signedIn(User)` enum.
- `ContentView` is the auth gate: routes to `BrandSplash` / `AuthView` / signed-in tabs.
- `AuthView` — email + password sign-in/up.

## Phase 3 — Done

Closed the core loop: see cats on a map → snap a new cat → see it appear → manage your profile.

Shipped:
- **Tabbed home** — `MainTabView` with Map and Profile tabs, plus a coral "+" overlay button that opens `SubmitView` as a fullScreenCover.
- **Map** — SwiftUI `Map` (iOS 17 API) with `Annotation` per `NearbySighting`. Re-fetches when the camera centre moves >500 m. Per-cat circular `CatPin` (white border, amber when selected). `PinDetailCard` slides up on selection and pushes `CatProfileView` via NavigationStack. Top-leading time filter (today / week / all), top-trailing find-me button, empty-state card.
- **Submit flow** — PhotosPicker (library) and `UIImagePickerController` (camera) → on-device JPEG compress (max 1600px, q=0.7) → `LocationManager` one-shot fix with `CLGeocoder` reverse-geocode → atomic `create_sighting_with_cat` RPC. NotificationCenter post triggers a map refresh in place.
- **Cat profile** — hero photo, info card with name + last-seen + stats, "i saw this cat" CTA opens Submit prefilled with the cat id, sightings thumbnail grid.
- **User profile** — avatar, display name, stats, my-sightings grid, `EditProfileSheet` for changing display name + avatar (uploads to `avatars` bucket, updates `profiles.avatar_url`), sign-out in the toolbar.
- **Cross-cutting primitives** — `RarityBadge`, `TagChip` (with the 12 preset tags from the design canvas), `AsyncCatImage` (cream-deep placeholder + brand-mark fallback), `SightingThumbnail` (square cell with a relative-time stamp).

Deferred to v2 (intentionally not built):
- Friend system, follows, reactions, comments, merge_requests
- Push notifications, badges, streaks, leaderboard
- Per-sighting visibility, TNR/caretaker flags on cats
- Notes field on sightings
- AI cat-matching at submit time (Phase 4 / v3 territory)

## Phase 4 — TestFlight

This is mostly your work — the things that need an Apple Developer account.

1. **Apple Developer account** ($99/yr): https://developer.apple.com/programs/enroll/
2. **App Store Connect** record: register the bundle id `com.jadaross.CatSnap`, set name + subtitle ("spot every cat.") + description.
3. **App icon**: 1024×1024 PNG, no transparency, no rounded corners. Master at `docs/icon-master.png` once exported. Add to `Assets.xcassets/AppIcon.appiconset/`.
4. **Sign in with Apple**:
   - Xcode → CatSnap target → **Signing & Capabilities** → `+` → Sign in with Apple
   - Supabase Dashboard → Authentication → Providers → Apple → enable, fill in Service ID + key
   - Add a "Sign in with Apple" button to `AuthView` using `SignInWithAppleButton` from AuthenticationServices
5. **Re-enable email confirmation** in Supabase Auth + configure SMTP (Resend or Postmark) so confirmation mails reach Hotmail/Outlook reliably.
6. **Privacy strings audit** — already have NSCamera, NSLocationWhenInUse, NSPhotoLibrary descriptions. Add NSUserTrackingUsageDescription if any analytics get wired later.
7. **Archive + upload** — Xcode → Product → Archive → distribute to TestFlight.
8. **Invite test flight users** by email in App Store Connect.

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
- **Re-enable email confirmation + configure SMTP** before TestFlight (was disabled during Phase 2 to unblock dev signup).
- **Push the git tag** when convenient: `git push origin v1.0.2-web-final`.
