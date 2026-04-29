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
- [ ] (Follow-up) Update `docs/brand.md` to sanction Fraunces on the snap button

## Phase 2 — Explore (screens 01 + 02)

- [x] `SpotsHeader`: map/list pill toggle (`Map` / `Guide`) + location search pill
- [x] `ExploreView` wrapper that owns the toggle state and swaps MapView ↔ GuideListView
- [ ] `GuideListView` body: progress bar (`23 / 60 · E. LONDON`), filter chips
      (All / ★ Legends / Rare / Today / Missing), 3-col grid with locked `?`
      silhouettes for unspotted cats (currently a placeholder)
- [ ] Live ticker chip on map view (`Marmalade just spotted · 60m away`)
- [ ] Bottom card peek with horizontal "nearby cats" rail
- [x] `PhotoPin` redesign: teardrop tail + ring + circular cat photo
      (replaces current `CatPin`); annotation anchor moved to `.bottom`
- [ ] User-location pulse marker (BLUE ring + dot)

## Phase 3 — Snap (screen 03)

- [ ] Dark camera screen (replaces today's nav-style `pickingPhoto` stage)
- [ ] `HOLD STEADY` reticle overlay
- [ ] Top hint card: `3 cats spotted on this street today`
- [ ] `VIDEO / PHOTO / BURST` mode selector (only PHOTO wired in v1)
- [ ] `UPLOAD` button (left) → routes to Phase 4
- [ ] Big shutter w/ `SNAP` label (center)
- [ ] `FLIP` camera button (right) — `AVCaptureDevice.Position` toggle

## Phase 4 — Upload from photos (screens 04 + 05 + 06)

- [ ] Camera-roll picker: chronological grid (`Today` / `This week` / month
      sections), no auto-detection copy, filters limited to
      `All / With location / Recent`
- [ ] Multi-select with coral border + check, sticky `Review N ›` footer
- [ ] Review screen: photo + `WHO IS THIS?` (`+ A new cat` / `From your guide`),
      EXIF date/time + GPS rows with `EXIF ✓` / `GPS ✓` pills, mini-map preview
- [ ] Date/time editor: quick chips (`Now` / `Today` / `Yesterday` / `Pick…`),
      HR:MIN nudge block
- [ ] EXIF extraction: `PHAsset.creationDate`, `PHAsset.location`
- [ ] Reuse existing `create_sighting_with_cat` RPC — no schema change

## Phase 5 — Name & tag + Spotted! (screens 07 + 08)

- [ ] Restyle Submit's `editing` stage to match the NameTag layout
- [ ] Tag chips, "is this a regular?" match suggestions
- [ ] `SpottedConfirm` success screen: coral gradient hero + award unlock card
- [ ] Wire success → existing `NotificationCenter.sightingSubmitted` post

## Phase 6 — Cat profile (screen 09)

- [ ] Hero photo + rarity badge restyled
- [ ] Stats card (last seen, total spots, regulars)
- [ ] Home-range mini-map
- [ ] `I spotted them!` CTA → Submit prefilled (existing wiring preserved)
- [ ] Sightings grid restyled

## Phase 7 — You (screen 10)

- [ ] Avatar + display name + handle
- [ ] Stats grid (cats / spots / streak)
- [ ] Awards grid with one yellow rare treatment + offset shadow
- [ ] 14-day streak heatmap (ink/yellow combo)
- [ ] `Friends` section header (tappable, links to v2 feed when shipped)
- [ ] `+ Add` button (v2 wiring)

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
