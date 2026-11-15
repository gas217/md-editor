# MD Editor — Build Readiness Metrics

The hill-climbing scorecard. Every dimension is 0-100. Target: **95% average across all twelve dimensions** before this repo is considered production-ready.

Two gates:
- **Build-ready** (dimensions 1–11): a Claude Code agent can start V1.0 today and the verification layer scores it.
- **Production-ready** (dimension 12): the V1.0/V1.1 build can ship to real users — signed, notarized, distributed, supported, monitored.

Run `make score` to compute the current score. The script emits `score.json` and appends to `score-history.jsonl`. It invokes `make build` for the current checkout; existing binaries alone earn no credit. `FAST_SCORE=1 make score` skips that build and records zero for the build dimension, so the readiness gate cannot pass.

This rubric combines scaffolding, historical reviews, and checklist evidence. It does not execute unit or E2E tests and is not a production certification. CI runs those tests separately; the readiness threshold is advisory during pre-V1.0.

For evaluation of the running app, use the [MD Editor app quality rubrics](docs/quality-rubrics.md) and [evaluation template](docs/quality-evaluation-template.md). They score file integrity, rendering, commenting, anchors, the agent loop, other format previews, performance, accessibility, and recovery. A separate [look-and-feel rubric](docs/look-and-feel-rubric.md) covers visual quality. Their scores and release gates are separate from this readiness score.

## Dimensions

| # | Dimension | Definition | How measured |
|---|---|---|---|
| 1 | **Vision quality** | Adversarial product-reviewer score | Latest pass-N adversarial review, × 10 |
| 2 | **Engineering soundness** | Principal-engineer feasibility score | Latest engineer review, × 10 |
| 3 | **Project scaffolding** | % of paths in VISION.md "Project Layout" that exist on disk with at least a stub file | `scripts/score.sh` |
| 4 | **Test scaffolding** | % of named test files in V1.0/V1.1 acceptance criteria that exist as Swift test stubs | `scripts/score.sh` |
| 5 | **Verification automation** | CI scoring hook (40), history continuity (10 or 30), score target (20), E2E scaffolding (10) | `scripts/score.sh`; does not require an E2E pass |
| 6 | **Build harness** | Does `make build` succeed (xcodegen + xcodebuild) for the current checkout? | Binary: 0 or 100 |
| 7 | **CI configuration** | Does `.github/workflows/ci.yml` exist and reference test files? | `scripts/score.sh` |
| 8 | **Repository hygiene** | README, CONTRIBUTING, LICENSE, .gitignore present and non-trivial | `scripts/score.sh` |
| 9 | **Feature compliance** | % of features in `feature-inventory.yml` whose required artifacts (tests, modules, milestone) all exist | `scripts/score.sh` → `features_score` |
| 10 | **Adversarial feedback** | Devil's-advocate reviewer score — independent third reviewer charged with finding anything wrong | Latest adversarial review, × 10 |
| 11 | **UX review** | UX/design reviewer score — flows, friction, discoverability, polish | Latest UX review, × 10 |
| 12 | **Production readiness** | % of items in `PRODUCTION-READINESS.md` marked `[x]` with evidence (file path, CI job, or commit ref) | `scripts/score.sh` → `production_score` |

## Reviewer types (dimensions 1, 2, 10, 11)

Four distinct reviewer personas. Each is its own dimension because they look at different things and a high score on one doesn't imply a high score on another.

- **Vision (1)** — adversarial *product* reviewer. Thesis sharpness, persona realism, competitive positioning, scope discipline, build-readiness from the doc alone.
- **Engineering (2)** — principal *engineer*. Feasibility, stack soundness, internal consistency, dependency risk, perf claim realism.
- **Adversarial (10)** — pure devil's advocate. Reads the whole repo (vision + code + tests) and tries to break it. No category — just "what's wrong."
- **UX (11)** — design/UX reviewer. User flows from first launch through repeat use. Friction points, discoverability, polish, consistency with macOS HIG, accessibility implications.

## Feature compliance (dimension 9)

Source of truth: `feature-inventory.yml` — every feature called out in VISION.md's Features section, with its required artifacts (test files, source modules, milestone tag). The current script counts a feature when **all** required artifacts exist on disk. It applies a concentration penalty when too many entries reuse the same artifacts. Milestones are documented in the inventory but are not validated by the scorer. This is an artifact-presence measure, not a feature acceptance test.

This dimension exists to catch silent vision drift — adding a feature to VISION.md without scaffolding evidence in the repo. The check is cheap and runs on every score pass.

## Production readiness (dimension 12)

Source of truth: `PRODUCTION-READINESS.md` — checklist of every item required to ship V1 to real users (signing, notarization, distribution, crash reporting, updater, privacy policy, support, release process, accessibility, localization stance, marketing artifacts). Each item is either checked `[x]` with evidence (file path, CI job, or commit ref) or unchecked `[ ]`. The scorer checks whether backtick-quoted evidence paths exist and counts other checked items syntactically. It does not rerun signing, release, or accessibility checks; historical claims still need fresh validation before release.

The checklist is what separates "buildable spec" from "shippable software." Dimensions 1–11 can all be at 100 while production-readiness is at 30 — that means the spec is great but nothing real ships yet. The 95% gate forces both bars to be cleared.

## Current baseline (updated by score.sh)

See `score.json` for live numbers. The script also appends to `score-history.jsonl` for trend tracking.

## Hill-climb policy

1. Run `scripts/score.sh`.
2. Find the lowest-scoring dimension.
3. Address it. The smallest concrete change that moves the number is the right one — no gold-plating.
4. Re-run `scripts/score.sh`; it appends the score to `score-history.jsonl` automatically.
5. Stop when the average ≥ 95% AND no dimension < 80%.

## Anti-gaming rules

- Scaffolding scores count *files exist*, not "stub satisfies the spec." Test scaffolding is intentionally cheap (a Swift file with the test name + `XCTSkipIf(true, ...)` counts).
- New Vision / Engineering / Adversarial / UX scores require fresh independent reviews with no prior context; reusing prior scores as review inputs is forbidden. The script currently defaults to historical values from `docs/review-log.md`, which were not re-reviewed during repository reconciliation. Those defaults must be refreshed before making new readiness claims.
- Feature compliance can be gamed by adding more required-artifact entries to `feature-inventory.yml` without backing scaffolding. Mitigation: every inventory entry is reviewed in PR; new features without artifacts drop the score, never raise it.
- A dimension scoring 100 via gimmicks (a one-line README; a feature inventory with zero entries) is allowed by the rubric but called out as a follow-up. The rubric measures readiness, not quality of the readiness artifacts.

## Why 95%

Below 80%, an autonomous-build agent hits blockers within hours of starting. Above 95%, additional polish hits diminishing returns and the time is better spent in V1.0 Story 0 code. The 95% gate forces every dimension to be at least *functional*, not aspirational.
