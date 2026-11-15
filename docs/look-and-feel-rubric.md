# MD Editor look and feel rubric

Evaluate the visual experience separately from [task usability and correctness](quality-rubrics.md).
The intended character is a quiet, document-first Mac utility: understated,
readable, technical, and slightly bookish, consistent with the [brand brief](brand-brief.md).
Successful task completion does not establish visual quality; an attractive
screenshot does not establish successful task completion.

## Scoring

Score each dimension 0–4. Use U for unobserved. The score is
`sum(weight × rating / 4)`, out of 100. Keep this score separate from the product
score. The proposed acceptance threshold is **85/100, every dimension at least
3, and E2 evidence for every dimension** using the main rubric's evidence scale.
An unknown dimension makes the result incomplete; retain the denominator when
reporting a lower bound. Do not assign points just because CSS or a design exists.

| Rating | Observable result |
|---|---|
| 0 | Content or essential controls are visually unusable. |
| 1 | Severe clipping, illegibility, or inconsistent states disrupt ordinary reading. |
| 2 | Ordinary reading works, but one or more listed core checks fail. |
| 3 | All core checks pass across the review matrix. |
| 4 | All core and stress checks pass; annotated evidence shows consistent detail. |
| U | The running candidate has not been observed under the required conditions. |

| ID | Dimension | Weight |
|---|---|---:|
| V1 | Typography and document hierarchy | 20 |
| V2 | Layout, spacing, and resizing | 20 |
| V3 | Markdown editing states | 15 |
| V4 | Comments and thread presentation | 15 |
| V5 | Color, appearance, and focus | 15 |
| V6 | macOS visual consistency | 10 |
| V7 | Transitions and finishing details | 5 |
| | Total | 100 |

## V1 Typography and document hierarchy

**Core for 3:** heading levels, prose, quotations, code, links, and list nesting
have distinguishable styles. Body text is comfortable at the default size;
code uses a consistent monospace face without changing surrounding line rhythm.
Headings remain more prominent than toolbar/status text. Paragraph and section
spacing follows a consistent pattern. Emoji, combining marks, and CJK do not
clip or disturb baselines. Font substitutions do not produce missing glyphs.

**Stress for 4:** long documents remain easy to scan; heading levels 1–6,
multiline quotes, nested lists, inline code, and fenced code retain hierarchy
at enlarged text size and at narrow and wide window sizes.

## V2 Layout, spacing, and resizing

**Core for 3:** document margins, gutter, inspector padding, and toolbar spacing
form a consistent layout. Opening the inspector leaves a useful reading area.
No status labels, composer controls, or document text overlap or clip at the
minimum supported window size. Empty space supports reading rather than
stranding controls. Long lines have an intentional wrap or scroll behavior.

**Stress for 4:** wide tables, long URLs, long filenames, and multiline code
retain readable alignment throughout a slow resize. The inspector's empty,
composer, and thread states align to the same edges without unexplained jumps.

## V3 Markdown editing states

**Core for 3:** source markers reveal predictably around the caret. Moving
between heading, link, list, and code lines preserves readable text, selection,
and caret visibility. Syntax markers do not crowd prose or resemble saved
content when hidden. Search highlights and comment highlights remain distinct.

**Stress for 4:** before/after screenshots of editing, selecting, finding, and
undoing show no unexplained scroll shift greater than one body-text line, no
flashing duplicate text, and no leftover decoration after deleting syntax.
Functional rendering failures are also recorded under Q2; keep the two scores separate.

## V4 Comments and thread presentation

**Core for 3:** gutter indicators look actionable and sit beside their text.
Active and resolved states have distinguishable shapes or labels as well as
color. The selected quote, human comment, author, replies, and status have a
clear visual hierarchy. Composer input and Save/Cancel controls are readable.
An empty inspector explains how to begin without competing with the document.

**Stress for 4:** long quotes, replies, repeated mentions/tags, several comments
on one line, and 100-comment documents remain scannable. Hover and keyboard
focus make the exact target clear. Inspector content scrolls without hiding
essential controls or covering the editor. Record navigation success under Q4.

## V5 Color, appearance, and focus

**Core for 3:** light and dark appearance each use coherent document, gutter,
inspector, input, and toolbar surfaces. There are no accidental white strips,
low-visibility carets, or unreadable selected text. Secondary text is subordinate
but readable. Links, errors, search, comments, and focus are visually distinct;
state meaning is also conveyed by shape, text, or an icon.

**Stress for 4:** changing appearance with a selection, search, and inspector
open leaves no stale colors. Inspect inactive-window selection and system
Increase Contrast. Record measured contrast pairs and the agreed acceptance
target; avoid judging contrast from a screenshot alone.

## V6 macOS visual consistency

**Core for 3:** title bar, toolbar, menus, controls, dividers, and focus treatment
fit the app's native AppKit/SwiftUI surfaces. Icons share a consistent weight
and size. Labels and shortcut notation agree across menus and tooltips.
The editor and native inspector feel like parts of the same document window.

**Stress for 4:** active/inactive windows, fullscreen, multiple documents, and
native open/save/error panels retain a coherent visual hierarchy. Check both
Retina and an available non-Retina display; mark unavailable coverage U.

## V7 Transitions and finishing details

**Core for 3:** opening, resizing, toggling the inspector, and switching threads
avoid blank flashes, stranded overlays, or visible layout settling. Disabled,
empty, error, and loading states use consistent wording, alignment, and styling.

**Stress for 4:** capture transitions at native display frame rate with system
Reduce Motion enabled and disabled. No motion obscures the reading position or
delays input. Save errors leave the draft visibly present. Latency is scored
quantitatively under Q8, independently of this visual assessment.

## Review matrix and evidence

Use the exact candidate app in normal mode. Record commit/dirty patch, bundle
hash, macOS version, appearance, display scale, window size, and font settings.
Capture the full window and relevant detail crops; do not crop away defects.

1. Review the same Markdown fixture in light and dark appearance at minimum,
   laptop, and wide sizes, with the inspector open and closed.
2. Include headings 1–6, nested lists, tasks, quotes, links, images, frontmatter,
   a wide GFM table, long code, Unicode, and a plain paragraph being edited.
3. Inspect an empty inspector, selected quote/composer, saved active comment,
   resolved thread, long reply, multiple markers, search, and focus traversal.
4. Record expected versus actual behavior, annotated screenshots or short videos,
   and V IDs for each finding. Use a second reviewer for the 4-level claims
   that depend on reading hierarchy or scanability; preserve disagreement.

The [evaluation template](quality-evaluation-template.md) records this score
alongside product quality, mandatory gates, and evidence. No candidate has been
graded by the existence of this document.
