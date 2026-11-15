# Releasing MD Editor

This is the maintainer's release runbook. Public users don't need this.

## Versioning

- **Semantic versioning** per [semver.org](https://semver.org/).
- **Tag format:** `v<major>.<minor>.<patch>` (e.g., `v1.0.0`).
- **Pre-V1 (V0.x.x):** development releases. No production-readiness guarantees.
- **V1.0.0:** ships V1.0 (markdown & text foundation) per `VISION.md`.
- **V1.1.0:** ships V1.1 (multi-format expansion).
- **V2.0.0:** ships V2 (PDF).
- **Patch bumps (V1.0.1, V1.0.2…):** bug fixes only. No feature additions.

## Release process

### Prerequisites (one-time)

- Apple Developer Program membership active.
- `DEVELOPER_ID_APPLICATION` certificate in the keychain.
- `APP_STORE_CONNECT_API_KEY` env var set (for `notarytool`).
- Signing identity name in `~/.zshrc` or equivalent: `export MDEDIT_SIGN_ID="Developer ID Application: Your Name (TEAMID)"`

### Distribution rules

- **Pre-public ship** (author + invited dogfooders): Developer-ID-signed builds are fine. Distribute via Homebrew cask (strips `com.apple.quarantine` on install) or `install.sh` curl-pipe (same). Skip steps 7–9 below until V1 is ready for non-author users.
- **Public ship** (anyone can download): notarization required. Run the full sequence below. First-time notarize on this machine requires: (a) re-signing the Apple Developer Program agreement at appstoreconnect.apple.com, (b) clicking "Always Allow" on the one-time Keychain modal when `sign_update` first runs.

### Per-release steps

1. **Dogfood gate.** Run `scripts/dogfood-report.sh` — must show ≥30 qualifying days for V1.0/V1.1; no dogfood requirement for V0.x patch releases.
2. **CI green.** Last 7 days of CI pushes on `master` must all be green. `scripts/score.sh` must report `gate_met: true`.
3. **Update `CHANGELOG.md`.** Move the `[Unreleased]` section under the new version heading; add today's date; create a new empty `[Unreleased]` block.
4. **Bump version.** Update `CFBundleShortVersionString` in `project.yml`. Commit: `release: bump to vX.Y.Z`.
5. **Tag.** `git tag -s vX.Y.Z -m "Release vX.Y.Z"` (signed tag).
6. **Build.** `make release` — runs `xcodegen generate`, `xcodebuild -configuration Release`, signs with Hardened Runtime, builds DMG via `scripts/build-dmg.sh`.
7. **Notarize.** `scripts/notarize.sh` — submits to Apple via `notarytool`, polls for completion, staples the ticket to the `.app` and DMG.
8. **Verify.** `spctl --assess --verbose=4 build/MDEditor.app` must report `accepted source=Notarized Developer ID`.
9. **Sign appcast.** `scripts/generate-appcast.sh` — produces `appcast.xml` with EdDSA signature on the new release.
10. **Push tag.** `git push origin vX.Y.Z`.
11. **GitHub Release.** Upload `MDEditor-vX.Y.Z.dmg` + `MDEditor-vX.Y.Z.zip` + `SHASUMS256.txt`. Body = the `CHANGELOG.md` entry for this version.
12. **Update Homebrew cask.** Open a PR against `homebrew-cask` updating the `mdedit` formula with the new version, URL, and SHA-256.
13. **Announce.** Post `docs/launch-post.md` (or release-notes equivalent) to HN/Mastodon/Twitter.

## Rollback

If a release ships a regression:
1. **Unpublish from the appcast.** Update `appcast.xml` to point to the previous version; users on auto-update revert on next check.
2. **Pull from Homebrew cask** (PR to revert).
3. **Mark the GitHub release as Pre-release** so it doesn't show as "latest" via the API.
4. **Note in `docs/incident-response.md`** for the post-mortem.

See `docs/rollback.md` for the full rollback playbook.

## Hot-fix cadence

For P0 (data loss, security): tag and release within 24 hours of root cause. For P1 (correctness, severe perf): within 7 days. For P2: bundle into the next scheduled release.
