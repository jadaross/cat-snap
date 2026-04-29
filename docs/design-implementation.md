# Design implementation tracker

Source: handoff bundle `o_yBL7-PGGclDDuU0JfJ7w` (`cat-snap/project/CatSnap App.html`).
Final intent landed in chat3.md: **3 tabs** (Explore / Snap / You), upload-from-photos
flow with no auto-detection copy, friends absorbed inside You.

The design has 12 screens. Each phase below ends in a green build and can ship
on its own.

| # | Screen (in design)            | Phase |
|---|-------------------------------|-------|
| 01| Explore — map                 | 2     |
| 02| Explore — list / guide        | 2     |
| 03| Snap (live)                   | 3     |
| 04| Upload from photos            | 4     |
| 05| Review sighting               | 4     |
| 06| Date/time edit                | 4     |
| 07| Name & tag                    | 5     |
| 08| Spotted!                      | 5     |
| 09| Cat profile                   | 6     |
| 10| You                           | 7     |
| 11| Friends · activity            | 8 (v2)|
| 12| Add friends                   | 8 (v2)|

---

## Phase 1 — Bottom tab bar

- [x] `CatSnapTabBar` (3-zone, overflowing 96pt snap button, Fraunces label)
- [x] Custom glyphs (`ExploreGlyph`, `ProfileGlyph`, `CameraGlyph`)
- [x] `MainTabView` rewrite (ZStack + fullScreenCover preserved)
- [ ] (Follow-up) Bundle `PlusJakartaSans-ExtraBold` for true 800-weight tab labels
- [x] (Follow-up) `docs/brand.md` updated to sanction Fraunces on the
      floating Snap button label

## Phase 2 — Explore (screens 01 + 02)

- [x] `SpotsHeader`: map/list pill toggle (`Map` / `Guide`) + location search pill
- [x] `ExploreView` wrapper that owns the toggle state and swaps MapView ↔ GuideListView
- [x] `GuideListView` body: progress bar (count vs total cats in DB),
      All / ★ Legends / Rare / Today / Missing filter chips, 3-col grid
      with locked `?` silhouettes for un-spotted cats. New `GuideModel`
      pulls all cats + the current user's sightings; tap an unlocked
      cat → push CatProfileView via the list's own NavigationStack.
- [ ] (Follow-up) Region label: today shows raw count; design wants
      `23 / 60 · E. LONDON` once a region concept is added server-side
- [x] Live ticker chip on map view: shows the most recent sighting in the
      last hour, pulse dot, tap to centre + select on the map
- [x] Bottom card peek with horizontal "nearby cats" rail; tap card → focus
      sighting on the map. Uses `distance_m` from the `sightings_near` RPC
      for each card's meta line.
- [x] `PhotoPin` redesign: teardrop tail + ring + circular cat photo
      (replaces current `CatPin`); annotation anchor moved to `.bottom`
- [ ] User-location pulse marker (BLUE ring + dot)

## Phase 3 — Snap (screen 03)

- [x] Dark gradient screen replaces the `pickingPhoto` stage; nav bar
      hidden + `.preferredColorScheme(.dark)` so the iOS status bar reads
      light against the gradient
- [x] Top tip card (placeholder copy — "photo will be tagged with your
      location")
- [x] `VIDEO / PHOTO / BURST` mode selector (visual only — only PHOTO is
      reachable in v1)
- [x] `UPLOAD` glass chip on the left — opens PhotosPicker
- [x] Shutter w/ `SNAP` label — opens the existing UIImagePickerController
- [x] Custom xmark dismiss button top-leading
- [ ] (Follow-up) `HOLD STEADY` reticle — needs an AV preview to feel real,
      skipped for now since we hand off to the system picker
- [ ] (Follow-up) `FLIP` button is decorative; rewire once we host an
      AVCaptureSession instead of UIImagePickerController

## Phase 4 — Upload from photos (screens 04 + 05 + 06)

- [x] EXIF extraction utility (`Core/Util/ExifMetadata.swift`) using
      ImageIO — pulls `DateTimeOriginal` and GPS lat/lng straight out of
      the JPEG bytes; no Photos-library permission needed
- [x] `SubmitModel.acceptUploadedPhoto(_:exif:)` accepts a picked photo
      with its EXIF, pre-fills location + reverse-geocoded label, and
      skips the live-location step entirely when GPS is present
- [x] Submit RPC payload uses `exifSeenAt ?? Date()` so the sighting
      timestamps to when the photo was taken, not when it was logged
- [x] Editor photo card shows `EEE · HH:mm · LOCATION` when from camera
      roll, or `FROM CAMERA ROLL` when GPS-only
- [ ] (Follow-up) Camera-roll picker: chronological grid + multi-select
      sticky `Review N ›` footer (current PhotosPicker is single-select)
- [ ] (Follow-up) Standalone review screen with `EXIF ✓ / GPS ✓` pills
      and mini-map preview before the editor
- [ ] (Follow-up) Date/time editor with quick chips (`Now / Today /
      Yesterday / Pick…`)

## Phase 5 — Name & tag + Spotted! (screens 07 + 08)

- [x] Restyle Submit's `editing` stage: rounded photo card with coral
      "JUST NOW · {locality}" badge, mono section labels, sticky bottom
      "Pin {name} on the map →" CTA
- [x] Tag chips already in place — kept the existing TagChip presets
- [x] `SpottedConfirm` success screen: cat window mark with sage pulse
      halo, sage check badge, +1 SIGHTING mono coral, Fraunces "name
      spotted!" headline, ink "See on the map" CTA
- [x] Existing `.sightingSubmitted` NotificationCenter post is preserved
- [ ] (Follow-up) "IS THIS A REGULAR?" match suggestions row — needs a
      cat-similarity backend call; deferred
- [ ] (Follow-up) Award unlocked card on Spotted! — needs an awards
      backend; deferred to v2

## Phase 6 — Cat profile (screen 09)

- [x] Full-bleed hero photo with darkening gradients top + bottom
- [x] Glassy back + ellipsis buttons over the hero (back wires to dismiss)
- [x] Hero title block: rarity capsule + Fraunces lowercase name +
      "last seen Xm ago" subtitle
- [x] 3-up stats row (sightings / unique spotters / known-for days)
- [x] Recent-sightings grid restyled at 3 columns, capped at 9 with
      "SEE ALL" stamp
- [x] Sticky CTA: coral "I spotted them!" + cream heart side-button
      (heart inert until v2 favourites)
- [ ] (Follow-up) Home-range mini-map — needs a way to render an MKMap
      snapshot constrained to the cat's sighting bounds

## Phase 7 — You (screen 10)

- [x] Coral header: cream-soft wordmark + settings gear menu, rounded-16
      avatar tile (76pt), Fraunces display name + `@username`, dark-tinted
      stats row (SIGHTINGS / CATS / STREAK / AWARDS)
- [x] Awards grid: 4-column 12-tile grid with computed local awards
      (First Snap, streaks, night-owl etc.), yellow + ink-bordered rare
      tiles with offset 2x2 shadow
- [x] Streak card: ink bg, yellow `CURRENT STREAK` mono, 56pt Fraunces
      day count, 17-cell heatmap; current streak computed by walking
      backward from today through the user's sightings
- [x] Settings gear menu hosts edit profile + sign out (replaces the old
      toolbar button)
- [x] `my sightings` grid kept until friends activity feed lands
- [ ] (Follow-up) Friends section header + `+ Add` row — wired in
      Phase 8 (v2)
- [x] (Follow-up) Streak is now anchored to the most recent active day
      in {today, yesterday} so it survives mornings before the user logs
      a sighting

## Phase 8 — Friends (screens 11 + 12) · DEFERRED to v2

Per `docs/ios-rebuild.md`: friend system, follows, comments, reactions are not
in v1 scope. Track here so the design isn't lost.

- [ ] Friends activity feed (photo cards, achievement cards, "I see them too")
- [ ] Add friends (search, scan QR, share invite, suggested spotters)
- [ ] Schema additions: `friendships`, follow graph, activity events

---

## Brand-discipline notes

- The design uses Fraunces 900 italic on the **snap button label**. `docs/brand.md`
  currently restricts Fraunces to wordmark-only — once Phase 1 ships, sanction this
  use explicitly so future contributors don't unwind it.
- The `VIDEO / BURST` mode labels and `UPLOAD` / `FLIP` micro-copy are JetBrains
  Mono uppercase. Stick to that even when wiring stubs.
