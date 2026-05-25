# Brand Brief — MD Editor (working name)

For a designer doing **name + icon** for the app. Codename `MD Editor` / `mdedit`
holds until this brief produces a final name.

## What the product is (60 seconds)

A lightweight native macOS viewer + light-editor for the text files AI agents
produce — `.md`, `.txt`, `.csv`, `.json`, `.html`, `.pdf`. The wedge is
**first-class commenting**: select text in any file, leave a margin note, the
comment is stored in a sidecar JSON next to the file. A Claude Code agent reads
those comments, addresses them, replies, marks them resolved — the whole loop
runs through plain files, no plugin, no API.

8.8 MB binary. Sub-500ms cold launch. Native AppKit + CodeMirror 6.

## Who it's for (the brand persona)

The solo dev whose workflow is **Claude Code dropping `.md` plans, `.csv`
results, `.json` tool outputs into their repo all day**. They want to glance,
fix a typo, leave a note for the next agent run, close the file. They will not
install Electron. They will not sign into a service. They run Homebrew and live
in the terminal half the day.

The brand should feel like a tool this person would put in their dotfiles repo.

## Anti-positioning

The name should NOT feel like:

- **Obsidian** — vault, knowledge graph, mystical-stone-of-second-brain energy
- **Notion** — startup workspace, collaboration suite, calendar feature creep
- **Cursor** — IDE, AI cursor, "we will build everything for you" promise
- **MarkEdit / Marked / MarkdownPad** — "yet another markdown editor"
- **iA Writer** — author-y, retreat-into-focus, anti-AI stance
- **Bear** — animal-named cuddly Apple-only notes app

The name should feel like:

- **Sublime Text** — built for people who care about how their tools work
- **Tailscale** — software that just stops being in your way
- **Zed** — short, confident, performance-led
- **Linear** — sharp, opinionated, no apology for what it isn't

## Tone words

Lightweight · honest · understated · technical · slightly bookish · not cute ·
not enterprise · not AI-themed (the AI is in the loop, not the brand)

## What the name should signal (in priority order)

1. **The wedge: commenting / annotation** — the thing MarkEdit can't do
2. **Lightweight / fast / restrained** — the product is small on purpose
3. **Document-shaped** — files are first class; not "documents" in the
   Google-Docs cloud sense, files on your disk
4. *(optional, not required)* — the AI loop. Don't put AI in the name; the
   product survives the hype cycle by not anchoring to it.

## Naming candidates by direction

Picked for fit, pronounceability, and (best guess) `.app` / `.dev` /
`.com` availability. ★ marks the strongest of the bunch.

### Collision audit

Names struck through have a direct collision in the note / text / PDF /
markdown app space and should not be used without renaming the incumbent:

- ~~**Sidenote**~~ — SideNotes (Apptorium Mac sticky-notes app)
- ~~**Skim**~~ — major Mac PDF reader
- ~~**Vellum**~~ — vellum.pub, Mac book-formatting tool
- ~~**Quire**~~ — quire.io, project management
- ~~**Endnote**~~ — Clarivate's reference manager
- ~~**Tome**~~ — tome.app, AI presentation tool
- ~~**Nook**~~ — Barnes & Noble e-reader
- ~~**Halo**~~ — Microsoft franchise
- ~~**Sparrow**~~ — defunct Mac email client (iconic association)

Names with adjacent baggage (collision in a different domain — usable,
not clean):

- ⚠ **Hatch** — Hatch sleep/sound brand
- ⚠ **Codex** — OpenAI Codex + GitHub
- ⚠ **Postscript** — Adobe language + Postscript.io (SMS marketing)
- ⚠ **Glance** — Glance workplace AI + various Mac plugins
- ⚠ **Folio** — Adobe DPS legacy + many
- ⚠ **Beacon** — overused across spaces
- ⚠ **Lighthouse** — Google Chrome devtool
- ⚠ **Waypoint** — Hashicorp deploy tool
- ⚠ **Mura** — Mura CMS (different space, real product)
- ⚠ **Pin** — Pinterest, Pinboard
- ⚠ **Karn** — Magic: The Gathering character
- ⚠ **Nib** — Apple's `.nib` Interface Builder format
- ⚠ **Marg** — reads as a person's name

Likely clean (no collision in adjacent space we're aware of):

- ✓ **Margin** — closest is MarginNote (niche Chinese PDF annotator)
- ✓ **Marginalia**, **Aside**, **Footnote**, **Cairn**, **Codicil**, **Errata**
- ✓ **Annote**, **Mardo**, **Glanze**

**Caveat:** this audit is a first pass from memory. Before committing to a
name, run: USPTO trademark search + `.app`/`.com` domain check + Mac App
Store + Homebrew cask search. Cheap; worth doing.

### Updated shortlist

After strikes:

1. **Margin** — clean enough; MarginNote is the only adjacent name and it's niche
2. **Cairn** — clean
3. **Postscript** — usable with the Adobe baggage
4. **Folio** — usable with the Adobe DPS baggage
5. **Marginalia** — clean, just long

Coined fallback after re-audit: **Mardo** (Mura was struck for CMS collision).

### A. Annotation / margin family — the wedge

| Name | Why it works | Why it might not |
|---|---|---|
| **Margin** ★ | On-the-nose for the wedge. 6 letters. "Open in Margin." | Generic, possibly contested .app domain |
| **Marginalia** | Historically correct (scholar notes in book margins) | 5 syllables, hard to brand |
| **Marg** | Margin as nickname; short and friendly | Could read as a person's name |
| **Aside** | "I'll add an aside on this paragraph" | Short verb-meaning conflicts |
| **Sidenote** ★ | Plain English for what comments are | One word? Two? Could feel descriptive |
| **Footnote** | Universally understood | "Foot" reads as bottom-of-page only |
| **Hatch** | Marginal hatching; also "hatching ideas" | Sleep-tracking brand already |
| **Glyph** | Typography-adjacent, technical | A million dev tools named this |
| **Nib** | Pen tip; small, focused | Tiny and dense — could go either way |
| **Notabene** / **N.B.** | Classical "note well"; bookish | Long; hard to say |

### B. Trail-marker / waypoint family — "mark the path through AI outputs"

| Name | Why it works | Why it might not |
|---|---|---|
| **Cairn** ★ | Trail-marker rock pile. Distinctive. Pleasant to say (KAYRN). Comments mark a path through the doc pile. | Most people won't immediately know what a cairn is |
| **Beacon** | "Drop a beacon for Claude to see" | Used a lot in dev tools |
| **Waypoint** | Comments as waypoints in a doc journey | Hashicorp product owns this |
| **Pinpoint** | Anchored comments | Clinical |
| **Landmark** | Distinctive features in the doc | Bland |
| **Lighthouse** | Guides the agent to fix things | Google product owns this |

### C. Post / after-the-fact family

| Name | Why it works | Why it might not |
|---|---|---|
| **Postscript** ★ | P.S. = the annotation after the doc. Distinctive. | PostScript-the-Adobe-format collision; mostly invisible to modern users |
| **Codicil** | Legal addendum to a will — bookish, distinctive | Obscure |
| **Addendum** | Plain meaning | Long, awkward |
| **Endnote** | Familiar academic term | Endnote (the reference manager) owns it |
| **Errata** | "Notes about what's wrong" | Implies bugs, wrong vibe |

### D. Document / textual family

| Name | Why it works | Why it might not |
|---|---|---|
| **Folio** ★ | Book-page word. Crisp. "Open in Folio." | Generic in print contexts; some collision |
| **Vellum** | Historic writing surface | Vellum.pub (book formatting tool) owns it |
| **Quire** | 24 sheets of paper; bookish, obscure | Too obscure |
| **Codex** | Bound manuscript; Latin gravitas | Codex (the GitHub Copilot predecessor) — collision |
| **Tome** | Heavy book — wrong for "lightweight" | Inverts the positioning |

### E. Lightweight / fast family

| Name | Why it works | Why it might not |
|---|---|---|
| **Wisp** | Tiny, light, immaterial | Maybe too light; doesn't say "tool" |
| **Glance** ★ | The persona's verb. "Just glance at this CSV." | A bit generic |
| **Skim** | Same idea, more colloquial | Skimlinks, etc. dilute it |
| **Brief** | "It's a brief." Document + short. | Reads like a noun more than a brand |
| **Sparrow** | Small fast bird; Apple-app aesthetic | Sparrow (the killed-by-Google email app) is the strongest association |
| **Halo** | Light, encircling — like the inspector around the doc | Microsoft game franchise |

### F. Single-syllable / minimal (Zed / Bear style)

| Name | Why it works | Why it might not |
|---|---|---|
| **Aside** | Margin note + literary device | See A |
| **Brief** | See E | See E |
| **Trace** | What comments leave behind | Many dev tools |
| **Nook** | A small place to put a note | Barnes & Noble e-reader |
| **Loft** | Light, raised, spacious | Real-estate-y |
| **Stake** | Cairn-adjacent | Aggressive |
| **Pin** ★ | "Pin a comment to that line." Short. | Pinterest collision |

### G. Coined / wordmark candidates

For a designer who'd rather draw a logotype than fight for an English word's
.app domain.

| Name | Origin | Notes |
|---|---|---|
| **Annote** | annotation - tion | Pleasant, soft consonants |
| **Skribl** | scribble - e | Tech-y, plays with letters |
| **Mardo** | markdown - kn | Echo of md + Spanish "ardor" warmth |
| **Mura** | Japanese village; also implies a small surface | Clean, evocative, no English collision |
| **Inka** | inkling / ink | Short, friendly |
| **Glanze** | glance + glaze (light reading) | Has a German softness |
| **Karn** | Cairn alt spelling | Edgier; might trademark cleanly |

### H. Mash-ups / compounds

- **Inkpad** (real product exists)
- **Margin Note** / **MarginNote** (real product exists — Chinese PDF annotator; collision)
- **Notewise** (sounds like a generic note app)
- **Markmail** (too email-y)
- **Codenote** (too coder-y)

## Top 5 to put in front of the designer

If the designer wants a shortlist to react to, this is the brief's
recommendation, ordered by how strongly each lands the wedge:

1. **Margin** — most legible wedge, hardest to defend (generic word)
2. **Cairn** — most distinctive, requires one beat of explanation
3. **Postscript** — most bookish, mild Adobe-format collision
4. **Folio** — cleanest document-y feel, slightly generic
5. **Sidenote** — most literal, English-fluent name

If none of those click for the designer, the strongest coined option is
**Mura** — clean, no English baggage, lots of mark-making metaphors to draw
from in the icon work.

## Icon brief (separate but related)

A few constraints the designer should know before sketching:

- **Mac app icon canvas**: Squircle. Must read at 16×16 in Spotlight, 128×128
  in the Dock, 1024×1024 in About.
- **Sits next to**: Finder, TextEdit, MarkEdit (CM6 + paper), Bear (bear cub),
  iA Writer (Aa). Should not look like another doc-with-a-pen.
- **Visual hooks the product gives us**:
  - Comments in the margin (margin marks, sidebar dots, gutter glyphs)
  - A document with a callout / pin / tag
  - Two columns: doc + annotation
  - A speech bubble *next to* a doc (not a chat bubble)
  - A cairn / trail marker (if the name lands there)
- **Avoid**: pencil-on-paper (every editor), brain (Obsidian), AI sparkles
  (Cursor / Notion AI / ChatGPT), gradients heavier than Sequoia's defaults
- **Color**: the renderer ships with `#0366d6` (link blue) and `#69b7ff`
  (dark-mode link). The icon doesn't have to match these but can.

## What I'm asking from the designer

1. **React** to the top-5 names. Veto, refine, propose something better.
2. **Decide** on the name before icon work starts.
3. **Sketch** 3 icon directions on the chosen name. We pick one, iterate.
4. **Deliver** the macOS icon set per `App/Assets.xcassets/AppIcon.appiconset/Contents.json`
   (10 mac variants from 16×16 @1x through 512×512 @2x).
5. **Wordmark** at the same time — for README, landing page, in-app About box.

## Out of scope for this brief

- Pricing / tagline / website copy (separate brief at public-ship time)
- App Store screenshots (we're not in App Store; see VISION.md non-goals)
- Mascot / personality (the brand is a tool, not a character)
- Brand colors beyond the existing link blue (designer can propose)
