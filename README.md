# Cat-Snap

> A community-driven map for spotting and tracking street cats. Native SwiftUI iOS app.

**spot every cat.**

## Status

iOS rebuild is feature-complete for v1 — map, submit-sighting, cat + user profiles, friends graph, explore guide, streaks, onboarding, and Apple's UGC review gates (account deletion, block + report) all ship from `main`. The remaining pre-launch work — Swift sweep, Snyk security audit, UI/UX pass, App Store gates — is tracked in [`docs/launch-checklist.md`](docs/launch-checklist.md).

The original Next.js web app has been retired and is preserved at git tag `v1.0.2-web-final`. The new schema, branding, and Supabase project are unrelated to it.

## Build & run

Open `CatSnap/CatSnap.xcodeproj` in Xcode and press ⌘R. Requires iOS 17+ simulator or device.

To build from CLI:

```sh
xcodebuild -project CatSnap/CatSnap.xcodeproj -scheme CatSnap \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Supabase credentials are read at runtime from `CatSnap/CatSnap/CatSnap.xcconfig` (gitignored). Copy `CatSnap.example.xcconfig` next to it and fill in `SUPABASE_URL` and `SUPABASE_ANON_KEY`.

## Where things are

- **App source** → [`CatSnap/CatSnap/`](CatSnap/CatSnap) — `Core/` (Supabase client, models, UI primitives, location, storage), `Features/` (Auth, Map, Submit, CatProfile, UserProfile, Friends, Explore, Sightings, Onboarding, Moderation)
- **Pre-launch checklist** → [`docs/launch-checklist.md`](docs/launch-checklist.md)
- **Brand** → [`docs/brand.md`](docs/brand.md) (palette, typography, mark)
- **DB schema** → [`docs/new-schema.sql`](docs/new-schema.sql) (Postgres + PostGIS)
- **Working notes for Claude Code** → [`CLAUDE.md`](CLAUDE.md)

## Tech stack

| Layer | Choice |
|-------|--------|
| App framework | SwiftUI (iOS 17+) |
| Language | Swift 5.9+ |
| State | `@Observable` (iOS 17) |
| Backend | Supabase (Postgres + PostGIS + Auth + Storage) |
| Auth | Supabase Auth (email today; Sign in with Apple in Phase 4) |
| Maps | Apple MapKit |
| Location | CoreLocation |
| Photos / camera | PhotosPicker + `UIImagePickerController` |
| Networking | Supabase Swift SDK only |
| Fonts | Plus Jakarta Sans, Fraunces, JetBrains Mono (bundled `.ttf`) |

## Deferred to v2

Reactions, comments, merge requests, real badges/streaks (UI uses locally-computed awards + a streak counter today), per-sighting visibility, TNR/caretaker flags on cats, push notifications, leaderboard, AI cat-matching at submit time.
