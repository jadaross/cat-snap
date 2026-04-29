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

| Phase | What | Time |
|-------|------|------|
| 0 | Preserve spec, archive web app | ✅ Done |
| 1 | Foundations: branding, new Supabase, repo cleanup | In progress |
| 2 | Walking skeleton: SwiftUI + Supabase auth + one API call | 1–2 weeks |
| 3 | MVP feature parity: map, submit, profiles | 3–5 weeks |
| 4 | TestFlight | 1 week |

## What's already done

- ✅ Git tag `v1.0.2-web-final` preserves the entire Next.js web app in history.
- ✅ Web app + Vercel/Next.js root config deleted from working tree.
- ✅ Web-specific docs (architecture.md, manual-setup.md, database-schema.md, legacy-schema.sql) deleted — superseded by the iOS plan + new schema.
- ✅ Branding extracted into `docs/brand.md` from the design system at `~/Downloads/cat-snap-branding-and-design/` — palette (cream/ink/coral), typography (Plus Jakarta Sans + Fraunces), mark spec, tagline, voice.
- ✅ `docs/new-schema.sql` simplified for v1 + augmented with `rarity` column on `cats`. Defers social/gamification tables to v2.
- ✅ `docs/design-reference.md` indexes the external design folder so future-you can find the source-of-truth mockups.
- ✅ `README.md` rewritten as a short pointer to the docs.

## What you need to do (Phase 1, remaining)

### No blockers (do now)

1. **Kick off Xcode download** from the Mac App Store. ~10 GB. Background it; takes ~30 minutes.
2. **Confirm the app icon plan.** The mark exists as the `Window` SVG component in `~/Downloads/cat-snap-branding-and-design/design-canvas.jsx`. Export it as 1024×1024 PNG → `docs/icon-master.png` when ready (can defer until Phase 2).

### After app icon is exported (or in parallel)

3. **Create the new Supabase project** at [supabase.com](https://supabase.com):
   - Name: `catsnap` (or your preferred slug — must be URL-safe)
   - Region: closest to your users
   - Save Project URL + anon key to a password manager (not git)
   - Database → Extensions → enable **postgis**
   - SQL Editor → paste and run [`docs/new-schema.sql`](new-schema.sql)
   - Authentication → Providers → enable **Email** and **Sign in with Apple**
     - Sign in with Apple full setup needs an Apple Developer account — defer if you're only running in the simulator for now
   - Storage → New bucket → `sighting-photos` (public read, authenticated write)
   - Storage → New bucket → `avatars` (public read, authenticated write)

4. **Decide: same repo vs fresh repo for the iOS code.**
   - You said you'll keep working in this repo. So when Phase 2 starts, the Xcode project goes at `./CatSnap.xcodeproj` (or similar), `Sources/`, `Resources/` at the root.
   - Old web app history is preserved via the git tag — no need to fork.

### Phase 1 deliverables checklist

- [x] Branding extracted into `docs/brand.md` (real, not placeholders)
- [x] `docs/design-reference.md` points at external design folder
- [x] `docs/new-schema.sql` includes rarity, ready to paste into Supabase
- [x] Web app deleted, repo cleaned
- [ ] App icon master `docs/icon-master.png` exported (1024×1024)
- [ ] Xcode installed
- [ ] New Supabase project created; URL + anon key saved
- [ ] PostGIS enabled
- [ ] `docs/new-schema.sql` run in new Supabase project
- [ ] Email + Sign in with Apple auth providers enabled
- [ ] `sighting-photos` and `avatars` storage buckets created
- [ ] `git push origin v1.0.2-web-final` (push the preservation tag)

When this checklist is done, you're ready for Phase 2 (Xcode).

## Tech stack (locked)

| Layer | Choice |
|-------|--------|
| App framework | SwiftUI (iOS 17+) |
| Language | Swift 5.9+ |
| Backend | Supabase (new project) |
| Auth | Supabase Auth + Sign in with Apple |
| DB | Postgres + PostGIS |
| Storage | Supabase Storage |
| Maps | Apple MapKit |
| Location | CoreLocation |
| Photos/camera | PhotosPicker / UIImagePickerController |
| State | `@Observable` (iOS 17) |
| Networking | Supabase Swift SDK only |
| Fonts | Plus Jakarta Sans, Fraunces, JetBrains Mono (bundled `.ttf`) |

## When you're ready for Phase 2

Drop a message — "I've finished Phase 1, what now?" — and we'll:
- Walk through Xcode project creation step by step at the repo root
- Add the Supabase Swift SDK via Swift Package Manager
- Bundle the brand fonts into `Resources/Fonts/`
- Scaffold the folder structure (`App/`, `Features/`, `Core/`)
- Build the walking skeleton: auth + one API call
- Port the `Window` mark from JSX to a SwiftUI `Shape`
