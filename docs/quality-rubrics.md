# MD Editor app quality rubrics

Evaluate whether someone can open an agent-produced file, read it, make a small
edit, leave an accurately anchored comment, and review an agent's response
without losing data or waiting on the UI. These rubrics assess the running
macOS app and its bundled `mdedit` helper.

Use four results together: a weighted product score, a separate
[look-and-feel score](look-and-feel-rubric.md), mandatory correctness and safety
gates, and an evidence grade. The proposed release threshold is
**85/100 in each score, every product and visual dimension at least 3/4, every
gate passing, and evidence grade E2 or better for every dimension and gate**. A high average cannot cancel
a wrong anchor, data loss, or missing evidence.

[METRICS.md](../METRICS.md) measures repository readiness and uses historical
review scores. Its score is not an input to this evaluation. Fill out
[the evaluation template](quality-evaluation-template.md) for each candidate.

## Evaluation scope

Freeze the supported-feature list before testing. The base profile covers the
surface currently advertised in [README.md](../README.md): Markdown/plain-text
editing, text-range comments and sidecars, the agent CLI, CSV/JSON/HTML previews
with source editing, and PDF viewing. Include aliases and variants the candidate
advertises, especially `.tsv`, `.jsonl`, and `.ndjson`; a registered extension
alone does not establish support.

Treat Focus mode, CSV sorting/virtualization, JSON Pointer copy, streamed JSONL,
PDF comments, Mermaid/math rendering, and the three-way merge picker as extension
checks until explicitly included in a release's promises. A visible control or
user-facing instruction claiming a feature makes it in scope. Unsupported
features need an honest fallback or limitation, not a silently empty view.

The weighted dimensions below always apply to the base profile. Do not remove a
failed dimension, shrink the fixture set, or relabel a promised feature as
optional after seeing results. Record extension results separately; they cannot
add bonus points that conceal a base-profile failure.

## Rubric 1 Product quality

Assign an integer from 0 to 4 to each dimension. Run all of its core checks before
awarding 3; award 4 only when its core and stress checks pass. Performance has
the additional scoring rule in Q8.

| Score | Meaning |
|---|---|
| 0 | The core task is absent or unusable, or causes data loss, a wrong anchor, or a safety violation. |
| 1 | The task can start but cannot be completed through the intended UI or CLI. |
| 2 | A basic round trip completes, but a required case needs a workaround or fails. |
| 3 | All listed core checks pass without a workaround. |
| 4 | All core and stress checks pass, including the stated quantitative targets. |
| U | Unobserved, blocked by the test environment, or supported only by stale evidence. Not a pass. |

The score is `sum(weight × rating / 4)`, out of 100. If any rating is U, report
an **incomplete** evaluation and a lower bound using zero for U; keep the
denominator at 100. Report evidence coverage separately as the sum of weights
with a known rating and E2-or-better evidence. Do not turn that lower bound into
a release grade. For example, a score of 80 with 20 points unobserved is not 100%.

| ID | Dimension | Weight |
|---|---|---:|
| Q1 | Opening files and macOS integration | 7 |
| Q2 | Markdown rendering fidelity | 13 |
| Q3 | Editing and file integrity | 18 |
| Q4 | Comment creation and thread navigation | 14 |
| Q5 | Anchor correctness after edits | 12 |
| Q6 | Sidecar and agent interoperability | 10 |
| Q7 | CSV JSON HTML and PDF viewing | 8 |
| Q8 | Responsiveness and resource use | 8 |
| Q9 | Keyboard and accessibility | 6 |
| Q10 | Recovery and local privacy | 4 |
| | Total | 100 |

### Q1 Opening files and macOS integration

**Core for 3:** open a Markdown file through Finder's Open With, the app's Open
command, drag to the app, and the bundled CLI. The intended MD Editor build must
receive the correct file, even when another app is the default Markdown handler.
The document window shows its filename and actual content, not just a blank
WKWebView. Opening a second file leaves the first file and its edits intact.
No account, setup wizard, or unrelated privacy permission is required.

**Stress for 4:** repeat with Unicode filenames, spaces, a moved file, a read-only
file, and two different directories containing `plan.md`. Reopen after quitting;
window restoration and Finder events must not create duplicate or wrong documents.

**A 2 looks like:** Open works, but the CLI opens the default editor instead of
MD Editor, or a second-file open requires quitting the app. Observe the receiving
window; CLI exit code 0 is insufficient evidence.

### Q2 Markdown rendering fidelity

Score faithful content and editing behavior here. Assess typography, spacing,
color, and visual polish independently in the [look-and-feel rubric](look-and-feel-rubric.md).

**Core for 3:** a 10 KB review document displays distinct heading levels, readable
paragraphs, emphasis, links, inline/fenced code, lists, and blockquotes. GFM tables,
task lists, images, and frontmatter either render correctly when claimed or have
a legible, honest fallback. Source text remains recoverable. The hybrid editor
reveals syntax consistently around editing; source and rendered text do not
overlap, duplicate, or disappear. Moving the caret does not jump to another
paragraph. The gutter matches the surface in light and dark mode.

**Stress for 4:** inspect the same document at the app's minimum window size,
ordinary laptop size, and a wide display, with the inspector open and closed.
Long URLs and code lines do not cover prose or controls. Text enlargement does
not clip the status bar or comment composer. Screenshots before/after selection
show no unexplained scroll jump greater than one body-text line. A reader can
identify the heading hierarchy and find a named section without opening source.

**A 2 looks like:** readable text with a white gutter strip in dark mode,
overlapping status text, broken wrapping, or syntax hiding that removes content.
Check the visible editor: the separate shared renderer producing correct HTML
does not prove that the CodeMirror editor looks correct.

### Q3 Editing and file integrity

**Core for 3:** edit one sentence, paste multiline text, find/replace, undo/redo,
save, close, and reopen. Compare the bytes on disk against the expected edit.
Untouched LF files, frontmatter, tabs, trailing spaces, and final-newline presence
must survive a no-op save. A failed save must remain visibly unsaved and leave
the original file intact. Editing one document must not modify another.

Freeze the newline contract by format before comparison. Existing tests permit
CRLF-to-LF normalization, while the vision also promises byte-identical no-op
saves and CSV CRLF preservation. Record this discrepancy explicitly. For this
rubric, undisclosed normalization fails; any approved exception must identify
the format and exact allowed byte transformation. Opening a file without editing
must never rewrite it merely to normalize it. UTF-8 rejection must be actionable,
not replaced by a blank document that can overwrite the source.

**Stress for 4:** run at least 50 text fixtures, including CRLF, emoji, combining
characters, CJK, empty files, and files without a final newline. Pass all 30 CJK
IME scenarios, including composition/cancel, replacement, undo, and save/reopen.
Recover correctly from an external edit while local edits are unsaved and from
an injected write failure. A raw source edit to CSV/JSON/HTML must also reach its
preview and persist without a format-changing reserialization.

**A 2 looks like:** ordinary typing persists, but undo, preview refresh, or a
documented newline case fails. Lost user content is 0 and fails G2.

### Q4 Comment creation and thread navigation

**Core for 3:** select a sentence, invoke both the toolbar Comment button and
Cmd-Shift-M, see the correct quoted selection, enter `@claude clarify this #review`,
and save with Cmd-Return. Exactly one valid sidecar comment appears. The new
marker and thread are visible immediately. Click the marker, inspect its body,
close/reopen the document, and verify that the same thread and anchor reappear.
Escape cancels without creating a comment. With no selection, invoking Comment
must not create a stray composer or sidecar. Resolve a thread and confirm its
visible state and persisted state agree.

**Stress for 4:** test multiline and emoji selections, several comments on one
line, unsaved new documents, long comment bodies, and two open documents. Panel
reveal preserves the selection and reading position. In a timed task with three
first-time macOS users, at least two create and save a correctly anchored comment
within 30 seconds from launch without instructions beyond the task.

**A 2 looks like:** a valid comment is saved, but only a restart reveals its marker,
or clicking one marker displays another thread. A sidecar written by the test
process does not demonstrate the comment-creation workflow.

### Q5 Anchor correctness after edits

**Core for 3:** create known anchors, then insert text above them, move a paragraph,
edit inside the quote, duplicate the quote with different context, delete the
target, and introduce emoji/combining characters before the target. On reopening,
each attached comment must select its intended text. A missing or ambiguous
target must become an explicit orphan, never a confident attachment elsewhere.
The UI marker, selected range, and inspector quote must agree.

**Stress for 4:** use at least 100 independently labeled recoverable mutations
and 20 deleted/ambiguous negative cases. Correctly reattach at least 95 of the
100 recoverable cases, with **zero wrong attachments across all 120 cases**.
Record expected target ranges before running the resolver. An orphan in a
recoverable case counts against reattachment; a safe orphan in a negative case
passes. Labels cannot be generated by the same resolver being tested.

**A 2 looks like:** all attachments are safe, but paragraph moves orphan comments
too often. Any observed wrong attachment is 0 and fails G3. Apply the same rule
to CSV/JSON/PDF selectors if those commenting features are included in scope.

### Q6 Sidecar and agent interoperability

**Core for 3:** create a comment in the app, list it with
`mdedit comments <file> --unresolved --addressable`, change the source with a
separate process, and resolve that ID using `--resolve <id> --reply <text>`.
The CLI returns parseable JSON and correct exit statuses. Reopen the app and
verify the edited source, reply, author, resolution state, and anchor. Untargeted
comments and the source bytes are preserved by sidecar-only commands. Compare
the JSON with [the schema](comments-schema.md), including version, document path,
hash contract, UTF-16 positions, mentions, and tags.

**Stress for 4:** execute three review/edit/reply cycles on a document with 100
comments, multiple agent mentions, and Unicode paths. Unknown selectors or
optional fields must follow the documented compatibility contract; unsupported
schema versions, malformed JSON, and unknown IDs must not silently overwrite
data or return false success. External updates must become visible through the
documented refresh/reopen path. If live refresh is advertised, observe the
inspector update within one second without an unrelated user action.

**A 2 looks like:** CLI JSON is correct but the app shows stale resolution after
reopening, or the workflow only works for ASCII paths. Printing a reply into a
test-owned file without observing the app consume it earns no workflow credit.

### Q7 CSV JSON HTML and PDF viewing

**Core for 3:** run each included format through the actual app. CSV preserves
quoted commas/newlines, empty cells, and literal values such as `00123`; TSV must
use tabs if supported. JSON distinguishes strings/numbers/booleans/null, exposes
actual nested values, and reports malformed input. Test JSONL record boundaries
if advertised. HTML displays fixture content with untrusted scripts and external
loads blocked. PDF must contain the expected page count and visible text, and
support scrolling/zoom without altering its original bytes. `.txt` containing
Markdown syntax remains plain text. Source edits refresh text-format previews.

**Stress for 4:** inspect a 10,000-row CSV, deeply nested JSON, a self-contained
HTML report, and a multipage PDF. Resize the split panes, switch documents, and
reopen. Included large-file capabilities must meet the extended performance
budgets below or show an explicit fallback. Broken inputs must not strand an
empty preview with no explanation.

**A 2 looks like:** a simple CSV works, but quoted multiline cells become extra
rows. A PDFView's existence, generic HTML body children, or two web views are
not enough to prove the intended file rendered. Record a sub-result per format;
use the lowest format rating as Q7, so a broken format cannot be averaged away.

### Q8 Responsiveness and resource use

Measure a Release build in normal mode, with no E2E probe, debugger, or profiler
attached except the instrumentation required for that measurement. The E2E bridge
polls every 200 ms and would distort idle CPU. Record hardware, macOS, display
refresh rate, build identity, fixture sizes, and timing method.

The numeric budgets below come from [VISION.md](../VISION.md#success-metrics).
The repetition protocol is part of this rubric. Run 20 app-cold launches (app
terminated, OS caches not artificially purged), 30 warm opens, and at least 500
keystrokes at 10 keys/second. Report p50, p95, maximum, and failures; use p95 for
timing decisions. Disclose the first run separately. Observe first readable
document content, not just process creation or a blank window.

| Measurement | Target | Hard limit | Profile and observation |
|---|---:|---:|---|
| Cold launch to readable 10 KB Markdown | <500 ms | 700 ms | Base; process spawn to document content |
| Warm open | <100 ms | 200 ms | Base; existing app opens a different file |
| Open 10 KB / 100 KB / 1 MB Markdown | <100 / 150 / 300 ms | 150 / 225 / 450 ms | Base; open request to readable content |
| Typing to visible result | ≤1.0× MarkEdit p95 | 1.25× MarkEdit p95 | Base; identical machine, file, and input workload |
| Scroll 10,000-line Markdown | 60 fps | 30 fps minimum | Base; 30 seconds, disclose display refresh rate |
| Idle CPU with file open | approximately 0% | <0.5% of one core | Base; 30-second sample after settling |
| Typing CPU | <10% of one core | <20% | Base; sustained 10 keys/second |
| Main-process idle / 1 MB Markdown RSS | <80 / 120 MiB | 120 / 200 MiB | Base; fixed 10-second settling interval |
| Net RSS growth after 100 open/close cycles | <10 MiB | 30 MiB | Base; same fixture sequence and settling interval |
| RSS excess after one document closes | ≤5 MiB | 15 MiB | Base; compare with pre-open baseline after settling |
| Complete Release app bundle | <10 MiB | 15 MiB | Base; include renderer assets, helper, and Sparkle |
| 10,000-row CSV first readable preview | <300 ms | 500 ms | Extended CSV performance claim |
| 500,000-row CSV first readable preview | <2 s | 4 s | Extended large CSV claim |
| 10 MB JSON first readable preview | <1 s | 2 s | Extended large JSON claim |
| Fully expanded 10 MB JSON main RSS | <250 MiB | 400 MiB | Extended large JSON claim |

Use MiB consistently for memory/bundle comparisons, matching the existing binary
size script's 1024-based units. Report WebKit content/GPU processes separately
alongside main-process RSS; do not call main-process RSS the entire app's memory
footprint or present summed RSS as unique physical memory. A renderer function
returning HTML is not an end-to-end open-time measurement.

Until a current MarkEdit baseline exists, show typing latency as **provisional**
against the vision's M-series target/limit of 8/10 ms (Intel: 16/20 ms), and leave
the relative check U. Use event-to-present instrumentation with sufficient
resolution; a 60 fps video cannot establish an 8 ms latency claim. Do not retune
budgets to the current build's measurements.

**3:** every base hard limit passes, with complete measurements. **4:** every base
target also passes, plus all performance claims in the frozen extension profile.
**2:** the normal workflow completes but a hard limit fails. **1:** repeated
stalls make the ordinary task impractical. **0:** ordinary fixtures crash or
exhaust resources. Missing required measurements mean U, not an assumed 3.

### Q9 Keyboard and accessibility

**Core for 3:** use only the keyboard to open, navigate, edit, search, undo/redo,
save, create/cancel/save a comment, inspect a thread, and close the document.
Verify Cmd-O/S/W/F/Q/Z, Shift-Cmd-Z, Cmd-Shift-M, Cmd-Return, and Escape against
their visible menu/toolbar behavior. Focus must enter the composer and return
sensibly when it closes. Toolbar icons expose useful names; selection, editing,
composer fields, thread content, and resolution state are accessible to VoiceOver.
No keyboard trap or hidden focused control is acceptable.

**Stress for 4:** repeat with enlarged text, light/dark appearance, minimum window
size, and system reduced-motion settings. A VoiceOver user completes the entire
open/edit/comment/reopen loop without sighted assistance. Comment state is
distinguished by text or shape as well as color. All additional advertised
shortcuts, including zoom and source-mode switching, perform their documented
actions without stealing ordinary text-editing shortcuts.

**A 2 looks like:** typing and saving work, but the comment panel traps focus or
has unnamed controls. Inspecting an Accessibility tree alone does not prove a
screen-reader user can complete the workflow.

### Q10 Recovery and local privacy

**Core for 3:** test unreadable files, invalid UTF-8, malformed/truncated sidecars,
read-only destinations, canceled saves, external modifications, and corrupt PDFs.
Show an actionable error while retaining recoverable work. Ordinary viewing and
editing must not send document/comment contents off-device. Logs must not expose
document bodies. Untrusted HTML/Markdown content cannot execute its own script,
read unrelated local files, or invoke native bridge actions. First-party editor
JavaScript is expected; it must remain isolated from document-supplied content.

**Stress for 4:** inject save failures and terminate during controlled writes to
disposable fixture copies; reopening yields a complete old or new file, never a
truncated mixture. Test malicious scripts, event handlers, external resources,
and local-file probes using synthetic sentinels and a controlled request logger.
Validate the logger with a positive control outside the app. Explicitly requested
updates or link navigation are separate from background document loads.

**A 2 looks like:** an error leaves the file intact but hides the reason or loses
the user's place. Data destruction or untrusted-content execution is 0 and fails
the corresponding mandatory gate. Use an isolated test volume or fault injection
for disk-full cases; never fill the user's real disk.

## Rubric 2 Mandatory correctness and safety gates

Record PASS, FAIL, or UNKNOWN for each gate. UNKNOWN blocks a release claim as
surely as missing quality ratings do. Failures require a reproducible fixture
and expected/actual result; fixing a gate does not erase other dimension scores.

| ID | Gate | Required evidence |
|---|---|---|
| G1 | Clean build and launch | A clean checkout plus the candidate changes builds app, editor resources, and helper. The exact candidate opens a real document through a normal entry point. No hidden sibling directory or stale output is required. |
| G2 | No document or comment data loss | Before/after bytes and parsed sidecars for save/reopen, undo, failed write, external edit conflict, and cancel. No unapproved newline rewrite, erased comments, or false saved indicator. PDF bytes remain unchanged. |
| G3 | Zero wrong anchors | Golden expected ranges and app-observed highlights for the mutation corpus. Deleted/ambiguous targets are safe orphans. One wrong attachment fails. |
| G4 | Complete human comment and agent loop | In-app selection → saved comment → visible marker → reopen → CLI reply/resolve → app shows reply and state. Preserve IDs and unrelated comments. Test both toolbar and keyboard entry. |
| G5 | Untrusted content stays isolated | Actual runtime tests of script/event handlers, native bridge attempts, remote loads, and unrelated local-file reads. Synthetic sentinels stay private; request logs show no document-initiated traffic. CSP strings alone do not pass. |
| G6 | Honest support and errors | Every advertised format opens correctly or reports an actionable error without replacing data. Menus, help, and release notes do not present unimplemented features as working. |
| G7 | Performance limits met | All base hard limits and any explicitly advertised extension limits pass the Q8 protocol. Missing latency/memory measurements remain UNKNOWN. |
| G8 | Reliable candidate validation | Required unit/UI suites pass with real failure exit codes; skipped acceptance tests have explicit coverage elsewhere or remain UNKNOWN. Core UI scenarios pass three consecutive runs on the same candidate. Retain earlier failures and explain their cause; rerunning until green is not a diagnosis. |

For a public download, also require a separate distribution pass: install the
exact signed/notarized artifact on a clean user account, open a document, use the
bundled helper, and verify update/rollback behavior if offered. Follow
[PRODUCTION-READINESS.md](../PRODUCTION-READINESS.md) and
[RELEASING.md](../RELEASING.md); an unsigned local build is not that evidence.

## Rubric 3 Evidence quality

Grade evidence separately from behavior. A thoroughly reproduced failure can
have E3 evidence and a product score of 0. A pass in an unrelated helper function
cannot certify a UI workflow.

| Grade | Evidence standard |
|---|---|
| E0 | Assertion, source inspection, checklist tick, old score, or test filename without relevant runtime observation. |
| E1 | One relevant observation, but incomplete reproduction details, narrow fixture coverage, or missing artifacts. |
| E2 | Exact candidate, environment, fixtures, procedure, and expected/actual results recorded; observable evidence for all required checks, including errors. Critical UI flows repeated three times with outcomes retained; G8 separately requires consecutive passes. Performance uses Q8 sample counts. Manual keyboard/VoiceOver evidence is valid when steps and outcomes are recorded. |
| E3 | E2 plus repeatable automated regression checks with assertions at the user-visible or persistence boundary, artifacts and reliable failure status, and consistent independent reproduction on a second clean environment. Manual-only aspects remain documented explicitly. |

For each result retain the commit and dirty patch identity, dependency lockfile
hash, app artifact hash, macOS/Xcode/hardware, fixture manifest, commands/actions,
screenshots or video, before/after data, and relevant `.xcresult` or raw measurements.
A build pass proves compilation; a file's existence proves existence. Neither
proves rendered content, successful comment decoding, nor inspector refresh.

## Fixture set and execution plan

Use copies in a dedicated temporary directory. Capture hashes and expected
content before running. Existing `E2ETests/Fixtures/basic.*` files provide a
starting smoke set, not the complete corpus below.

| Fixture family | Required content | Main dimensions |
|---|---|---|
| Review document | 10 KB Markdown with h1–h6, paragraphs, emphasis, links, code, lists, blockquote, table, tasks, local image, frontmatter | Q1 Q2 Q4 Q9 |
| Text preservation corpus | ≥50 files; LF/CRLF, Unicode, tabs, trailing spaces, empty/no-final-newline files, Markdown-looking `.txt` | Q3 |
| Anchor mutations | 100 recoverable cases plus 20 ambiguous/deleted cases; expected spans labeled independently | Q5 |
| Agent handoff | App-created sidecars, 100-comment stress sidecar, multiple agents, malformed/versioned/unknown-selector cases, two same-basename files | Q4 Q6 Q10 |
| CSV and TSV | Empty values, quoted separators/newlines, escaped quotes, leading zeros, header/no-header; 10,000-row stress sample | Q3 Q7 |
| JSON and JSONL | Nested arrays/objects, scalar types, empty containers, malformed input; records per line when claimed | Q3 Q7 |
| HTML and hostile content | Self-contained report plus script/event/resource/bridge/local-file attempts using synthetic sentinels | Q7 Q10 |
| PDF | Multipage searchable text, image-only page, corrupt PDF; pre/post file hash | Q7 Q10 |
| Performance corpus | Exact 10 KB/100 KB/1 MB Markdown, 10,000-line Markdown, and declared extension-sized fixtures | Q8 |
| Failure injection | Read-only paths, external modifications, truncated sidecars, controlled write failures | Q3 Q6 Q10 |

Run these task sequences in order, linking every result to the Q/G IDs it covers:

1. Build the exact candidate and open the review document through each normal entry point.
2. Inspect rendering in light/dark mode and narrow/wide windows; move the caret and toggle the inspector.
3. Make a typo correction, undo/redo, save/reopen, and compare expected bytes; repeat preservation and IME cases.
4. Create a comment with selected Unicode text via toolbar and keyboard; cancel one, save one, click its marker, reopen, and resolve it.
5. Apply the labeled anchor mutations and inspect attached text/orphan state in the app.
6. Complete the CLI agent loop against an app-created comment, including external source edits and an invalid sidecar/ID.
7. Open and source-edit each supported text format; inspect actual values and preview refresh. Read/search/zoom PDF where offered and compare its hash.
8. Repeat the core loop with keyboard and VoiceOver, then test recoverable failures and hostile content.
9. Measure the Release app under the Q8 protocol and retain raw samples.
10. Repeat critical UI flows three times, record failures/skips, and fill in the score, gates, and evidence grades.

The current [E2E coverage table](e2e-test-plan.md) identifies where existing
assertions are weaker than these tasks. In particular, composer creation/save,
gutter-click thread reveal, actual marker restoration, and external refresh need
direct observations. The historical 9/10 E2E result and repository score of 92
do not assign this rubric a grade. No new app-quality score is assigned by this
document.
