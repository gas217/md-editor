# Security Policy

## Reporting a vulnerability

If you find a security issue in MD Editor, please **do not** open a public GitHub issue. Instead:

1. Email the maintainer (see `git log` for the address) with subject line `[mdedit security] <one-line summary>`.
2. Include reproduction steps, affected versions, and your assessment of severity.
3. We'll acknowledge within 5 business days and aim to ship a fix within 30 days for high-severity issues.

After the fix ships, the issue is disclosed publicly with credit to the reporter (unless you ask otherwise).

## What counts as a security issue

- Code execution via crafted `.md`/`.csv`/`.json`/`.html`/`.pdf` content (we render in a sandboxed WebView; escapes are a security issue).
- Sandbox escape from the editor or preview WKWebView.
- Path traversal in the sidecar reader/writer.
- Data exfiltration via any code path (we promise zero outbound requests; a breach of that is a security issue).
- Code-signing / notarization bypass.
- Dependency vulnerabilities that affect the shipped binary.

## What doesn't count

- Misleading UI (file `bug` instead).
- Performance issues (file `bug`).
- The editor letting you edit a file you have OS-level permission to edit (that's the point).
- Theoretical issues without a working PoC.

## Threat model

MD Editor is a local-first viewer for files you already trust enough to put on your disk. We assume:
- The macOS Sandbox + Hardened Runtime + notarization are working as designed.
- The user controls their disk.
- The files opened may be malformed but are not actively malicious supply-chain attacks (an attacker who can write to your `~/runs/` already has full read access to your machine).

We do not assume:
- The user has correctly configured network firewalls (our defense: zero outbound requests).
- The user has audited every dependency (our defense: documented `LICENSES.md`, pinned versions).
- Files have been scanned by AV (irrelevant — we render in a sandboxed surface).

## Hardening commitments

- WebView CSP locked to `default-src 'none'` + explicit allow-lists per format (see VISION.md "HTML rendering trade-off").
- JS disabled in the HTML preview WebView; no `javascript:` URL handling.
- All file I/O via `NSFileCoordinator`; no direct `rename(2)` or POSIX shortcuts that bypass Versions/Sandbox.
- No `unsafe-eval`, no `eval()`, no `Function()` constructor in shipped JS.
- Dependencies pinned in `package-lock.json` (JS) and `Package.resolved` (Swift). CI fails on lockfile drift.
- Notarization required for every release artifact.
