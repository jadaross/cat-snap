# App Icon Creation Guide

## Requirements

- **Master size**: 1024×1024 PNG
- **No transparency** (solid background)
- **No rounded corners** (iOS rounds them automatically)
- **Format**: PNG (24-bit or 32-bit RGB)
- **Color space**: sRGB

## Design Specifications

### Brand Guidelines
According to `docs/brand.md`:

- Use the **cat-at-the-window mark** (see `CatWindowMark.swift` for reference)
- Background should be **Cream Soft** (`#fffbf2`) or **Coral** (`#ff6b5b`)
- Final background color TBD (your choice)
- Reference variants in design system: `~/Downloads/cat-snap-branding-and-design/CatSnap Brand System.html`

### Visual Elements
- **Cat silhouette**: Black/Ink color (`#252220`)
- **Window frame**: Should use brand coral color (`#ff6b5b`)
- **Clear space**: ½ frame width on all sides
- **Minimum size**: 16px (below this, use frame only)

## Creation Options

### Option 1: Use Existing Design Files
Check your design folder:
```bash
ls ~/Downloads/cat-snap-branding-and-design/uploads/
```

The current available files:
- `pasted-1777451443115-0.png` (3000×2249) - May contain app icon design
- Other smaller PNG files that might be design assets

### Option 2: Create from SwiftUI Code
The `CatWindowMark.swift` component has the cat-at-the-window mark. You could:
1. Create a test app that renders the mark at 1024×1024
2. Take a screenshot or export as image
3. Add appropriate background in image editor

### Option 3: Use Design Tools
1. Open the design reference: `~/Downloads/cat-snap-branding-and-design/CatSnap Brand System.html`
2. Look for "App icons" canvas
3. Export the design as 1024×1024 PNG
4. Ensure no transparency, solid background

### Option 4: Manual Creation
1. Create 1024×1024 canvas in Figma/Sketch/Photoshop
2. Fill with Cream Soft (`#fffbf2`) or Coral (`#ff6b5b`)
3. Add cat-at-the-window mark from design system
4. Export as PNG

## Required Sizes

Once you have the master 1024×1024 PNG, Apple auto-generates all required sizes for:
- iPhone (various sizes)
- iPad (various sizes)  
- App Store (1024×1024)
- Settings, Spotlight, etc.

## Where to Place the Icon

1. Save your master as `docs/icon-master.png` (for reference)
2. Copy the 1024×1024 PNG to: `CatSnap/CatSnap/Assets.xcassets/AppIcon.appiconset/`
3. Name it appropriately (e.g., `1024x1024.png`)
4. Update `Contents.json` if needed (Xcode 16+ usually handles this automatically)

## Xcode Asset Catalog Setup

The current `Contents.json` expects:
- Universal 1024×1024 (main icon)
- Dark mode variant (optional, but brand is light-only)
- Tinted variant (optional)

For v1 (light-only brand), you can simplify to just the universal size.

## Verification

After adding the icon:
1. Open Xcode
2. Navigate to `Assets.xcassets/AppIcon.appiconset`
3. Verify the icon appears correctly
4. Build and run on simulator to check icon appearance
5. Test on home screen, settings, and app switcher

## Brand Compliance Checklist

- [ ] Uses cat-at-the-window mark (or brand-appropriate design)
- [ ] Background is Cream Soft (`#fffbf2`) or Coral (`#ff6b5b`)
- [ ] No transparency (solid background)
- [ ] No rounded corners in source file
- [ ] 1024×1024 dimensions exactly
- [ ] sRGB color space
- [ ] PNG format
- [ ] Follows brand color palette
- [ ] Clear space maintained around mark
- [ ] Works well at small sizes (home screen)

## Temporary Solution

If you don't have design access immediately, you can:
1. Use a placeholder icon for testing
2. Submit with placeholder for TestFlight (Apple allows this)
3. Update with final icon before App Store submission
4. Use a simple colored square with brand colors as interim

## Recommended Next Steps

1. Check the design files in `~/Downloads/cat-snap-branding-and-design/uploads/`
2. Open the brand system HTML to see if app icons are already designed
3. If designs exist, export them at 1024×1024
4. If not, decide on background color (Cream Soft vs Coral)
5. Create the icon using your preferred method
6. Place in the asset catalog
7. Test on device

## Alternative: Use Online Icon Generator

If you have a logo but not all sizes:
1. Use services like AppIconGenerator or MakeAppIcon
2. Upload your 1024×1024 master
3. Download the complete asset catalog
4. Replace the AppIcon.appiconset contents

## Notes

- The brand is "light only" for v1, so dark mode variant is optional
- Tinted variant is optional for v1
- Focus on getting a good 1024×1024 master first
- Apple's automatic generation handles all other sizes
- Test on real device to ensure icon looks good at various sizes