# Cat Snap

> A community-driven map for discovering and tracking street cats in your city.

Spot a street cat? Snap a photo, drop a pin, and share the sighting with your community. Cat Snap lets neighborhoods build a living map of their local feline residents — complete with cat profiles, sighting histories, and a social feed so you can keep up with what your friends are finding.

## What It Does

- **Snap & Tag** — Take or upload a photo of a cat, drop a map pin at the location, and submit a sighting in seconds.
- **Cat Profiles** — Sightings of the same cat are linked together to build a profile: last seen location, photo gallery, description, nicknames, and sighting history.
- **Neighborhood Map** — An interactive map showing recent cat sightings near you. Filter by date, area, or specific cats.
- **Social Feed** — Follow friends and see what cats they've spotted around town. React and comment on sightings.
- **Cat Check-In** — Mark a cat as recently seen to let other community members know it's still around and healthy.
- **Cat Status** — Community-sourced notes like whether a cat is being fed, is TNR'd, has a known caretaker, or is shy vs. friendly.

## Roadmap

See [`docs/features.md`](docs/features.md) for the full phased feature plan.

| Phase | Focus |
|-------|-------|
| MVP | Map + photo upload + cat profiles |
| v2 | Social features (friends, feed, reactions) |
| v3 | Cat recognition / duplicate linking, notifications |
| iOS | Native iOS app using the same backend API |

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Next.js 14 (App Router), TypeScript, Tailwind CSS |
| Maps | Mapbox GL JS |
| Backend | Next.js API Routes |
| Database | Supabase (PostgreSQL + PostGIS) |
| Auth | Supabase Auth |
| Storage | Supabase Storage |
| Deployment | Vercel |

See [`docs/architecture.md`](docs/architecture.md) for the full architecture breakdown.

## Getting Started

```bash
# Install dependencies
npm install

# Set up environment variables
cp .env.example .env.local
# Fill in your Supabase and Mapbox keys

# Run the dev server
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Project Structure

```
cat-snap/
├── apps/
│   └── web/              # Next.js web application
│       ├── app/          # App Router pages & layouts
│       ├── components/   # Reusable UI components
│       ├── lib/          # Utilities, API clients, hooks
│       └── public/       # Static assets
├── docs/                 # Planning and architecture docs
│   ├── architecture.md
│   ├── features.md
│   ├── database-schema.md
│   └── competitive-analysis.md
└── README.md
```

## Competitive Landscape

See [`docs/competitive-analysis.md`](docs/competitive-analysis.md) for a breakdown of existing apps in this space and how Cat Snap differentiates.

## Contributing

This project is in early planning/development. See [`docs/features.md`](docs/features.md) for what's coming next.
