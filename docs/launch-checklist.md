# Launch Checklist

The single doc tracking everything between **here** (feature-complete v1 on `main`) and **there** (live on the App Store).

Earlier roadmap docs (Phase 0–3.5 build journal, design notes, competitive scan, future-upgrade wishlist) have been retired — they're preserved in git history. The two remaining reference docs are `brand.md` (visual source of truth) and `new-schema.sql` (DB source of truth). Everything else lives below.

---

## 0. Where things stand

- v1 feature surface is shipping: map, submit, cat profiles, user profiles, friends graph, explore, streaks, onboarding.
- Apple App Store review gates A1 (account deletion) and A2 (block + report) are merged on `main`, the migrations are applied to the live Supabase project, and the `delete-account` edge function is deployed.
- What's left, in priority order: any **functional changes** you want to make first → **Swift best practices sweep** → **security audit** → **UI/UX pass** → **App Store gates** → **production readiness** → **App Store Connect prep** → ship.

---

## 1. Functional changes I want to make first

> _Map out any functional/product changes you want to land **before** the launch checklist work below. Anything here gets folded into the build before we start polishing._

### 1.1 Drop the "missing cat" framing
- [ ] Remove the "missing cat" concept and the `?` placeholder from the Explore / guide views. A cat is either spotted or not-yet-spotted — never "missing".
- [ ] Remove the progress bar growing at the top of the guide (it was tied to the missing-cat completion metric and no longer makes sense).
- [ ] Audit copy across guide / explore / cat-profile for any remaining "missing" / "find me" wording and rewrite to "spotted" vs "not yet spotted".

### 1.2 Cat profile entry points
- [ ] Tapping a cat in the **Nearby cats** list (and any cat row in Explore / guide) opens that cat's profile. Confirm every cat-row tap target routes to `CatProfileView`, not just the highlighted ones.
- [ ] From inside a cat's profile, tapping **Explore** in the tab bar returns the user to the **Map**, not back to the guide stack. (Pop to root + switch tab.)

### 1.3 "I spotted them" vs "Upload a sighting"
- [ ] Split the current submit action into two distinct affordances on `CatProfileView`:
  - **"I spotted them"** — quick, no-photo check-in. Logs the sighting (timestamp + location) and increments the spot count. No camera, no upload.
  - **"Upload a sighting of <cat name>"** — the existing photo flow, but pre-filled with this cat (so it's adding a photo to a known cat, not creating a new one). The button label should interpolate the cat's actual name.
- [ ] Schema/RPC check: `create_sighting_with_cat` currently expects a photo URL — needs a path (or a sibling RPC) that allows `photo_url IS NULL` for the no-photo check-in case. Confirm RLS + storage policies still hold.

### 1.4 Editable / pinnable sighting location
- [ ] Today the sighting location comes from EXIF on the uploaded photo. Keep that as the default when a photo is uploaded, **but** let the user drop / drag a pin to override before submitting.
- [ ] For the no-photo "I spotted them" flow, default to current device location and let the user adjust the pin before confirming.
- [ ] Add a "change location" affordance on the submit screen (map preview with a draggable pin). Make sure the final write hits the `location geography(Point, 4326)` column via the typed insert path, not by parsing strings.

### 1.5 Awards: bigger, tappable, explained
- [ ] Increase award icon size on the user profile and tighten the spacing between awards — currently they read as small and over-spaced.
- [ ] Each award is tappable and opens a sheet/popover with: award name, description, and the criteria for unlocking it ("spot 10 cats", "7-day streak", etc.).
- [ ] Locked vs. unlocked treatment should still be visually distinct after the size change.

### 1.6 Drop the today / week / all-time filter
- [ ] Remove the today / week / all-time time-filter chips from the map (and any other surface they appear on). Default — and only — view is all-time.
- [ ] Drop the related state, query params, and RPC arg(s); whatever currently powers the filter (likely a `since` / `time_window` parameter on `sightings_near`) gets simplified to always return all-time data.
- [ ] Audit Section 4.3 tap-target list — the time-filter chips were called out there and that bullet can come out once the chips are gone.

### 1.7 Favorites (heart) + favorites filter
- [ ] Add a heart / favorite toggle on `CatProfileView` (and inline on cat rows where it fits).
- [ ] Filter on the **Guide / Explore** view: "show favorites only".
- [ ] Filter on the **Map** view: "show favorites only" — same heart button, hides non-favorited pins.
- [ ] Schema: add a `favorites` table (`user_id`, `cat_id`, `created_at`, PK on the pair) with RLS — `auth.uid() = user_id` for all CRUD. Update `sightings_near` and the guide RPC to either join favorites or accept a `favorites_only` flag.

### 1.8 Guide: filter by cat attributes, location, time, etc.
- [ ] Add a filter affordance to the guide that supports combining multiple criteria:
  - **Attributes** — rarity (common / uncommon / rare / legendary), colour / pattern, any tag fields surfaced via `sighting_tags`.
  - **Location** — within a chosen radius of a point (current location or a dropped pin), or by a coarse area filter.
  - **Time** — first-spotted / last-spotted within a date range. (Independent of the removed map time-filter chips — this is a guide-only, opt-in control.)
  - **Status** — spotted vs not-yet-spotted (replaces the old "missing" framing); favorites-only stacks on top from 1.7.
- [ ] Filter state should be ephemeral (resets on app relaunch is fine for v1) and visible — surface active filters as removable chips above the grid.
- [ ] Schema/RPC: extend the guide RPC with optional filter args rather than building a separate one. Confirm RLS still applies and the query plan stays sane (PostGIS index for the radius case, btree on `cats.rarity`).

### 1.9 Cross-cutting follow-ups (after the above land)
- [ ] Re-walk Section 4 (UI/UX pass) once these changes settle — copy, empty states, and tap-target audits all shift.
- [ ] Update `docs/new-schema.sql` to reflect the new `favorites` table and any RPC changes.

---

## 2. Swift best-practices sweep

Audit the codebase against current Swift / SwiftUI conventions. Aim for a clean compile with no warnings and a one-pass read-through where nothing surprises a senior reviewer.

### 2.1 Concurrency & state
- [ ] Every observable state holder is `@Observable` (iOS 17), not `ObservableObject`. Spot-check `AuthSession`, `FriendsModel`, any other view-models.
- [ ] View-models that touch UI are `@MainActor`-isolated. `Task { … }` blocks inside views inherit `MainActor`; long-running work hops off via `Task.detached` or an actor.
- [ ] No `Task { … }` in a `View` body without explicit `[weak self]` or value-type capture — easy retain-cycle source.
- [ ] All `Task`s started by a view are cancelled when the view disappears (`.task` modifier handles this; raw `Task { … }` doesn't).
- [ ] Long-poll loops, `for await … in supabase.auth.authStateChanges`, and any `AsyncStream` consumers respect cancellation. Confirm by greping for `for await` and checking the surrounding lifecycle.
- [ ] `Sendable` conformance on every Codable model passed across async boundaries. Build with `-strict-concurrency=complete` once and triage warnings.

### 2.2 Error handling
- [ ] No `try!` outside test code. No `as!` outside places where the type is provably correct (and even then, prefer `as?` with a clear fallback).
- [ ] Force-unwraps audited (`grep -rn '!\b' --include='*.swift'` + manual review). The exceptions: `URL(string: "<known-good>")!` for static URLs, IBOutlets (we don't use any), and asset catalog lookups.
- [ ] Network errors from Supabase are not surfaced as `error.localizedDescription` to the user — wrap in a presentational error type with friendly copy.
- [ ] Throwing functions that the UI calls have a `do { try await … } catch { … }` site that does something useful with the error (toast, retry button, fallback view) — not just `print(error)`.

### 2.3 SwiftUI hygiene
- [ ] Big views split into smaller subviews so SwiftUI's body-diff cost stays low (`MapView`, `FriendsActivityView`, `OnboardingView` are the candidates).
- [ ] No expensive work in `body` (no `DateFormatter()` initialisation per render — caching is already done in places, sweep for other instances).
- [ ] `Equatable` conformance on row models for `List` / `LazyVGrid` cells where it cuts re-renders.
- [ ] Image loading: `AsyncCatImage` is the canonical async loader; `Image(uiImage:)` only for in-memory bitmaps. No synchronous file reads in `body`.
- [ ] `@State` is for view-local UI state only. Cross-view shared state goes through `@Environment` (`AuthSession`) or a `@Bindable` view-model.
- [ ] Animations: every `.animation(...)` is value-driven (`.animation(.spring(), value: x)`) rather than the deprecated implicit form.

### 2.4 Code-level cleanliness
- [ ] Run `xcodebuild … -warningsAsErrors` once and clear remaining warnings.
- [ ] Dead code from earlier phases pruned (search for `// TODO`, `// FIXME`, `// removed`, commented-out blocks).
- [ ] `print(...)` statements either removed or routed through a single debug logger that's stripped in release builds.
- [ ] No unused imports. No unused `@Environment` properties.
- [ ] Public-by-default audit on view-model methods — anything not consumed externally goes `private`.
- [ ] `@MainActor` annotations are on the **type**, not sprinkled per-method, where the whole type is UI-bound.

### 2.5 Build & tooling
- [ ] Add a `.swiftlint.yml` (or pick the built-in `-Wno-…` set) and wire as an Xcode build phase. Decide which rules to enforce vs. warn.
- [ ] Bump deployment target to the lowest version actually tested (currently 17.6 — confirm or document).
- [ ] Strip debug symbols in Release config (`STRIP_INSTALLED_PRODUCT = YES`, default).

---

## 3. Security audit (Snyk + manual)

The global CLAUDE.md mandates Snyk on first-party generated code. This is the formal pre-launch sweep.

### 3.1 Snyk runs
Run each of these and address findings before submission:

- [ ] **`snyk_auth`** — log in once if the CLI / MCP isn't already authenticated.
- [ ] **`snyk_code_scan`** on the Swift sources under `CatSnap/CatSnap/` — static-analysis sweep for injection, weak crypto, insecure storage, hard-coded secrets.
- [ ] **`snyk_code_scan`** on `supabase/functions/delete-account/index.ts` — TypeScript / Deno scan covers JWT handling, service-role-key usage, path-traversal in storage list/remove.
- [ ] **`snyk_iac_scan`** on `supabase/migrations/` — IaC scan for SQL DDL: missing RLS, overly broad GRANTs, dangerous `SECURITY DEFINER` functions without `search_path`.
- [ ] **`snyk_sca_scan`** on `CatSnap/CatSnap.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` — supply-chain scan of every SPM dependency (supabase-swift, swift-crypto, etc.). Note any HIGH/CRITICAL CVEs even if not yet exploitable.
- [ ] **`snyk_package_health_check`** on `supabase-swift` and any dep that gets flagged — confirms maintenance status, license, popularity.

### 3.2 Manual review (Snyk doesn't catch)
- [ ] Re-confirm RLS is on for every public-schema table except `spatial_ref_sys` (PostGIS metadata — RLS off is correct, advisor false-positive).
- [ ] Every RPC has `set search_path to 'public', 'pg_temp'` to avoid the `search_path` injection class. The amended RPCs from migration `0002` already do; spot-check the older ones (`create_sighting_with_cat`, `find_or_create_cat`, `handle_new_user` trigger).
- [ ] Storage policies still match the lock-down post-`v1_storage_policy_tightening`: public read via CDN only, authenticated INSERT only, no UPDATE/DELETE for non-owners.
- [ ] `delete-account` edge function only accepts a JWT in the `Authorization` header — never an anon-key or query-param token. Confirm `verify_jwt: true` is on in the deployed config (already verified on deploy).
- [ ] No secrets in the repo. `CatSnap.xcconfig` is gitignored; `CatSnap.example.xcconfig` is a template only.
- [ ] No service-role key in any client-shipped code or `.xcconfig` — only the anon (publishable) key.
- [ ] `SUPABASE_URL` / `SUPABASE_ANON_KEY` Info.plist substitution doesn't leak into a release-build dSYM in plaintext (it does, but that's fine — anon key is public by design; just confirm no other secrets follow the same path).
- [ ] Rate-limit RPCs added before launch (Section 5, item B12) — submit cap, follow cap, photo-size enforcement.
- [ ] Leaked-password protection turned on in Supabase Auth → Policies (one-click toggle).
- [ ] Email confirmation back ON before TestFlight (was off for dev). SMTP wired to a real provider so confirmations don't go to spam.

---

## 4. UI/UX final pass

Walk every flow on a real device (not just the simulator) with these in mind:

### 4.1 State coverage on every screen
For each list/grid/detail view, confirm all four states render correctly:
- [ ] **Loading** — branded skeleton or spinner, not a blank screen.
- [ ] **Empty** — friendly copy + a clear next-action ("snap your first cat", "add friends to see activity", etc.). No raw `0 results` text.
- [ ] **Error** — graceful "couldn't load — retry" with a button. Never `error.localizedDescription` raw.
- [ ] **Offline** — the airplane-mode test. Map cached tiles + cached pins are nice-to-have; minimum is a non-broken UI.

Surfaces to walk: Map, Submit, CatProfile, UserProfile, Friends activity, Add Friends, Explore, Onboarding flow.

### 4.2 Permissions
- [ ] Walk every flow assuming the user said "Don't Allow" once. Each path has a "Open Settings" button (`UIApplication.openSettingsURLString`).
- [ ] Permissions touched: Camera, Photo Library, Location (when-in-use), Notifications.
- [ ] Info.plist usage strings (`NS…UsageDescription`) are user-facing English, not placeholders.

### 4.3 Accessibility
- [ ] VoiceOver labels on `CatPin`, `RarityBadge`, `SightingThumbnail`, `CatWindowMark`, the coral "+" overlay button.
- [ ] Dynamic Type honoured in cards and lists — test at the largest accessibility size; nothing should be cut off or overflow off-screen.
- [ ] Coral-on-cream contrast ratio ≥ 4.5:1 for body text and ≥ 3:1 for large text (use the Accessibility Inspector).
- [ ] Tap targets ≥ 44×44 pt — overflow `…` menus, close buttons, the "+" overlay, time-filter chips.
- [ ] Reduce Motion respected — any custom animations check `UIAccessibility.isReduceMotionEnabled` or use SwiftUI's automatic accommodation.

### 4.4 Brand discipline
- [ ] Light mode only — no `Color(.systemBackground)`, no `.preferredColorScheme(.dark)`, no semantic system colours that flip in dark mode.
- [ ] Wordmark uses Fraunces BlackItalic only; no other weight/style of Fraunces appears.
- [ ] Yellow / sage are highlights only — never on the wordmark, never as a large surface.
- [ ] All copy lowercased where the brand calls for it ("spot every cat.", "i saw this cat", section labels).

### 4.5 Microcopy + flow
- [ ] Every destructive action has a confirmation dialog (delete account, block user, sign out is borderline — match the pattern).
- [ ] Time formatting consistent: "2m ago", "3h ago", "yesterday", absolute date past 7d. One helper, used everywhere.
- [ ] Forms keyboard-aware: scroll the active field into view; "Done" button on numeric pads; submit on return where it makes sense.
- [ ] Onboarding can be exited (or completes on its own) — no soft-locks if a permission is denied mid-flow.
- [ ] The "Contact support" / privacy / terms links in `SettingsSheet` open the **real** values (see Section 5.A1 — these are still placeholders).

### 4.6 Device matrix
- [ ] iPhone 15 Pro Max (largest), iPhone SE 3rd gen (smallest supported), iPhone 17 Pro (latest) — at minimum.
- [ ] Set `TARGETED_DEVICE_FAMILY = 1` (iPhone only) so the App Store doesn't list us as iPad-compatible.
- [ ] Portrait only — confirm `UISupportedInterfaceOrientations` reflects this.

---

## 5. App Store review gates

Things that get the app **rejected** if missing.

### A1. Account deletion (Guideline 5.1.1(v)) — ✅ shipped
- `Features/UserProfile/SettingsSheet.swift` — destructive "Delete account" row with confirmation dialog.
- `Core/Supabase/AccountDeletion.swift` — invokes the edge function, then `signOut(scope: .local)`.
- `supabase/functions/delete-account/index.ts` — deployed to live project (version 1, ACTIVE).
- **Still pending:** replace the placeholder `support@catsnap.app`, `https://catsnap.app/privacy`, `https://catsnap.app/terms` in `SettingsSheet.swift:16-18` with real values.

### A2. UGC moderation (Guideline 1.2) — ✅ shipped
- Report sheet (`Features/Moderation/ReportSheet.swift`) reachable from `…` menus on `CatProfileView`, `FriendsActivityView` `FeedCard`, and `PinDetailCard`.
- Block via `FriendsModel.block` → `public.blocks` insert; the four read-side RPCs (`sightings_near`, `friend_activity`, `my_friends`, `search_profiles`) filter symmetric pairs server-side.
- Migrations `0001_blocks_and_reports` and `0002_filter_blocked_in_rpcs` applied to live Supabase.
- **Still pending:** an admin dashboard / triage flow for `public.reports`. v1 acceptable — manual triage via the Supabase dashboard is fine for launch.

### A3. Sign in with Apple (Guideline 4.8) — code shipped, manual config pending
Code is in place — `Core/Supabase/AppleSignIn.swift` (nonce + SHA-256 + `signInWithIdToken` exchange + best-effort `display_name` backfill) and the button + "or" divider in `Features/Auth/AuthView.swift`. The native flow needs no Service ID or `.p8` for sign-in.
- [x] Add `SignInWithAppleButton` to `AuthView`; wire to `supabase.auth.signInWithIdToken(...)`.
- [ ] Apple Developer console → Identifiers → App ID `com.jadaross.CatSnap` → Capabilities → tick **Sign In with Apple** → Configure → "Enable as a primary App ID" → Save.
- [ ] Xcode → CatSnap target → Signing & Capabilities → `+ Capability` → "Sign in with Apple". This auto-creates `CatSnap/CatSnap.entitlements` and adds `CODE_SIGN_ENTITLEMENTS` to both build configs.
- [ ] Supabase Dashboard → Authentication → Providers → Apple → toggle **Enabled** → fill **only** "Authorized Client IDs" with `com.jadaross.CatSnap` → Save. Leave Service ID / Secret Key / Team ID / Key ID blank — those are the OAuth-redirect fields and are not needed for the native flow.
- [ ] **Follow-up (deferred):** extend the `delete-account` edge function to call Apple's `https://appleid.apple.com/auth/revoke` endpoint when a SIWA user deletes their account. This is the only piece that requires a Service ID + `.p8` (stored as a Supabase secret). Apple's strict reading of 5.1.1(v) wants revocation; reviewers historically pass on deletion alone but it's not guaranteed. TODO mirrored in `Core/Supabase/AccountDeletion.swift`.

### A4. Privacy policy + Terms of Service
- [ ] Host both as static pages (GitHub Pages, a Vercel static deploy, or a one-pager on `catsnap.app`).
- [ ] Privacy policy must cover: data collected (email, photos, GPS, profile info, sightings, follows, blocks, reports), purpose, retention, deletion path (point to the in-app flow), processors (Supabase), contact email.
- [ ] Replace the placeholder URLs in `SettingsSheet.swift` with the real ones.
- [ ] Add the privacy policy URL to App Store Connect (required field).

### A5. App Privacy "nutrition labels"
- [ ] App Store Connect → App Privacy → declare:
  - **Account**: email, name. Linked to identity.
  - **Photos**: yes. Linked to identity.
  - **Coarse Location**: yes. Linked to identity.
  - **User Content**: photos, sightings. Linked to identity.
  - **Tracking**: none.

---

## 6. Production-readiness

Stuff that bites if skipped — not a rejection risk, but the difference between a launch and a meltdown.

- [ ] **B6. Re-enable email confirmation + configure SMTP.** Auth → toggle on. Wire Resend or Postmark — default Supabase SMTP is rate-limited and goes to spam. Customise the confirmation email with brand colours + wordmark.
- [ ] **B7. App icon.** `Assets.xcassets/AppIcon.appiconset/Contents.json` exists with universal/dark/tinted slots but **no PNG files**. Export 1024×1024 PNGs (no transparency, no rounded corners). Keep the master at `docs/icon-master.png`.
- [ ] **B8. Crash + error reporting.** Wire Sentry (free tier, SPM package). Catch unhandled exceptions and log Supabase RPC errors. Without this, TestFlight is flying blind.
- [ ] **B9. Rate limits + abuse mitigation.** Postgres-side guards:
  - Per-user submit cap (e.g. 50 sightings / day) via constraint or RPC guard.
  - Per-user follow cap (e.g. 1000) to limit spam graphs.
  - Photo size cap enforced server-side (currently client-side at 1600px / q=0.7).
- [ ] **B10. Bundle ID + signing.** Xcode → target → Signing & Capabilities → assign Apple Developer team. Confirm `com.jadaross.CatSnap` registered in App Store Connect.
- [ ] **B11. Leaked-password protection.** Supabase → Authentication → Policies → toggle on (one click).
- [ ] **B12. Localization scaffolding.** Wrap user-facing strings in `String(localized:)` even shipping en-only; v2 can add languages without a refactor.

---

## 7. App Store Connect prep

Do once, in parallel with sections 5–6.

- [ ] **C13. App Store Connect record.** Bundle id `com.jadaross.CatSnap`, name "Cat-Snap", subtitle "spot every cat.", primary category Photo & Video (secondary Social Networking), age rating 4+ (UGC + location disclosures answered honestly).
- [ ] **C14. Description + keywords.** 4000-char description, 100-char keyword list. Draft alongside this checklist if iterating.
- [ ] **C15. Screenshots.** 6.7" iPhone Pro Max + 6.1" iPhone (required). 5–8 screenshots each. Real fixtures (real cats, real map). Marketing-text overlay on each.
- [ ] **C16. Preview video** (optional but converts better). 15–30s. `xcrun simctl io booted recordVideo`.
- [ ] **C17. Support URL.** Same static site as the privacy policy.

---

## 8. Ship sequence

The order to actually do things in:

1. ✅ Section 1 — bank any functional changes you want first.
2. Section 2 — Swift sweep.
3. Section 3 — security audit. Fix anything HIGH/CRITICAL before TestFlight.
4. Section 4 — UI/UX pass on a real device.
5. Section 5 A3 + A4 — Sign in with Apple, hosted privacy/terms, real placeholders.
6. Section 6 — production readiness (icon, Sentry, SMTP, rate limits).
7. Internal TestFlight build → daily-driver on your phone for ~1 week.
8. External TestFlight (≤100 testers, no review needed for friends/family).
9. Address feedback, iterate.
10. Section 7 — App Store Connect record + screenshots + description.
11. Submit for review.

---

## 9. Deferred to v2 (not for this launch)

Reactions, comments, merge-requests on cats, real `badges` table, leaderboard, push notifications (permission is requested in onboarding but no APNs handler), per-sighting visibility flags, TNR/caretaker flags on cats, server-side photo moderation, AI cat-matching at submit time (v3 territory — on-device Vision feature prints + pgvector), Universal Links / share sheet, iPad support.

---

## Reference

| | |
|---|---|
| **Brand source of truth** | [`docs/brand.md`](brand.md) |
| **DB source of truth** | [`docs/new-schema.sql`](new-schema.sql) |
| **Working notes for Claude Code** | [`CLAUDE.md`](../CLAUDE.md) |
| **Live Supabase project** | `wgtjtvxpxalyeukgxbpo` (eu-central-2) |
| **Retired web app** | git tag `v1.0.2-web-final` |
