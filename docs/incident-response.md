# Incident Response

When a P0 or P1 hits a shipped release.

## During the incident

1. **Acknowledge in writing** (GitHub issue, pinned): `Investigating reports of <symptom> in vX.Y.Z`. Within 30 minutes of discovery.
2. **Triage severity.** Use `docs/rollback.md` § "Severity assessment first" to decide P0/P1/P2.
3. **If P0/P1:** follow `docs/rollback.md` rollback steps. Goal: bleed stopped within 30 min, communicated within 1 hour.
4. **If P2:** schedule the fix; close the incident loop on the GitHub issue.
5. **Keep a running log** in the GitHub issue: timestamps + what was tried. This becomes the post-mortem source material.

## After the incident (post-mortem)

Within 7 days of resolution, append a post-mortem to this file using the template below. The post-mortem is public (this file is in the repo).

### Post-mortem template

```markdown
## YYYY-MM-DD — <symptom> in vX.Y.Z

**Severity:** P0 / P1 / P2
**Detected:** YYYY-MM-DD HH:MM by <how>
**Resolved:** YYYY-MM-DD HH:MM
**Duration:** N hours
**Affected:** approx N users / X% of installed base / unknown

### What happened
<one paragraph>

### Why it happened
<root cause; not a finger-point — usually a process or tooling gap>

### What we did
- Time T+0: <action>
- Time T+15m: <action>
- ...

### What we'd do differently
- <prevention>
- <faster detection>
- <faster mitigation>

### Action items
- [ ] (owner) (deadline) <thing>
- [ ] (owner) (deadline) <thing>
```

## Blameless culture

Post-mortems describe systems and decisions, not the person who pushed the bad commit. Anyone calling out a contributor by name in a post-mortem gets a redaction request.

## Drills

The point of having this file is that it gets exercised. Schedule one no-stakes incident-response drill per quarter — a synthetic alert that runs the full playbook from "issue pinned" through "post-mortem published."

## Past incidents

(None yet. V1.0 hasn't shipped.)
