# Architecture

## Overview

Cat Snap is a Next.js web application backed by Supabase. The architecture is deliberately simple for the MVP and designed to evolve cleanly into an iOS app later.

```
┌──────────────────────────────────────────────────────────────┐
│                        Client (Browser)                       │
│                                                              │
│   Next.js App (React, TypeScript, Tailwind, Mapbox GL JS)   │
└──────────────────┬───────────────────────────────────────────┘
                   │ HTTPS
         ┌─────────▼──────────┐
         │  Next.js API Routes │  (thin layer: auth checks,
         │  /app/api/**        │   input validation, Supabase calls)
         └─────────┬──────────┘
                   │
         ┌─────────▼──────────┐
         │     Supabase        │
         │                     │
         │  ┌───────────────┐  │
         │  │  PostgreSQL   │  │  ← primary data store
         │  │  + PostGIS    │  │    (geospatial queries)
         │  └───────────────┘  │
         │  ┌───────────────┐  │
         │  │  Auth         │  │  ← email, Google OAuth
         │  └───────────────┘  │
         │  ┌───────────────┐  │
         │  │  Storage      │  │  ← cat photos, avatars
         │  └───────────────┘  │
         │  ┌───────────────┐  │
         │  │  Realtime     │  │  ← live feed updates (v2)
         │  └───────────────┘  │
         └─────────────────────┘
```

---

## Frontend Architecture

### Framework: Next.js 14 (App Router)

Using the App Router for:
- Server Components for data-heavy pages (cat profile, map initial load)
- Client Components for interactive elements (map, camera, feed)
- Route handlers for API endpoints
- Built-in image optimization

### Directory Structure

```
apps/web/
├── app/
│   ├── layout.tsx              # Root layout (nav, auth provider)
│   ├── page.tsx                # Landing / home (map view)
│   ├── (auth)/
│   │   ├── login/page.tsx
│   │   └── signup/page.tsx
│   ├── map/
│   │   └── page.tsx            # Full-screen map of sightings
│   ├── cats/
│   │   ├── page.tsx            # Browse cats
│   │   └── [id]/page.tsx       # Individual cat profile
│   ├── sightings/
│   │   ├── new/page.tsx        # Submit a new sighting
│   │   └── [id]/page.tsx       # Individual sighting view
│   ├── feed/
│   │   └── page.tsx            # Friend activity feed (v2)
│   ├── profile/
│   │   ├── page.tsx            # Current user's profile
│   │   └── [username]/page.tsx # Public user profile
│   └── api/
│       ├── sightings/
│       │   ├── route.ts        # GET /api/sightings, POST /api/sightings
│       │   └── [id]/route.ts   # GET, PATCH, DELETE
│       ├── cats/
│       │   ├── route.ts
│       │   └── [id]/route.ts
│       └── users/
│           └── [username]/route.ts
├── components/
│   ├── map/
│   │   ├── CatMap.tsx          # Main Mapbox map
│   │   ├── SightingPin.tsx     # Map marker component
│   │   └── MapFilters.tsx      # Filter controls
│   ├── cats/
│   │   ├── CatCard.tsx         # Cat preview card
│   │   ├── CatProfile.tsx      # Full cat profile
│   │   └── SightingGallery.tsx # Photo grid of sightings
│   ├── sightings/
│   │   ├── SightingForm.tsx    # New sighting form
│   │   ├── SightingCard.tsx    # Feed item
│   │   └── PhotoUpload.tsx     # Camera / file upload
│   ├── social/
│   │   ├── FriendFeed.tsx      # Activity feed
│   │   ├── FriendList.tsx
│   │   └── ReactionBar.tsx
│   └── ui/
│       ├── Button.tsx
│       ├── Avatar.tsx
│       ├── Modal.tsx
│       └── ...                 # Shared UI primitives
├── lib/
│   ├── supabase/
│   │   ├── client.ts           # Browser Supabase client
│   │   ├── server.ts           # Server-side Supabase client
│   │   └── middleware.ts       # Auth session refresh
│   ├── api/
│   │   ├── sightings.ts        # API fetch helpers
│   │   ├── cats.ts
│   │   └── users.ts
│   ├── hooks/
│   │   ├── useLocation.ts      # GPS location hook
│   │   ├── useSightings.ts     # SWR/TanStack Query hooks
│   │   └── useAuth.ts
│   └── utils/
│       ├── geo.ts              # Coordinate helpers
│       └── images.ts           # Image resize/compress before upload
├── public/
│   └── icons/                  # App icons, cat placeholder images
├── .env.example
├── next.config.ts
├── tailwind.config.ts
└── package.json
```

---

## Key Technical Decisions

### Why Supabase?

1. **PostGIS** — geospatial queries (find cats within X km) are built-in, no extra infrastructure needed
2. **Auth** — handles email + OAuth (Google) out of the box
3. **Storage** — S3-compatible image storage with CDN, no extra service needed
4. **Realtime** — postgres change notifications for live feed updates in v2
5. **Single service** — reduces complexity for a solo/small team

### Why Mapbox GL JS?

- Generous free tier (50,000 map loads/month)
- Beautiful default tiles, highly customizable
- `mapbox-gl` has a React wrapper (`react-map-gl`)
- Used by Strava, Airbnb, Snap Maps — proven at scale
- Better for mobile-feeling interactions than Google Maps JS API

### Why Next.js API Routes vs. separate backend?

For the MVP, co-locating API routes with the frontend reduces deployment complexity (single Vercel project). When the iOS app is built, we can either:
- Keep using the Next.js API (works fine for REST)
- Migrate hot paths to a dedicated Express/Fastify service

### Image Handling Strategy

1. Client-side compression before upload (using `browser-image-compression` or Canvas API) — target < 1MB per photo
2. Upload directly to Supabase Storage from the client (no server round-trip for files)
3. Use Supabase Storage's image transformation API for thumbnails

---

## Auth Flow

```
User signs up / logs in
        │
        ▼
Supabase Auth sets session cookie
        │
        ▼
Next.js middleware (lib/supabase/middleware.ts)
refreshes session on every request
        │
        ▼
Server Components: use server Supabase client (reads session from cookie)
API Routes: verify session before any writes
```

---

## Deployment

| Service | Purpose |
|---------|---------|
| Vercel | Next.js hosting, Edge Middleware |
| Supabase (free tier) | Database, Auth, Storage |
| Mapbox | Map tiles |

All free tier for early development. Supabase free tier supports up to 500MB DB storage and 1GB file storage.

---

## iOS App Transition Plan

The web app is designed with the iOS transition in mind:

1. **API-first** — all data access goes through the API routes (no direct Supabase calls from page components). The iOS app will consume the same endpoints.
2. **Auth via Supabase** — Supabase has native iOS Swift SDKs, so auth is already portable.
3. **Storage** — image URLs are the same; iOS app will upload to the same Supabase Storage bucket.
4. **Potential React Native** — if we want to share React component logic, React Native (with Expo) is an option. Evaluate after the web MVP is stable.
