# CatSnap — Remaining Steps to App Store

**Verified**: 18 August 2026, by building and running the app and inspecting the live Apple accounts.

The previous version of this file claimed "95% ready for TestFlight". That was
never verified against a build. **The tree did not compile.** Corrected below.

---

## Verified working

| Item | Evidence |
|---|---|
| App compiles and runs | Debug build succeeds, launches on iPhone 17 Pro simulator, onboarding renders |
| Bundle ID registered | `com.jadaross.CatSnap`, team `DFFRB59G23`, portal confirmed |
| Sign in with Apple | Enabled on the App ID, "Enable as a primary App ID" — portal confirmed |
| Privacy policy live | https://jadaross.github.io/cat-snap/privacy-policy.html → 200 |
| Terms live | https://jadaross.github.io/cat-snap/terms-of-service.html → 200 |
| App icon | 1024×1024 present in the asset catalog |
| App Store name | **CatSnap** — no hyphen (decided 18 Aug 2026) |
| Support domain | `catsnap.app` resolves, MX (Namecheap forwarding) configured |
| Account deletion, block/report | Shipped — see launch-checklist.md §5 A1/A2 |

## Fixed in commit `b49d493`

- `CatSnapApp.swift` — `options.sessionTracking` is not a member of sentry-cocoa
  8.x `Options`. Correct name is `enableAutoSessionTracking`. Hard compile error.
- `SpotConfirmSheet.swift` — `[weak self]` inside a SwiftUI `View` struct.
  `weak` requires a class type. Hard compile error.
- `TARGETED_DEVICE_FAMILY` `1,2` → `1`. iPad is deferred to v2 but the project
  advertised support, which puts the app in front of reviewers on iPad and
  requires a separate iPad screenshot set.
- iPhone orientations narrowed to portrait only.
- `Info.plist` — added `ITSAppUsesNonExemptEncryption = false`, so the export
  compliance prompt does not block every TestFlight upload.

## Fixed on `gh-pages` (commit `4953b35`)

The app links to `/cat-snap/privacy-policy.html`, but the files only existed
under `/docs/`. **Both in-app links were 404ing.** Copied to the publishing root.

---

## Blockers — must be done by hand

### 1. Accept the App Store Connect Terms of Service — ✅ DONE 18 Aug 2026

Accepted. This also activated the Free Apps Agreement
(18 Aug 2026 – 30 Apr 2027), which is what permits free-app distribution.

### 2. Install Xcode's iOS platform — DONE, but note the cause

Xcode 26.6 ships the iOS 26.5 SDK; only the 26.4 simulator runtime was
installed, so `xcodebuild` reported **zero eligible destinations** and no build
of any kind could run. Resolved by `xcodebuild -downloadPlatform iOS` (8.5 GB).
Re-check after any Xcode update.

### 3. Register a device — ✅ DONE 18 Aug 2026

"Mokos iPhone" (iPhone 16, UDID `00008140-001D546E0E89401C`) registered in
the portal. Note: connecting the cable is NOT enough — `xcodebuild` never
registers devices, only Xcode.app does, so this was registered by hand.
Archiving failed with "Your team has no devices" until it was.

### 4. Create the distribution certificate — ✅ DONE 18 Aug 2026

Minted automatically during `xcodebuild -exportArchive -allowProvisioningUpdates`.
The IPA is signed `Apple Distribution: Moko Ross (DFFRB59G23)` with an
"iOS Team Store Provisioning Profile" and `get-task-allow = false`.

### 5. Archive and upload — ✅ DONE 18 Aug 2026, build 1.0 (1)

Correcting an earlier note in this file: the archive does **not** require the
Xcode GUI. `xcodebuild archive` + `xcodebuild -exportArchive` with
`-allowProvisioningUpdates` works end to end, including minting the
distribution certificate and uploading. The earlier failures were the missing
registered device, not a CLI limitation.

Verified in the uploaded binary: `UIDeviceFamily = [1]`, iPhone orientations
portrait-only, `ITSAppUsesNonExemptEncryption = false`, usage strings renamed
to CatSnap, and a resolving `SENTRY_DSN`.

### 6. Create the App Store Connect record — ✅ DONE 18 Aug 2026

Created as **CatSnap** (no hyphen), iOS, English (U.K.), bundle ID
`com.jadaross.CatSnap`, SKU `CATSNAP001`. Status: "Prepare for Submission".

Note there are two bundle IDs on the account — `com.jadaross.cat-snap` is a
leftover from the retired web project and is *not* the one to use.

### 7. Declare EU Digital Services Act trader status — ✅ SUBMITTED 18 Aug 2026

Declared and recorded against the 27 EU territories. Status is **In Review** —
Apple verifies the declaration, so it is not instant. Check back on the
Business tab; EU availability depends on it clearing.

---

## Non-blocking, but worth doing

- **Screenshots.** Correcting an earlier note in this file: the live App Store
  Connect form for this record asks for **iPhone 6.5"** —
  1284 × 2778 or 1242 × 2688. Apple states these are reused for *all* display
  sizes, so one set is enough; the 6.7"/6.1" pair in `launch-checklist.md`
  §7 C15 and the "6.9" required" note I wrote earlier are both wrong.
  Up to 10 allowed, first 3 appear on the install sheet. Needs real seeded
  data — an empty map makes a poor screenshot.

- **Demo account for App Review — easy rejection if missed.** Every screen in
  CatSnap is behind the auth gate, and the version page has "Sign-in required"
  ticked. Apple must be given a working username and password under
  App Review Information or the review cannot proceed. Create a throwaway
  account seeded with a few sightings so the reviewer sees a populated app.
- **SMTP.** Email confirmation is on but no provider is wired. Default Supabase
  SMTP is rate-limited and lands in spam. Resend or Postmark.
- **Sentry dSYM upload failed.** The build uploaded, but symbol upload warned:
  "archive did not include a dSYM for Sentry.framework". Crash reports from
  inside the Sentry SDK itself will be unsymbolicated. App-code crashes are
  unaffected. Fix by setting `DEBUG_INFORMATION_FORMAT = dwarf-with-dsym` for
  dependencies, or upload dSYMs to Sentry manually.
- **Localization is inert.** 36 `String(localized:)` call sites but no string
  catalog exists, so nothing is actually localizable. Fine for an en-only v1 —
  the scaffolding is there — but it does not do anything yet.
- **Confirm `support@catsnap.app` delivers.** It appears in the app, the privacy
  policy, and the terms. The domain has email forwarding configured; send a
  test to be sure it reaches you.
- **App icon appearance variants.** The same full-colour PNG is used for the
  universal, dark, and tinted slots. Legal, but the tinted variant will look
  poor. Supply a proper grayscale tinted version, or drop those two slots.
- **Notification permission with no notifications.** Onboarding requests
  notification authorization but there is no APNs handler and nothing ever
  sends one. Reviewers occasionally flag this. Consider dropping the step.

---

## Order to do things in

1. ~~Accept the App Store Connect ToS.~~ done
2. ~~Create the App Store Connect record.~~ done — CatSnap
3. ~~Declare DSA trader status.~~ submitted, In Review at Apple
4. Plug in your iPhone so it gets registered.
5. Set the Sentry DSN before building (it is baked in at build time).
6. Xcode → Product → Archive. Let it create the distribution certificate.
7. Distribute App → App Store Connect → upload.
8. Wire Supabase SMTP while the build processes.
9. Internal TestFlight, daily-drive it, seed real data.
10. Capture 6.9" screenshots from the seeded app.
11. Fill in description, keywords, privacy nutrition labels, support URL.
12. Submit.

Run `./scripts/ship-to-testflight.sh` to be walked through steps 3-9.
