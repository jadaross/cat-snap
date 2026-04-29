# Cat-Snap

> A community-driven map for spotting and tracking street cats. Native iOS, in pre-build.

**spot every cat.**

## Status

This repo is the planning + spec home for the Cat-Snap iOS app. The original Next.js web app has been retired (preserved at git tag `v1.0.2-web-final`); the iOS rebuild is in Phase 1 (foundations, pre-Xcode).

When the Xcode project starts (Phase 2), it'll either live in this repo at the root, or in a fresh repo named after the rebrand — TBD.

## Where things are

- **The plan** → [`docs/ios-rebuild.md`](docs/ios-rebuild.md)
- **Brand** → [`docs/brand.md`](docs/brand.md) (palette, typography, mark)
- **Design system** → [`docs/design-reference.md`](docs/design-reference.md) (points to external folder)
- **Schema for new Supabase project** → [`docs/new-schema.sql`](docs/new-schema.sql)
- **Product feature spec** → [`docs/features.md`](docs/features.md)
- **Roadmap / future** → [`docs/future-upgrades.md`](docs/future-upgrades.md)
- **Competitive landscape** → [`docs/competitive-analysis.md`](docs/competitive-analysis.md)

## Tech stack (locked)

| Layer | Choice |
|-------|--------|
| App framework | SwiftUI (iOS 17+) |
| Backend | Supabase (Postgres + PostGIS + Auth + Storage) |
| Auth | Supabase Auth + Sign in with Apple |
| Maps | Apple MapKit |
| AI matching (v3) | On-device Vision feature prints + pgvector |
