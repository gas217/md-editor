# First-Run Test on a Clean Mac

Pre-release validation that the install + first launch + first useful action flow actually works on a machine that has never seen MD Editor before.

Last run: NOT YET — V1.0 build hasn't produced a binary.

## Test environment

Use a fresh macOS user account (not a fresh OS — a new account is sufficient). Sign out, create a throwaway test user, sign in.

## Steps and pass criteria

| # | Step | Pass criteria |
|---|---|---|
| 1 | `brew install --cask mdedit` (or download the DMG and drag to `/Applications`) | Install completes without errors. App appears in `/Applications`. |
| 2 | First launch via double-click | Gatekeeper does NOT show "from an unidentified developer." Window opens within 1 second. **No permission dialogs** (no Files, no Calendar, no Contacts, no Apple Events). |
| 3 | Open a `.md` file via File → Open | File renders in preview view. Cold-launch + first-open total <1 second. |
| 4 | Add a comment (select text → Cmd-Shift-M) | Comment composer appears. Type, hit Cmd-Enter or click Save. Margin indicator appears. |
| 5 | Quit and reopen the same file | Comment is restored at the same anchor position. |
| 6 | Verify the sidecar | `ls path/to/file.md.comments.json` shows the file. Open it; structure matches `docs/comments-schema.md`. |
| 7 | Run the CLI | `mdedit comments path/to/file.md --unresolved` prints the comment as JSON. |
| 8 | Uninstall | `brew uninstall --cask mdedit` (or drag from `/Applications`) leaves no orphan LaunchAgents, no `~/Library/Application Support/MDEditor`, no auto-update artifacts. (Sidecar files next to user files are NOT removed — those belong to the user.) |

## Log

| Date | macOS version | App version | Steps passed | Notes |
|---|---|---|---|---|
| TBD | TBD | v0.1.0 (scaffold) | n/a | No binary to test |

## What "fail" looks like

Any of:
- Permission dialog on first launch (violates "no permission prompts" success metric)
- First-paint >1 second on M-series (violates cold-launch budget)
- Comment doesn't re-anchor after quit+reopen (violates anchor-cascade correctness)
- CLI not found or non-zero exit (violates "registered opener + CLI" feature)
- Uninstall leaves orphans (sloppy)
