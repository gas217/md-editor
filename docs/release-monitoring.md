# Release Monitoring

How we know a release is healthy. Reference: `PRODUCTION-READINESS.md` "Post-launch monitoring."

## What we don't do

No analytics. No telemetry. No phone-home dashboards. See `PRIVACY.md` — this is a constraint, not a gap.

That means release health monitoring is **passive and indirect**:

## Signals we actually have

| Signal | Where | What it tells us |
|---|---|---|
| **GitHub Issues opened in the 48 hours after release** | github.com/gas217/md-editor/issues | Crashers, broken installs, regressions |
| **HN/Mastodon/Twitter mentions** | search the URL `github.com/gas217/md-editor` | Word-of-mouth signal of severe issues |
| **Homebrew analytics (aggregate install counts)** | https://formulae.brew.sh/analytics/cask/mdedit | Install volume (proxy for reach, not health) |
| **GitHub Releases download counts** | release page API | Same |
| **Auto-updater appcast hit rate** | webserver logs of `appcast.xml` (if self-hosted) | How many clients are checking |
| **Maintainer dogfooding** | running the release on the maintainer's machine | First line of defense — the maintainer is user #1 |

## Cadence

- **First 24 hours post-release:** check Issues every few hours. The first 24 hours is when 80% of "release broke X" reports arrive.
- **First week:** check Issues daily.
- **Steady state:** weekly issue triage.

## Health gates

- **Green:** no new P0/P1 in 7 days; ≤3 unique P2 reports.
- **Yellow:** 1 unconfirmed P0/P1 report, or ≥5 unique P2 reports clustered around one feature. Investigate before shipping the next release.
- **Red:** confirmed P0 (data loss / security / install-broken). Trigger `docs/rollback.md`.

## What to do when you can't tell

Default to the more conservative interpretation. A single ambiguous "MD Editor ate my file" report is yellow until proven otherwise.

## Future

If usage grows past the maintainer's bandwidth to monitor manually, candidate additions (all opt-in, all documented in PRIVACY.md before shipping):
- Crash report submission with explicit user consent per incident (not blanket).
- Update-check ping (already happens) augmented with anonymous OS-version histogram.

Both require PRIVACY.md updates and a community discussion before implementing. Neither lands without explicit opt-in.
