# Comments Sidecar Schema

The wire format for `foo.<ext>.comments.json`. Stable as of `version: 1`. Backward-compatible additions (new optional fields) don't bump the version; breaking changes do.

Companion: `VISION.md` § "Commenting Design" (the design rationale lives there). This file is the *machine-readable* contract — what tools producing or consuming the sidecar must respect.

## Top-level

```json
{
  "version": 1,
  "document": {
    "path": "foo.md",
    "sha256": "..."
  },
  "comments": [ ... ]
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `version` | integer | yes | Must be `1` for the current schema |
| `document.path` | string | yes | Relative to the sidecar's directory; usually the basename |
| `document.sha256` | string | yes | SHA-256 of the LF-normalized UTF-8 bytes of the source file. Tripwire for out-of-band edits. CSV exception: hash is still over the LF-normalized form even though CSV preserves CRLF on save. |
| `comments` | array | yes | Sorted by `id` (ULID time-ordering). Empty array is valid. |

## Comment

```json
{
  "id": "c_01HXYZABC...",
  "createdAt": "2026-05-23T14:00:00Z",
  "author": { "kind": "human", "name": "ag" },
  "body": "@claude rethink step 3 — won't work with the new API #bug #api-v2",
  "mentions": [{ "kind": "agent", "name": "claude" }],
  "tags": ["bug", "api-v2"],
  "resolved": false,
  "addressable": true,
  "status": "active",
  "target": { ... },
  "thread": [ ... ]
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes | ULID, 26-char Crockford base32. Sorted lexicographically = sorted by time |
| `createdAt` | string (ISO-8601, UTC) | yes | |
| `author` | object | yes | See *Author* |
| `body` | string | yes | UTF-8, NFC-normalized. Mentions and tags are present in the body verbatim |
| `mentions` | array of *Mention* | no | Parsed from `body`. Empty/missing = no mentions |
| `tags` | array of string | no | Parsed from `body`. Empty/missing = no tags |
| `resolved` | boolean | no | Default `false`. Agents flip this to `true` after addressing |
| `addressable` | boolean | no | Default `false`. `@<agent>` mention implies `true` for that agent |
| `status` | string | no | One of `active` \| `orphaned` \| `resolved` \| `archived`. Default `active`. `orphaned` set by anchor resolver when no selector attaches. `archived` set by user delete |
| `target` | object | yes | The anchor. See *Target* |
| `thread` | array of *Reply* | no | Default empty |

## Author

```json
{ "kind": "human", "name": "ag" }
{ "kind": "ai", "name": "claude", "model": "claude-opus-4-7" }
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `kind` | string | yes | `human` \| `ai` |
| `name` | string | yes | For humans: a display handle. For agents: the agent name (`claude`, `gemini`, `codex`, `apple-intelligence`) |
| `model` | string | no | Specific model identifier when `kind == "ai"` |

## Mention

```json
{ "kind": "agent", "name": "claude" }
{ "kind": "user", "name": "ag" }
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `kind` | string | yes | `user` \| `agent` |
| `name` | string | yes | The handle/agent name without the leading `@` |

## Target

```json
{
  "selectors": [
    { "type": "TextPositionSelector", "start": 1423, "end": 1467, "startLine": 42, "endLine": 43 },
    { "type": "TextQuoteSelector", "exact": "...", "prefix": "...", "suffix": "..." }
  ]
}
```

`selectors` is an array tried in order during anchor resolution. Format-specific selectors are documented in `VISION.md` § "Selector types (one set per format family)". Authoritative selector types:

- `TextPositionSelector` — UTF-16 offsets + 1-indexed line numbers
- `TextQuoteSelector` — exact + 32-grapheme prefix/suffix, NFC
- `CSVCellSelector` — `{ rowIndex, columnIndex, headerName? }`
- `CSVRowRangeSelector` — `{ startRowIndex, endRowIndex, primaryKeyColumn?, primaryKeyValue? }`
- `JSONPointerSelector` — `{ pointer }` (RFC 6901)
- `JSONValueSelector` — `{ valueHash }` (SHA-256 of canonical serialization)
- `PDFAnnotationSelector` — `{ pageIndex, rect, quadPoints?, selectedText? }`

## Reply (thread entry)

```json
{
  "author": { "kind": "ai", "model": "claude-opus-4-7", "name": "claude" },
  "createdAt": "2026-05-23T14:12:00Z",
  "body": "Switched to invalidation on write; see commit abc123"
}
```

Replies don't have their own `id`, `target`, or `mentions` — they inherit context from the parent comment.

## Forward compatibility

- Producers MUST emit `version: 1` and SHOULD reject sidecars with a higher `version`.
- Consumers MUST ignore unknown top-level fields.
- Consumers MUST ignore unknown selector `type` values (don't break the cascade — skip the unknown and try the next).
- Adding a new optional field on `Comment` or `Author` is non-breaking; adding a required field bumps `version`.
