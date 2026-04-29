# Brand

Single source of truth for Cat-Snap's visual identity. Extracted from the design system at `~/Downloads/cat-snap-branding-and-design/CatSnap Brand System.html`. The full design folder stays in Downloads — see `docs/design-reference.md` for what's there.

## Identity

| Field | Value |
|-------|-------|
| App name | **Cat-Snap** (display: lowercase italic, "cat" + coral "snap") |
| Tagline | **"spot every cat."** |
| Bundle identifier | `com.jadaross.catsnap` (lowercase, no hyphens) |
| Voice | Warm, observational, narrative ("the cat at the window") — never overly cute |

## The mark

A cat at a window. The frame holds the brand together — every cat fits in it, every coat colour, every rarity. It works as logo, empty state, avatar frame, and merch.

- Drawn on a **200-unit grid**
- Frame stroke = sill height = **14u**
- Mullion = **4u**
- Cat is clipped to the glass — never escapes the window
- Minimum size **16px**; below that, drop the cat and use just the frame
- Clear-space = **½ frame width** on all sides

Reference artwork: see `~/Downloads/cat-snap-branding-and-design/CatSnap Brand System.html` (rendered) or `design-canvas.jsx` (the `Window` component, ~150 lines from top).

## Wordmark

- **Primary**: Fraunces, weight **900**, italic. "cat" in Ink + "snap" in Coral. Letter-spacing ~ -0.8.
- **Sans alternate** (when serif unavailable): Plus Jakarta Sans, weight **800**, same colour split.

## Color palette (light only)

| Token | Hex | Role |
|-------|-----|------|
| Cream | `#f7f4ee` | Background |
| Cream Soft | `#fffbf2` | Surface (cards, sheets) |
| Cream Deep | `#ebe4d6` | Hover, dividers |
| Ink | `#252220` | Type, cat silhouette |
| Stone | `#807a72` | Muted text |
| Stone Light | `#e7e1d6` | Subtle borders |
| **Coral** | `#ff6b5b` | **Primary** — frame, buttons, brand moments |
| Coral Deep | `#d44a3a` | Pressed state, accent |
| Streetlamp Yellow | `#fcd34d` | Highlight, cat eyes |
| Streetlamp Yellow Deep | `#f59e0b` | Eye outline, text on yellow |
| Sage | `#7a9b7e` | Rarity (uncommon) |

**Restraint rules:**
- Yellow + sage are **highlight only** — never the wordmark, never large surfaces
- The wordmark is **always** Ink + Coral; never substitute another colour
- No dark mode in v1 — the brand is "light only"

### Rarity colours

For rarity badges/tags. Source: `catsnap-data.jsx` `RARITY` constant.

| Rarity | Color | Background |
|--------|-------|-----------|
| Common | `#a8a29e` (stone) | `#f5f5f4` |
| Uncommon | `#16a34a` (sage-aligned) | `#dcfce7` |
| Rare | `#2563eb` (blue) | `#dbeafe` |
| Legendary | `#d97706` (amber-deep, w/ ★) | `#fef3c7` |

## Typography

| Role | Font | Source | Notes |
|------|------|--------|-------|
| UI / body | **Plus Jakarta Sans** (400–800) | Google Fonts | Default for all interface text |
| Display / serif | **Fraunces** (italic 900) | Google Fonts | Wordmark and headline moments only |
| Mono accents | **JetBrains Mono** (400–700) | Google Fonts | Small labels, metadata, system v1 stamps |

In SwiftUI (Phase 2), these will load via `Font.custom` from the bundled `.ttf` files. Drop the Google Fonts files into `Resources/Fonts/` and register in `Info.plist`'s `UIAppFonts`.

System fallback: `system-ui` → SF Pro for body, Times for serif. Keep brand on first paint by bundling fonts.

## App icon

Spec: 1024×1024 PNG, no transparency, no rounded corners (iOS rounds them). Apple auto-generates the size variants from the master.

The icon should use the cat-at-the-window mark on a Cream Soft (`#fffbf2`) or Coral (`#ff6b5b`) background — final call TBD. Reference variants in `CatSnap Brand System.html` ("App icons" canvas).

Master file goes at `docs/icon-master.png` once exported.

## Voice & tone

- **The frame is the brand.** Every cat fits in the frame — coats, colours, rarity. Brand language often references "spotting," "framing," "windows," "the moment."
- **Observational, not cutesy.** Prefer "spotted Marmalade in Brick Lane" over "OMG kitty 😻 found!!"
- **Light gamification.** Rarity tiers, badges, streaks are real product surfaces — name them with confidence ("Legendary find ★", "7-day streak"), not apology.
- **System voice** (e.g. mono "system v1 · 2026" timestamps) stays out of marketing-facing copy.

## Where these decisions show up in code

- **Colors** → `Core/UI/BrandColors.swift` in Phase 2 (Color extensions like `Color.coral`, `Color.cream`)
- **Fonts** → `Resources/Fonts/*.ttf` registered in `Info.plist` → `Core/UI/BrandFonts.swift`
- **Mark** → `Core/UI/CatWindowMark.swift` — port the SVG `Window` component from `design-canvas.jsx` to a SwiftUI `Shape`
- **App name** → Xcode project name, `Info.plist` `CFBundleName`, App Store listing
- **Bundle ID** → Xcode "Bundle Identifier"; can't change after first App Store submission
- **Tagline** → App Store subtitle, onboarding copy
