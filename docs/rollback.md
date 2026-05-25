# Rollback Playbook

If a release ships a regression, follow this. Reference: `RELEASING.md` § "Rollback".

## Severity assessment first

Within 1 hour of discovery:

- **P0** — data loss (file corruption, sidecar wipe), security vulnerability, ≥10% of users hitting an OOM/crash on launch. Rollback immediately.
- **P1** — correctness regression (mis-anchor, wrong save), severe perf hit (≥2× slower cold launch), feature totally broken. Decide rollback within 6 hours.
- **P2** — annoyance, edge-case bug, cosmetic. Patch in next scheduled release; do not rollback.

## Rollback steps

1. **Stop the bleed.** Update `appcast.xml` to point auto-updater clients back to the previous version:
   ```bash
   git checkout vX.Y.(Z-1) -- appcast.xml
   git commit -m "rollback: pin appcast to vX.Y.(Z-1)"
   git push
   # Hosted appcast updates within 5 min.
   ```
2. **Mark the bad release as Pre-release on GitHub** so it doesn't surface as "latest":
   ```bash
   gh release edit vX.Y.Z --prerelease
   ```
3. **Pull from Homebrew cask** if the bad version landed:
   ```bash
   # Open a revert PR against homebrew-cask
   ```
4. **Document.** Write the incident note in `docs/incident-response.md` with the post-mortem template.
5. **Communicate.** Pin a GitHub issue titled `Known issue in vX.Y.Z — please update to vX.Y.(Z+1)` once the fix ships.

## What rollback can't fix

- **User data already mangled.** If the bad release corrupted user files, rollback to the previous version doesn't un-corrupt them. The only mitigation is NSFileVersion (macOS Time-Machine-style local versions). Document the recovery path in the GitHub issue.
- **Already-installed users who don't auto-update.** Auto-update is best-effort; some users have it off. The pinned GitHub issue is the broadcast.

## Re-issue the version

Don't. Increment to vX.Y.(Z+1) with the fix. Versions are immutable in user perception; re-issuing breaks trust.

## Drills

Run this playbook against a synthetic regression on `main` once per quarter. Time-to-rollback target: <30 minutes from "I see a P0" to "appcast updated." Last drill: TBD.
