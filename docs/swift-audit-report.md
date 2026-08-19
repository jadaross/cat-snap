# Swift Audit

**Last verified**: 19 August 2026, against a build that compiles and a test
suite that passes.

---

## Correction to the previous version of this file

The 18 August version of this report graded the codebase **B+** and recorded
**"Critical Issues: 0"**.

**The tree did not compile at the time.** Two hard compile errors were sitting
on `main`:

- `CatSnapApp.swift` — `options.sessionTracking` is not a member of
  sentry-cocoa 8.x `Options`; the property is `enableAutoSessionTracking`.
- `SpotConfirmSheet.swift` — `[weak self]` applied inside a SwiftUI `View`
  **struct**. `weak` requires a class type.

Both were introduced by the same commits the report was describing. A report
written without running `xcodebuild` cannot grade a codebase, and its counts
were wrong in both directions — it claimed 18 `error.localizedDescription`
sites where there was 1, and 5 per-render `DateFormatter`s where there were 3.

Everything below was counted against the working tree on 19 August. The point
of the CI added in `79b8a6d` is that this cannot recur silently.

---

## Verified state

| Check | Count | Notes |
|---|---|---|
| Compiles | ✅ | Debug and Release, simulator and device |
| Tests | ✅ 15 passing | `CatSnapTests`, 2 suites |
| Snyk SAST — Swift | ✅ 0 issues | re-run 19 Aug |
| Snyk SAST — `supabase/` | ✅ 0 issues | re-run 19 Aug |
| Build warnings | 0 | |
| `print(...)` in shipped code | 0 | |
| `error.localizedDescription` shown to users | 1 | |
| Force-unwrapped `URL(string:)!` | 0 | was 2; fixed 19 Aug |

## Open items, in priority order

### 1. `Task { }` in view bodies — 32 sites under `Features/`

Raw `Task { }` is not cancelled when the view disappears; `.task { }` is.
Not every one of the 32 is wrong — many are button actions that should
outlive the tap — but they have not been triaged individually. Worth a pass
specifically on the ones started during `onAppear`-style setup.

### 2. Per-render `DateFormatter` — 3 sites

`DateFormatter()` construction is expensive and these are inside `body`:

- `Features/Submit/SubmitView.swift:299`
- `Features/Explore/GuideListView.swift:194`
- `Core/Util/ExifMetadata.swift:29` — not a view body, lower priority

Hoist to a `static let`. `launch-checklist.md` §4.5 also asks for one shared
relative-time helper used everywhere, which would collapse these anyway.

### 3. `AsyncImage` instead of `AsyncCatImage` — 2 sites

`AsyncCatImage` is the canonical loader per `CLAUDE.md`. Two call sites still
use the raw SwiftUI one and so skip the brand placeholder treatment.

### 4. Oversized views

`SubmitView.swift` at 583 lines is the largest and the most important screen
in the app. `UserProfileView` (483) and `MapView` (408) follow. Splitting
`SubmitView` also makes `SubmitModel` reachable from tests.

### 5. Localization is inert

36 `String(localized:)` call sites, no string catalog. The scaffolding is
there and it costs nothing, but nothing is actually localizable today.

## Fixed since the previous report

- Both compile errors above.
- `SettingsSheet` privacy/terms URLs: the `?? URL(string: "…")!` fallbacks
  were unreachable force-unwraps pointing at pages that do not exist.
  Replaced with a single audited `staticURL` helper.
- `TARGETED_DEVICE_FAMILY` narrowed to iPhone; orientations to portrait.
- `ITSAppUsesNonExemptEncryption` declared, so export compliance no longer
  gates every upload.
