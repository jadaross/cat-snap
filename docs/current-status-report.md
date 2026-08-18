# Cat-Snap — Remaining Steps to App Store

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

### 1. Accept the App Store Connect Terms of Service — HARD BLOCKER

https://appstoreconnect.apple.com is showing a full-page Terms of Service
modal. Nothing can proceed until it is accepted: no app record, no build
upload, no TestFlight. This is a legal agreement and must be accepted by you.

### 2. Install Xcode's iOS platform — DONE, but note the cause

Xcode 26.6 ships the iOS 26.5 SDK; only the 26.4 simulator runtime was
installed, so `xcodebuild` reported **zero eligible destinations** and no build
of any kind could run. Resolved by `xcodebuild -downloadPlatform iOS` (8.5 GB).
Re-check after any Xcode update.

### 3. Register a device

The team has **zero registered devices**, so Xcode cannot mint a development
provisioning profile — archiving fails with "Your team has no devices". Plug
your iPhone in and let Xcode register it. Required before you can run on
hardware; also the smoothest path to a first archive.

### 4. Create the distribution certificate

Only an **Apple Development** certificate exists. App Store distribution needs
an **Apple Distribution** certificate. Xcode creates one automatically during
Product → Archive → Distribute App, provided the account has Account Holder or
Admin rights. No manual step expected, but it has not happened yet.

### 5. Archive from the Xcode GUI

Automatic signing cannot be overridden from the command line, so the archive
must go through Xcode: **Product → Archive → Distribute App → App Store Connect**.
CLI archiving would require switching the project to manual signing.

### 6. Create the App Store Connect record

Blocked on step 1. Then: My Apps → + → New App. Platform iOS, name Cat-Snap,
bundle ID `com.jadaross.CatSnap`, SKU `CATSNAP001`, primary language English.

---

## Non-blocking, but worth doing

- **Screenshots.** App Store Connect now requires **6.9"** iPhone (1320×2868 or
  1290×2796 — iPhone 17 Pro Max), not the 6.7"/6.1" pair named in
  `launch-checklist.md` §7 C15. Needs real seeded data to look good — an empty
  map makes a poor screenshot.
- **SMTP.** Email confirmation is on but no provider is wired. Default Supabase
  SMTP is rate-limited and lands in spam. Resend or Postmark.
- **Sentry DSN.** `SENTRY_DSN` is absent from `CatSnap.xcconfig`. The app skips
  Sentry init gracefully, so TestFlight would fly blind on crashes.
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

1. Accept the App Store Connect ToS.
2. Plug in your iPhone so it gets registered.
3. Xcode → Product → Archive. Let it create the distribution certificate.
4. Create the App Store Connect record.
5. Distribute App → App Store Connect → upload.
6. Wire SMTP + Sentry DSN while the build processes.
7. Internal TestFlight, daily-drive it, seed real data.
8. Capture 6.9" screenshots from the seeded app.
9. Fill in description, keywords, privacy nutrition labels, support URL.
10. Submit.
