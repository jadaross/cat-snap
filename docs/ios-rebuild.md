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
| 3.5 | Beyond-MVP: explore guide, friends, streaks, onboarding | ✅ Done |
| 4 | Pre-release hardening + TestFlight | **← here** |
| 5 | App Store submission | Not started |

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

## Phase 3.5 — Beyond-MVP (also done, ahead of original plan)

Several features that were originally deferred to v2 shipped opportunistically once the MVP loop felt complete:

- **Friends** — one-way follow graph (`public.follows` + `friend_activity` / `my_friends` / `search_profiles` RPCs). UI: `AddFriendsView`, friends section on profile, activity feed (`FriendsActivityView` + `FriendActivityRow`).
- **Explore field-guide** — grid of all known cats with locked silhouettes for unspotted ones, progress, filters (`Features/Explore/`).
- **Streaks + awards** — locally-computed daily streak heatmap and awards grid on the user profile.
- **Onboarding** — full multi-step flow: welcome → how-it-works → avatar pick → on-the-map demo → spotted demo → camera/location/notifications permissions → first-snap (`Features/Onboarding/`).
- **EXIF-aware uploads** — submit flow respects orientation + extracts capture date from camera-roll photos.

Still deferred to v2 (intentionally not built):
- Reactions, comments, merge_requests
- Push notifications (permission is requested in onboarding but no APNs payload handler yet)
- Real `badges` table (UI uses locally-computed awards)
- Leaderboard
- Per-sighting visibility, TNR/caretaker flags on cats
- Notes field on sightings
- AI cat-matching at submit time (v3 territory)

## Phase 4 — Pre-release hardening + TestFlight

You have the Apple Developer account ✅. Below is the actual pre-release checklist — gates first, then the things that block App Store review specifically, then nice-to-haves.

### A. App Store review gates (App Store Review Guidelines)

These will get the app **rejected** if missing. Do these before submitting, not after.

1. **Account deletion in-app** (Guideline 5.1.1(v))
   Any app that supports account creation must let the user delete their account from inside the app — not just sign out, not just "email us". Implement:
   - Settings entry on `UserProfile` → "Delete account" → confirm sheet → Supabase Edge Function (service-role) that cascades: deletes the `auth.users` row (FKs cascade to `profiles` / `sightings` / `follows`).
   - Storage objects in `sighting-photos` and `avatars` owned by that user need explicit cleanup — Postgres FKs don't reach into Storage. Either iterate + delete in the Edge Function, or schedule a janitor.
2. **UGC moderation** (Guideline 1.2)
   Cat-Snap is a photo-UGC app, so all four are required:
   - **Report content** — long-press / overflow menu on a sighting → "Report" sheet with categories (spam, abuse, inappropriate, copyright). Writes to a `reports` table; you triage manually for v1.
   - **Block users** — from another user's profile → "Block". Blocked users' content is hidden from the blocker (filter in `sightings_near` and the activity feed RPCs); blocked users can't follow or interact.
   - **Filter for objectionable content** — at minimum a per-user list of blocked users. Stronger: server-side photo moderation (Cloud Vision SafeSearch / OpenAI moderation via Edge Function on upload). For v1 pre-moderation can be lighter, but the report → 24h triage commitment must be real.
   - **Contact for resolution** — published email (e.g. `support@catsnap.app`) reachable from the in-app Settings screen *and* in the App Store listing. Reports must be actioned within 24 hours per Apple's guideline.
3. **Sign in with Apple** (Guideline 4.8)
   Required if you offer any third-party login. With email/password only, technically not required — but if you add Google/Facebook later it becomes mandatory, and reviewers like to see it. Steps:
   - Xcode → CatSnap target → **Signing & Capabilities** → `+ Capability` → Sign in with Apple.
   - Supabase Dashboard → Authentication → Providers → Apple → enable, paste the Service ID + key (created in the Apple Developer console).
   - Add `SignInWithAppleButton` (from `AuthenticationServices`) to `AuthView`, wire to `supabase.auth.signInWithIdToken(...)`.
4. **Privacy policy + Terms of Service**
   App Store Connect requires a public privacy policy URL. Host it on a static page (e.g. GitHub Pages or a one-pager on `catsnap.app`). Cover: what data is collected (email, photos, GPS, profile info), why, retention, deletion path, third parties (Supabase as processor), contact email. Link from in-app Settings.
5. **App Privacy "nutrition labels"**
   In App Store Connect → App Privacy, declare: email + name (Account), Photos, Coarse Location, User-Generated Content. Linked-to-identity = yes for all. No tracking.

### B. Production-readiness (stuff that bites if skipped)

6. **Re-enable email confirmation + configure SMTP**
   Supabase Auth → toggle email confirmation back on. Default Supabase SMTP is rate-limited and goes to spam — wire a real provider (Resend or Postmark, ~£0/month at this volume). Customise the confirmation email template with brand colours + wordmark.
7. **App icon**
   `Assets.xcassets/AppIcon.appiconset/Contents.json` exists with universal/dark/tinted slots but **no PNG files**. Export 1024×1024 PNGs (no transparency, no rounded corners; iOS adds the radius) for all three appearances. Master goes at `docs/icon-master.png`.
8. **Crash + error reporting**
   Wire Sentry (free tier) via SPM. Catch unhandled exceptions and log Supabase RPC errors. Without this you fly blind on TestFlight.
9. **Permission denial UX**
   Walk every flow assuming the user said "Don't Allow" once and now wants to re-grant. The denial recovery path needs a "Open Settings" button (`UIApplication.openSettingsURLString`) on each of: camera, location, photo library, notifications.
10. **Bundle ID + signing**
    Xcode → target → Signing & Capabilities → assign Apple Developer team, confirm bundle id `com.jadaross.CatSnap` registered in App Store Connect.
11. **Empty / error / offline states**
    Audit map, explore, profile, friends activity. Each needs a non-broken empty state and a graceful "couldn't load — retry" state. No raw `Error.localizedDescription` shown to users.
12. **Rate limits + abuse mitigation** (Postgres-side)
    - Per-user submit cap (e.g. 50 sightings / day) via a constraint or RPC guard.
    - Per-user follow cap (e.g. 1000) to limit spam graphs.
    - Photo size cap enforced server-side, not just client-side.
13. **Leaked-password protection** — Supabase → Authentication → Policies → toggle on (one click).

### C. App Store Connect prep (do once, in parallel with above)

14. **App Store Connect record** — bundle id `com.jadaross.CatSnap`, name "Cat-Snap", subtitle "spot every cat.", primary category Photo & Video (secondary Social Networking), age rating 4+ (with UGC + location disclosures answered honestly).
15. **Description + keywords** — 4000-char description, 100-char keyword list. Draft in `docs/app-store-copy.md` so it's reviewable / iterable.
16. **Screenshots** — 6.7" iPhone Pro Max + 6.1" iPhone (required), iPad optional if you support it. 5–8 screenshots each. Use real fixtures (real cats, real map). Include a marketing-text overlay on each.
17. **Preview video** (optional but converts better) — 15–30s, recorded on simulator with `xcrun simctl io booted recordVideo`.
18. **Support URL** — same static site as the privacy policy.

### D. Nice-to-have before public launch (skip for first TestFlight build)

19. **iPad support** — currently iPhone-only feels right; explicitly set `TARGETED_DEVICE_FAMILY = 1` so the App Store doesn't list it as iPad-compatible.
20. **Push notifications** — onboarding asks for the permission but nothing sends pushes yet. Wire APNs + a Supabase Edge Function trigger on `friend_activity` ("Alex spotted a cat near you") once the basics ship.
21. **Universal Links / share sheet** — share a cat profile or a sighting via `catsnap.app/cat/<id>`; currently no out-of-app surface.
22. **Accessibility pass** — VoiceOver labels on `CatPin`, `RarityBadge`, `SightingThumbnail`; Dynamic Type honoured in cards; contrast check on coral-on-cream.
23. **Localization scaffolding** — wrap user-facing strings in `String(localized:)` even if only en is shipped, so v2 can add languages without a refactor.
24. **NSUserTrackingUsageDescription** — only needed if analytics/ads get wired. Skip until it's actually true.

### E. Ship sequence

1. Land A1 (account deletion) and A2 (report/block) — these are real code, not toggles.
2. Land B6 (email confirm + SMTP), B7 (icon), B8 (Sentry), B9 (permission denial UX).
3. Host privacy policy + terms (A4).
4. Internal TestFlight build → use it on your own phone for a week.
5. External TestFlight (≤100 testers, no review needed for friends/family).
6. Address feedback, iterate.
7. App Store submission (C14–C18).

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

- **Push the git tag** when convenient: `git push origin v1.0.2-web-final`.
- (The Supabase dashboard items — leaked-password protection and email confirmation/SMTP — are now tracked under Phase 4 above as B6 and B13.)
