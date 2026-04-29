# Design Reference

The full design system lives **outside this repo** at `~/Downloads/cat-snap-branding-and-design/`. This file is the index — what's there, what each file is, and what product decisions it captures.

> **Why external?** Keeping the design files out of the repo avoids bloating it with HTML mockups + 4 MB of PNGs, and the design will iterate independently of the code. Branding extracted *into* the repo (palette, typography, mark spec) lives in `docs/brand.md`.

## What's in the design folder

```
~/Downloads/cat-snap-branding-and-design/
├── CatSnap Brand System.html       — the brand bible (open in browser)
├── CatSnap App.html                — full app screen mockups
├── CatSnap Map Pins.html           — map pin variants
├── CatSnap Onboarding.html         — onboarding flow
├── design-canvas.jsx               — React source for Brand System.html
├── catsnap-data.jsx                — design tokens + sample data (CS, RARITY, CATS, FEED_ITEMS, LEADERBOARD, MY_BADGES, MY_STATS)
├── catsnap-screens.jsx             — React source for App.html
├── catsnap-onboarding.jsx          — React source for Onboarding.html
├── ios-frame.jsx                   — iOS device chrome wrapper used in mockups
├── tweaks-panel.jsx                — interactive design controls
└── uploads/
    ├── pasted-1777451423171-0.png  — reference screenshot
    ├── pasted-1777451443115-0.png  — reference screenshot
    ├── pasted-1777451448737-0.png  — reference screenshot
    └── pasted-1777451461585-0.png  — reference screenshot
```

## How to view

The HTML files are self-contained — open in a browser:

```bash
open "~/Downloads/cat-snap-branding-and-design/CatSnap Brand System.html"
open "~/Downloads/cat-snap-branding-and-design/CatSnap App.html"
open "~/Downloads/cat-snap-branding-and-design/CatSnap Map Pins.html"
open "~/Downloads/cat-snap-branding-and-design/CatSnap Onboarding.html"
```

(They use Babel-in-browser to render the JSX live.)

## What the design captures (product decisions)

Source: `catsnap-data.jsx`. These shape the data model and feature set.

### Cat profile fields
- `name`, `description`
- `rarity`: common / uncommon / rare / legendary → in v1 schema as `cats.rarity` column
- `tags`: free-text tag array → existing `sighting_tags` table
- `lastSeen`, `firstSeen` → derive from `sightings.seen_at` (no separate column)
- `sightings` count → derive (`COUNT(*) FROM sightings WHERE cat_id = ?`)
- `followers` count → **needs `cat_follows` table** (deferred to v2)
- `bg`: per-cat gradient → cosmetic, can store as `cats.gradient_css text` or compute from photo

### Social features (deferred to v2)
- **Feed** of friends' sightings — needs `friendships` table
- **Reactions** (`❤️ 😮 😂`) on sightings — needs `reactions` table
- **Comments** on sightings — needs `comments` table
- **Cat following** — needs `cat_follows` table

### Gamification (deferred to v2)
- **Badges**: First Snap, Orange Obsessed, Night Owl, Week Streak, Sharp Eyes — derive from query patterns; minimal storage needed
- **Streaks** (consecutive days with a sighting) — compute from `sightings.seen_at`
- **Leaderboard** by sighting count + streak — compute from existing data

### Stats panel (compute from existing data)
- `streak`, `catsThisYear`, `totalSightings`, `rarestFind`, `topNeighbourhood`, `following`

## v1 vs design surface

The v1 schema (`docs/new-schema.sql`) intentionally cuts everything social/gamified and ships the core "snap a cat" loop first. The plan:

| Feature | v1 (now) | v2 (after v1 is shipped) |
|---------|----------|--------------------------|
| Snap photo + drop pin | ✅ | |
| Map view with pins | ✅ | |
| Cat profiles | ✅ | |
| Sighting list per cat | ✅ | |
| Tags on sightings | ✅ | |
| **Rarity** | ✅ (added to schema) | |
| User profile (basic) | ✅ | |
| Feed | ❌ | ✅ |
| Reactions / comments | ❌ | ✅ |
| Cat follows | ❌ | ✅ |
| Friends / friend requests | ❌ | ✅ |
| Badges | ❌ | ✅ |
| Streaks / leaderboard | ❌ | ✅ |

## Reference assets to extract during Phase 2 (Xcode build)

These need to come *into* the iOS project at some point:

- **Fonts** — download from Google Fonts: Plus Jakarta Sans, Fraunces, JetBrains Mono → drop into `Resources/Fonts/`
- **App icon** — export the `Window` mark from Brand System as a 1024×1024 PNG → `docs/icon-master.png`, then add to Xcode `Assets.xcassets/AppIcon.appiconset`
- **The `Window` mark itself** — port the SVG from `design-canvas.jsx` to a SwiftUI `Shape` in `Core/UI/CatWindowMark.swift`
- **Pin styles** — reference `CatSnap Map Pins.html` for variants when building the MapKit annotations
