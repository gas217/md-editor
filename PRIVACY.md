# MD Editor Privacy Policy

**Effective date:** 2026-05-24 (V1.0 pre-release scaffold; final date set at first public release)

## Short version

MD Editor collects nothing. The app does not phone home, does not send telemetry, does not analyze your files, does not have an account system, and does not require network access at all. Everything you do stays on your Mac.

## Long version

### What we collect

Nothing. Zero. No analytics, no usage events, no crash reports (unless you explicitly opt in — see below), no error reports, no user identifiers, no email collection.

### What stays local

- Every file you open or edit — `.md`, `.txt`, `.csv`, `.json`, `.html`, `.pdf`. Stored on your disk, never transmitted by us.
- Every comment you write. Saved to a sidecar `*.comments.json` next to the file. Never transmitted by us.
- Every preference. Saved to per-file `*.settings.json` sidecars. Never transmitted.
- The dogfood usage log (`log show --predicate 'subsystem == "com.mdedit.dogfood"'`). Lives in the system log — only the maintainer's local copy, never collected centrally.

### Network access

The app runs without network. The App Sandbox declares no `network.client` entitlement; `Tests/NoNetwork.swift` asserts zero outbound requests during normal use. (Note: during spec iteration the entitlements file at `App/MDEditor.entitlements` is intentionally empty; a V1.0 must-fix tracked in `PRODUCTION-READINESS.md` re-applies the documented minimal set — `app-sandbox`, `files.user-selected.read-write`, `files.bookmarks.{app,document}-scope` — explicitly without `network.client`.)

The two exceptions are:
1. **Update check.** If the in-app updater is enabled (default: on after first launch), the app fetches an appcast XML from a stable URL (e.g. `https://github.com/gas217/md-editor/releases/...`). Only the appcast URL is contacted. No user info is sent — the request includes only a User-Agent and the current app version. The user can disable update checks in Settings.
2. **Apple Intelligence Services (V2).** If you invoke "Services → Address with Apple Intelligence" on a comment, macOS may consult Apple's on-device Foundation Model (zero network) or — on user opt-in within macOS — Apple's Private Cloud Compute. That data flow is governed by [Apple's privacy policy](https://www.apple.com/legal/privacy/). We never invoke a non-Apple cloud LLM.

### Crash reports (opt-in)

Off by default. If you opt in via Settings, crash reports are sent only when the app crashes — never during normal use. The report contains: macOS version, app version, stack trace. Never: file contents, comment contents, file paths, or any user data. The report endpoint will be documented in `App/CrashReporter.swift` once a destination is chosen; until then, opt-in does nothing.

### Apple Intelligence and on-device AI

When you use Writing Tools (Proofread, Rewrite, Summarize, etc.), macOS handles the request. Apple Intelligence runs on-device for short text. Longer text may go to Apple's Private Cloud Compute if you have enabled that setting in System Settings — Apple's policy governs that flow. MD Editor does not send your text anywhere itself.

### Third-party libraries

The app links the following dependencies, none of which collect user data:
- CodeMirror 6 (MIT)
- Apple's WebKit, PDFKit, NSDocument, NSFileVersion (system frameworks)
- swift-markdown (cmark-gfm — MIT)
- Yams (MIT)

See `LICENSES.md` for the full inventory.

### Your rights

Because we don't collect anything, there's nothing to delete, export, correct, or opt out of. If you remove the app, every artifact lives in your file system at known paths — sidecars are plain JSON next to your files; remove them with `rm` if you want.

### Changes to this policy

If the policy changes (for example: opt-in crash reporting becomes opt-out — it won't), the new version is committed to this file and announced in `CHANGELOG.md`. The previous version stays accessible via `git log PRIVACY.md`.

### Contact

Open a GitHub issue with the `privacy` label.
