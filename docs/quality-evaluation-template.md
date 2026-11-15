# MD Editor quality evaluation

Copy this template for one candidate. Use [the quality rubrics](quality-rubrics.md)
for scoring anchors and procedures. Replace placeholders with observations; U
and UNKNOWN remain until their checks are performed.

## Candidate and scope

- Evaluation date and evaluator: _record_
- Git commit and dirty patch identity or archive: _record_
- App configuration, path, artifact hash, and bundled CLI version: _record_
- Dependency lockfile hash: _record_
- macOS, Xcode, hardware/RAM, display refresh rate: _record_
- Build/install commands and clean-environment details: _record_
- Advertised formats and aliases: _record_
- Included extension claims and performance budgets: _record before testing_
- Explicitly deferred features and where users see those limitations: _record_
- Newline/encoding contract by format, approved exceptions, and requirement conflicts: _record before testing_
- Fixture manifest, hashes, expected outputs, and evidence directory: _record_

## Product score

Use ratings 0–4 or U; evidence E0–E3. Points = weight × rating / 4.
Until complete, count U as zero only for the lower bound; retain the denominator
of 100. Do not treat an unknown result as a failure that was observed.

| ID | Dimension | Weight | Rating | Points | Evidence | Expected and actual result or artifact |
|---|---|---:|---|---|---|---|
| Q1 | Opening and integration | 7 | U | — | E0 | — |
| Q2 | Markdown rendering fidelity | 13 | U | — | E0 | — |
| Q3 | Editing and integrity | 18 | U | — | E0 | — |
| Q4 | Comment workflow | 14 | U | — | E0 | — |
| Q5 | Anchors | 12 | U | — | E0 | — |
| Q6 | Sidecar and agent loop | 10 | U | — | E0 | — |
| Q7 | Other format previews | 8 | U | — | E0 | — |
| Q8 | Performance | 8 | U | — | E0 | — |
| Q9 | Keyboard and accessibility | 6 | U | — | E0 | — |
| Q10 | Recovery and privacy | 4 | U | — | E0 | — |

- Weighted score or incomplete lower bound: _/100; initially incomplete_
- E2-or-better evidence coverage for known ratings: _/100 weight points_
- Dimensions below 3 and unknown dimensions: _list_
- Q7 sub-results for CSV/TSV/JSON/JSONL/HTML/PDF as advertised: _record separately; use the lowest for Q7_

## Look-and-feel score

Use the separate [look-and-feel rubric](look-and-feel-rubric.md). Do not average
this score with product quality. Record appearance, window size, display scale,
font settings, screenshots, and expected versus actual findings for each V ID.

| ID | Dimension | Weight | Rating | Points | Evidence | Artifact and finding |
|---|---|---:|---|---|---|---|
| V1 | Typography and hierarchy | 20 | U | — | E0 | — |
| V2 | Layout and resizing | 20 | U | — | E0 | — |
| V3 | Markdown editing states | 15 | U | — | E0 | — |
| V4 | Comments and threads | 15 | U | — | E0 | — |
| V5 | Color and focus | 15 | U | — | E0 | — |
| V6 | macOS consistency | 10 | U | — | E0 | — |
| V7 | Transitions and details | 5 | U | — | E0 | — |

Visual score / incomplete lower bound: _not evaluated_ /100.
Visual evidence coverage: _record_ /100. Dimensions below 3 or unknown: _record_.
Review matrix and second-reviewer findings: _record_.

## Mandatory gates

| ID | Gate | Result | Evidence grade | Evidence or blocker |
|---|---|---|---|---|
| G1 | Clean build and normal launch | UNKNOWN | E0 | — |
| G2 | No data loss | UNKNOWN | E0 | — |
| G3 | Zero wrong anchors | UNKNOWN | E0 | — |
| G4 | Human comment and agent loop | UNKNOWN | E0 | — |
| G5 | Untrusted content isolated | UNKNOWN | E0 | — |
| G6 | Honest support and errors | UNKNOWN | E0 | — |
| G7 | Performance limits | UNKNOWN | E0 | — |
| G8 | Reliable candidate validation | UNKNOWN | E0 | — |

Distribution validation, if a public download is proposed: _not assessed / pass /
fail; identify exact signed artifact and install/update/rollback evidence_.

## Critical task evidence

For each sequence in the rubric, record fixture IDs, exact actions, expected and
actual results, artifacts, and Q/G IDs. For the comment loop, include the selected
quote, saved comment ID, gutter/inspector observation, source diff, CLI JSON,
reply/resolution, and reopened state. Do not use a hand-written sidecar as proof
that the composer saved it.

| Sequence | Fixture and actions | Expected versus actual | Artifacts | Q, V, or G IDs |
|---|---|---|---|---|
| _record_ | — | — | — | — |

Anchor corpus results:

- Recoverable cases attempted: _/100 minimum_; correct reattachments: _/attempted_
- Deleted/ambiguous cases attempted: _/20 minimum_; safe orphans: _/attempted_
- Wrong attachments across all cases: _count; required zero_
- Independent expected-span labels and UI observations: _artifact links_

## Performance measurements

Copy every applicable Q8 metric into this table before running. Record timing
p50/p95/max, raw sample count, and failures. For CPU/memory/bundle measurements,
record the statistic and units specified by Q8. Keep main RSS and WebKit/GPU
process measurements distinct. Record test-mode/debugger state and the timing
instrument's resolution.

| Metric and fixture | Samples | p50 or specified statistic | p95 | Max | Target and limit | Result | Raw evidence |
|---|---:|---|---|---|---|---|---|
| _record_ | — | — | — | — | — | UNKNOWN | — |

MarkEdit baseline version/build, workload, and comparison: _record or UNKNOWN_.
Provisional typing thresholds alone do not complete the relative latency check.

## Reliability and unresolved findings

- Unit tests passed/failed/skipped and `.xcresult`: _record_
- Renderer and build-harness checks: _record_
- Three consecutive core UI runs, including earlier failures and diagnosis: _record_
- Missing acceptance assertions, environment blockers, and manual coverage: _record_
- Independent second-environment reproduction for any E3 claims: _record_

| Finding | Severity | Reproduction and affected IDs | Owner or next action | Closure evidence |
|---|---|---|---|---|
| _record_ | — | — | — | — |

Classify data loss, wrong anchors, untrusted code execution, and document
exfiltration as release blockers. Classify inability to complete a core task or
a hard performance-limit breach as a major defect. Reserve minor for defects
that preserve correctness and task completion; cosmetic for appearance alone.

## Decision

Choose one: **INCOMPLETE**, **BLOCKED**, **NEEDS IMPROVEMENT**, or
**MEETS APP QUALITY THRESHOLD**.

- Any unknown required result or evidence below E2: INCOMPLETE, unless a known
  gate failure already makes it BLOCKED.
- Any failed mandatory gate: BLOCKED regardless of score.
- Complete evidence and passing gates, but either score below 85 or any dimension below
  3: NEEDS IMPROVEMENT.
- Both scores ≥85, all product and visual dimensions ≥3, all gates PASS, all evidence ≥E2:
  MEETS APP QUALITY THRESHOLD. Public distribution still needs its separate pass.

Decision and supporting evidence: _not evaluated_.
Next actions in priority order: _record_.
