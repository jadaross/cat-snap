# Feature Plan

Cat Snap is built in phases. Each phase ships a usable product.

---

## Phase 1 — MVP: Snap, Tag, Discover

**Goal:** A working map where people can log cat sightings and browse what others have spotted.

### Core features

- **User auth** — Sign up / sign in with email or Google
- **Snap a sighting**
  - Take or upload a photo
  - Drop a pin on the map (auto-fills from GPS)
  - Add a nickname, brief description, and tags (friendly, shy, fluffy, tabby, etc.)
  - Submit sighting
- **Map view**
  - Interactive Mapbox map showing recent sightings as photo pins
  - Tap a pin to see the photo, name, and description
  - Filter by recency (today, this week, all time)
- **Cat profile page**
  - All sightings linked to the same cat
  - Photo gallery of sightings over time
  - Last seen location and timestamp
  - Description, nickname, and community-added tags
  - "I saw this cat today!" check-in button
- **Basic user profile**
  - Sightings submitted by the user
  - Total cats spotted count

### Out of scope for MVP
- Social/friend features
- Notifications
- Cat identity matching / deduplication

---

## Phase 2 — Social: Friends & Feed

**Goal:** Turn individual spotters into a community. Add the social graph that makes Cat Snap sticky.

### Features

- **Friend system**
  - Search for users by username
  - Send / accept friend requests
  - View a friend's public profile and their sightings
- **Activity feed**
  - Chronological feed of sightings from friends
  - "Jada spotted Whiskers near Main St — 2 hours ago"
  - See friend check-ins on cats you've also seen
- **Reactions** — React to sightings (heart, surprised, etc.)
- **Comments** — Comment on a sighting
- **Cat followers** — Follow a specific cat to get notified when it's seen
- **Sighting privacy** — Public / friends-only / private per sighting
- **Notifications**
  - A cat you follow was spotted
  - A friend reacted to your sighting
  - Someone you know saw a cat near you

---

## Phase 3 — Intelligence: Cat Identity & Recognition

**Goal:** Reduce duplicate cat entries. Help the community match sightings of the same cat across users.

### Features

- **"Is this the same cat?" prompt** — When submitting a sighting, show nearby cats with similar appearance and ask the user to link or dismiss
- **Cat merging** — Moderators or cat creators can merge two cat profiles
- **AI-assisted matching** — Use vision model to suggest matches based on fur pattern, color, and markings (not full facial recognition, just similarity scoring)
- **Sighting confidence score** — Show how confident the community is that sightings belong to the same cat
- **Sighting timeline** — Visual timeline showing a cat's movement across the neighborhood over weeks/months

---

## Phase 4 — iOS App

**Goal:** Native iOS app with full feature parity. The backend API is already built; this is a new frontend.

### Approach

- Build with Swift / SwiftUI consuming the existing REST API
- OR React Native to share code with the web app (evaluate at the time)
- Native camera integration (faster, better photo quality)
- Push notifications
- Location services in background (optional opt-in for auto check-ins)
- Widgets: "Cats spotted near you today"

---

## Future Ideas (Backlog)

- **Cat care status** — community-sourced info: this cat is fed daily, this cat is TNR'd
- **Heat map view** — where are cats most commonly seen in the city?
- **Cat birthday / first seen anniversary** — celebration moment
- **Leaderboards** — most cats spotted this month in your city
- **Neighborhoods** — group cats by human-defined neighborhood zones
- **Sticker packs** — unlock stickers based on cats spotted
- **Export / share** — share a cat's profile as a card to social media
- **API for TNR orgs** — let volunteer organizations import Cat Snap data for their workflows
