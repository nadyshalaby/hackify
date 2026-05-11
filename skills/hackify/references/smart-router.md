# Smart router — three-signal-group classifier

Before entering Phase 1, the router decides whether the user prompt actually belongs in full hackify, in quick mode (`/hackify:quick`), or in brainstorm. Three signal groups are evaluated against the user's most recent prompt (the one that triggered this skill load); exactly one must fire to commit to that route. If zero or two-or-more groups fire, default to full hackify — the most-ensured decision.

### Signal group (i) — Brainstorm triggers

If the user prompt contains any of the following (case-insensitive substring match), route to the `brainstorm` skill (NOT quick or full). Brainstorm itself decides when the conversation graduates to a build task and hands off to Phase 1 of full hackify.

- `/brainstorm`
- `let's discuss`
- `let's think`
- `what if`
- `brainstorm`
- `explore the idea`

### Signal group (ii) — Full-mode triggers

Any of the following routes to full hackify (`/hackify:hackify`) from the start.

- **Auth/security keywords** (case-insensitive substring): `auth`, `crypto`, `migration`, `secret`, `token`, `password`.
- **Multi-file scope keywords** (case-insensitive substring): `across all`, `refactor everything`, `redesign`, `everywhere`.
- **Architecture keywords** (case-insensitive substring): `schema`, `data model`, `API surface`.
- **Prompt length > 80 characters** AND not already brainstorm-tagged (Group (i) did not fire).
- **Explicit `/hackify:hackify` slash** in the prompt.

### Signal group (iii) — Quick-eligible

None of Group (i) or Group (ii) fired AND the user prompt is concrete — either a file path is mentioned, or a single behavioral change is named. Route to `/hackify:quick`.

## Decision table

| Signal group fired | Route to | Rationale |
|---|---|---|
| Group (i) only — brainstorm triggers | `brainstorm` skill | The user is in idea-exploration mode; brainstorm graduates to full hackify Phase 1 when the conversation converges on a build task. |
| Group (ii) only — full-mode triggers | Full hackify (`/hackify:hackify`) | The task carries security/scope/architecture surface, or the user explicitly asked for the heavier flow — quick mode's carve-out does not cover it. |
| Group (iii) only — quick-eligible | `/hackify:quick` | The prompt is small, concrete, and free of security/scope/architecture signals — quick mode is the right speed-to-discipline tradeoff. |
| Zero groups fired | Full hackify (default) | The prompt is ambiguous or off-pattern; default-to-full is the most-ensured decision — full hackify's Phase 1 clarify wizard will disambiguate before any code lands. |
| Two-or-more groups fired | Full hackify (default) | Conflicting signals mean the task spans multiple shapes; default-to-full lets Phase 2 Plan+Gate resolve the scope before implementation starts. |

## Fallback rule

**Fallback rule.** If the signal-group count is not exactly 1 (i.e., zero groups fire OR two-or-more groups fire), default to full hackify. Default-to-full is the documented most-ensured decision — quick mode is a carve-out, not a default.

The same router logic lives in `skills/quick/SKILL.md` so both skills route consistently — if the user lands on quick first, that skill's router will hand off to full hackify under the same conditions documented above.

## Consumers

This reference is consumed by:
- `skills/hackify/SKILL.md` — full workflow's pre-flight router check.
- `skills/quick/SKILL.md` — compressed-flow's pre-flight router check.

Both files link here via the verbatim **Stub template** below. Edit the router rules HERE; the stubs are byte-stable.

## Stub template (verbatim — copy into consuming SKILLs)

The link target uses a repo-rooted leading-slash path so a single byte-stable stub works from BOTH consuming SKILL locations (`skills/hackify/SKILL.md` and `skills/quick/SKILL.md`). Bare relative paths break for the second consumer because the file does not live under `skills/quick/references/`.

```markdown
## Pre-flight: smart router — pick the right flow

Before doing anything else when invoked, this skill runs the smart-router pre-flight check. Three signal groups are evaluated against the user's most recent prompt; exactly one must fire to stay in this skill. If zero or two-or-more groups fire, default to full hackify — the most-ensured decision.

→ See [`skills/hackify/references/smart-router.md`](/skills/hackify/references/smart-router.md) for the full classifier (signal groups, decision table, fallback rule). The reference is the canonical source; this stub is byte-stable across both `hackify` and `quick` SKILLs.
```
