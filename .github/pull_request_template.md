## What changed

<!-- One sentence. -->

## Why

<!-- One paragraph. What problem does this solve? What VISION.md section does it advance?
     If this is a V1.0 Story implementation, name the story. -->

## Acceptance criteria satisfied

<!-- Check the boxes for the specific acceptance criteria your PR claims to satisfy.
     Every checked box must have a passing test in CI before merge. -->

- [ ] Story 0a — preview-md-shared extraction
- [ ] Story 0b — MarkEdit baseline measurement
- [ ] Story 0c — TextCanon ship + fuzz
- [ ] Story 1 — Open and read (`Tests/RenderPerformance.swift`, `Tests/ColdLaunch.swift`, `Tests/RenderFidelity.swift`)
- [ ] Story 2 — Edit inline (`Tests/TypingLatency.swift`, `Tests/IME.swift`)
- [ ] Story 3 — Save (`Tests/RoundTrip.swift`)
- [ ] Story 4 — Comment (`Tests/CommentRoundTrip.swift`)
- [ ] Story 5 — Anchor drift (`Tests/AnchorDrift.swift`)
- [ ] Story 6 — Sidebar
- [ ] Story 7 — Agent loop, CLI (`Tests/CLI.swift`)
- [ ] V1.1 story (specify): ___
- [ ] Other (specify): ___

## Tests added or modified

<!-- Path(s) + brief description. If you're touching a test that's still `XCTFail`,
     promote it to a real test in this PR. -->

## Risks

<!-- What could go wrong? Anything that touches: TextCanon, the bridge protocol,
     anchor resolution, the save path, or sandbox entitlements — call it out. -->

## Score impact

<!-- Run `make score` before/after. If any dimension dropped, explain or revert. -->

Before: avg X / min Y
After:  avg X / min Y

## Checklist

- [ ] I read VISION.md and `CONTRIBUTING.md`
- [ ] My changes do not violate the non-goals
- [ ] `TextCanon` is the only file I touched that does CRLF/NFC/UTF-16 (or I updated the allowlist with justification)
- [ ] I did not call `rename(2)` directly anywhere
- [ ] `make score` ran clean
