# Brand exports

Raster exports of the cat-at-the-window mark. **Generated — don't hand-edit.**

Everything here is rendered from `CatSnap/CatSnap/Core/UI/CatWindowMark.swift`
via `ImageRenderer`, so the PNGs are the same geometry the app draws rather than
a redraw. To change them, change the SwiftUI source and re-run:

```sh
./docs/brand-exports/render.sh
```

The script copies the mark + `BrandColors.swift` into the throwaway SwiftPM
target in `render/`, renders, and deletes the copies — there is no second copy
of the artwork to drift.

## Files

| File | Size | Alpha | Use |
|---|---|---|---|
| `AppIcon-creamsoft-1024.png` | 1024² | none | App icon candidate — Cream Soft `#fffbf2` field |
| `AppIcon-coral-1024.png` | 1024² | none | App icon candidate — Coral `#ff6b5b` field |
| `cat-window-mark-1024.png` | 1024² | yes | Mark on its native canvas, transparent |
| `cat-window-mark-512.png` | 512² | yes | ″ |
| `cat-window-mark-256.png` | 256² | yes | ″ |
| `cat-window-mark-128.png` | 128² | yes | ″ |
| `cat-window-mark-nosill-1024.png` | 1024² | yes | Sill-less variant (what the app uses small) |
| `cat-window-mark-cream-1024.png` | 1024² | none | Mark on Cream `#F7F4EE`, for decks |

## App icon notes

Per `docs/app-icon-specs.md` the background must be **Cream Soft** or **Coral**,
and the final choice is still TBD — hence two candidates. Once picked:

1. Copy it to `CatSnap/CatSnap/Assets.xcassets/AppIcon.appiconset/`
2. Fill in `Contents.json` (all three slots are currently empty)
3. Optionally also save it as `docs/icon-master.png`, which the spec asks for

Two things the renderer handles that are easy to get wrong by hand:

- **No alpha channel.** `ImageRenderer.isOpaque = true` still leaves a
  fully-opaque alpha channel on the `CGImage`, which App Store Connect rejects.
  The opaque exports are redrawn through a `CGContext` with `noneSkipLast` to
  drop the channel outright.
- **Optical centring.** The mark's content occupies x 14–186, y 22–184 of its
  200-unit canvas, so centring the canvas box sits the artwork low and left.
  The icon composition centres on the real visual bounds instead.

On the coral field the coral window frame would disappear, so that variant flips
the frame to Cream Soft and the glass to Cream to keep the mullions readable.
