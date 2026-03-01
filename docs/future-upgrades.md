# Future Upgrades

A backlog of enhancements, organised by theme and rough priority. These are deliberately not in the MVP to keep the initial build focused.

---

## Cat Intelligence

### Cat Identity Matching (High value)
When a user submits a sighting, show nearby existing cats with similar appearance and let them link the sighting to an existing profile instead of creating a duplicate. This solves the core UX problem of "Orange Tabby on Main St" being logged ten times as ten separate cats.

**Implementation ideas:**
- On sighting creation, query for cats spotted within 500m in the last 30 days
- Show a modal: "Is this the same cat as one of these?" (show thumbnails)
- Allow community merging: anyone can suggest a merge; cat creator approves
- Later: embedding-based similarity search on cat photos (CLIP model)

### AI Photo Analysis
Run each uploaded photo through a vision model to:
- Suggest tags automatically (tabby, orange, long-haired, kitten, etc.)
- Detect approximate cat colour/markings for matching
- Flag non-cat photos before they're saved

**Stack:** OpenAI Vision API or run `clip-vit` via Replicate/Modal for batch processing.

### Cat Trajectory Visualisation
Show a cat's movement over time as an animated path on the map. "Whiskers has been spotted in a 3-block radius over the past 6 months."

---

## Social & Community

### Friend Requests & Discovery
Full friend system UI: search by username, send/accept/decline requests, see pending requests badge. Currently the data model supports it — the UI needs building.

### Push Notifications
- A cat you follow was just spotted nearby
- Someone reacted to your sighting
- You got a new friend request
- A cat you follow hasn't been seen in 30 days ("Felix hasn't been spotted in a while 😟")

**Stack:** Web Push API for web; APNs for iOS. Trigger from Supabase Edge Functions listening to DB changes.

### Sighting Streaks & Gamification
- "You've logged sightings 5 days in a row!" streak counter
- Badges: First Sighting, 10 Cats Spotted, Cat Whisperer (100 sightings), Neighbourhood Watch
- Monthly leaderboard: most cats spotted in your city this month

### Neighbourhood Groups
Let users define or join neighbourhood zones (Greenwich Village, Mission District, etc.). Sightings automatically tagged to a neighbourhood. Neighbourhood-specific feeds and leaderboards.

---

## Map & Discovery

### Heat Map View
Toggle between pin view and a heat map showing cat density across the city. Useful for understanding which blocks are cat hotspots.

### Cluster Mode
At low zoom levels, group nearby pins into a cluster bubble showing the count. Click to zoom in and expand. Essential for cities with many sightings.

### Saved Areas / Subscriptions
"Watch" a geographic area (e.g. your commute route). Get notified when new cats are spotted there.

### Time-Lapse Slider
Slider on the map to show sightings from a specific date range. Watch the neighbourhood cats shift over seasons.

---

## Cat Profiles

### Community Editing
Allow any logged-in user to suggest edits to a cat's name, description, or status (TNR, caretaker). Original creator approves changes. Like a wiki model.

### Cat Care Status
Community-maintained fields:
- Is this cat regularly fed? By whom?
- TNR status (yes/no/unknown)
- Friendly / shy / feral temperament
- Known health issues or injuries

### Cat Anniversary & Birthday
Track first-ever sighting date as "discovery date." Send a notification on the anniversary. Let the community celebrate.

### Memorial
Mark a cat as deceased with a final note. Keep the profile as a memorial rather than deleting it.

---

## Platform

### Progressive Web App (PWA)
Add a web app manifest and service worker so users can install Cat Snap on their home screen and use it with a near-native feel before the iOS app ships. Enables:
- Add to Home Screen on iOS/Android
- Offline caching of the map tiles and recently viewed profiles
- Background sync for sightings logged offline

### iOS App
Native Swift/SwiftUI app consuming the existing REST API. Advantages over PWA:
- Native camera with live viewfinder
- Background location for automatic check-ins (opt-in)
- Push notifications via APNs
- Haptic feedback
- Lock screen / home screen widgets ("3 cats spotted near you today")

Consider React Native + Expo if you want to share business logic with the web app.

### Android App
Follow iOS. Either React Native (shares iOS codebase) or separate Kotlin/Compose.

### API for TNR Organisations
Publish a read-only API that trap-neuter-return volunteers and colony managers can query to get community sighting data for their area. Could become a B2B/nonprofit partnership opportunity.

---

## Monetisation (Optional Long-Term)

| Idea | Model |
|------|-------|
| Cat Snap Pro | Subscription: advanced map filters, export data, no ads |
| City Partnerships | Municipal animal services pay for access to aggregated sighting data |
| Shelter Integration | Shelters pay to list adoptable cats that match community cat profiles (potential matches) |
| Merchandise | Cat Snap stickers, prints of popular community cats |
| Donations | "Sponsor a cat" — donate toward TNR costs for a cat on the map |

---

## Technical Debt / Infrastructure

### Real-time Feed
Replace the static server-rendered feed with a Supabase Realtime subscription so new sightings appear instantly without refresh.

### Image CDN & Transforms
Use Supabase Storage's image transformation API (or Cloudinary) to serve correctly sized thumbnails instead of always loading full-res photos.

### Full-text Search
Add `pg_trgm` or Typesense for fast cat/user search across the whole catalogue.

### Rate Limiting
Add API rate limiting (via Upstash Redis or Vercel Edge Middleware) to prevent abuse — particularly on the photo upload endpoint.

### Moderation
- Report button on sightings and cats
- Admin dashboard to review reported content
- Automated NSFW photo screening (AWS Rekognition or similar)

### Analytics
Integrate PostHog or Plausible (privacy-friendly) to understand which features get used and where users drop off in the sighting submission flow.
