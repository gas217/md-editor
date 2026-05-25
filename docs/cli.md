# `mdedit` CLI

The shell entry point. Symlinked to `/usr/local/bin/mdedit` by Homebrew cask. Hands off to the GUI app via `NSWorkspace.open` for file-open commands, and reads/writes sidecars directly for the agent loop.

## Synopsis

```
mdedit                                           # launch the app
mdedit <file>                                    # open a file in the running app (or launch + open)
mdedit comments <file> --unresolved --addressable
mdedit comments <file> --resolve <id> --reply <text>
mdedit merge-comments <file>.comments.json       # 3-way merge picker
mdedit --version
mdedit --help
```

## Commands

### `mdedit <file>`

Open `file` in the GUI app. If the app isn't running, launches it. Returns immediately (does not wait for the user to close the file).

### `mdedit comments <file> --unresolved --addressable`

Print to stdout, as JSON, every comment in `<file>.comments.json` that satisfies:
- `resolved == false`
- `addressable == true` (or contains an `@`-mention of a known agent)

Useful for an agent run that wants to see what's queued up.

```bash
$ mdedit comments docs/plan.md --unresolved --addressable
[
  {
    "id": "c_01HXYZABC...",
    "body": "@claude rethink step 3",
    "target": { ... },
    ...
  }
]
```

### `mdedit comments <file> --resolve <id> --reply <text>`

Append a reply to comment `<id>` in `<file>.comments.json` and set `resolved: true`. Exit code 0 on success, non-zero if the id is unknown.

```bash
$ mdedit comments docs/plan.md --resolve c_01HXYZABC --reply "Switched to invalidation on write"
```

### `mdedit merge-comments <file>.comments.json`

Resolve a git merge conflict on a sidecar. Opens a 3-way picker showing left/right/common ancestor; user picks per comment. Writes the merged sidecar atomically.

## Exit codes

| Code | Meaning |
|---|---|
| 0 | Success |
| 1 | Bad arguments |
| 2 | File not found |
| 3 | Sidecar parse error |
| 4 | Comment id not found |
| 5 | Merge conflict not resolved (user aborted) |
| 10+ | Internal error (bug) |

## Examples

```bash
# Hand the agent a list of work
mdedit comments plan.md --unresolved --addressable | claude "address these"

# After the agent edits the file, mark its comment resolved
mdedit comments plan.md --resolve c_01HXYZABC --reply "Addressed in commit abc123"

# Walk a directory of agent outputs
for f in ~/runs/2026-05-24/*.md; do
    echo "=== $f ==="
    mdedit comments "$f" --unresolved
done
```

## Environment

- `MDEDIT_APP_PATH` — override the GUI app path (default: `/Applications/MDEditor.app`).
- `MDEDIT_NO_GUI` — set to `1` to suppress the GUI launch on `mdedit <file>` (sidecar commands still work).
