---
name: codewalk
description: Build a browser-based interactive call-stack viewer for code the user did not write — a senior-peer walkthrough of one execution path from a single entry point (route, handler, CLI command, queue job, UI action), rendered as a GitHub-PR-style three-pane app under `.codewalk/<slug>/` at the repo root. Auto-discovery triggers (case-insensitive substring match on the user's latest prompt) — `/codewalk`, `walk this code`, `walk me through`, `walk through this`, `trace this call stack`, `trace this flow`, `trace from`, `explain this flow`, `explain how this works`, `what happens when`, `onboard me to`, `call-stack viewer`, `code walkthrough`. Workflow shape — Phase 1 confirm entry (clarify ONLY on ambiguity) → Phase 2 read repo conventions → Phase 3 depth-first walk with a mandatory 5-function depth check → Phase 4 emit `data.json` → Phase 5 materialize the viewer by copying assets and writing `data.json` → Phase 6 launch `node serve.js` (with a fallback chain when Node is missing) → Phase 7 chat handoff (5 comprehension questions + decisions checklist). Locked contract — the viewer is the deliverable, not chat narration; branches not taken are listed BY NAME and never expanded; on ambiguity (env flags, feature gates, tenant guards, DI tokens, dynamic dispatch) the skill STOPS and asks rather than guessing; `.codewalk/` is added to `.gitignore`. Self-contained — never calls other skills.
---

# codewalk — interactive call-stack viewer for code you didn't write

The deliverable is a browser viewer the user opens to make decisions. Posture is senior peer walking the code with the user, not a tutor reciting it back. Every annotation the trace produces — purpose, side effects, risk, branches not taken, data shape — exists to let the user pick what to change and what to leave alone.

This skill is self-contained. It never calls other skills. Two reference files carry the heavy detail and are read on-demand:

- [`references/data-schema.md`](./references/data-schema.md) — the exact JSON contract the viewer consumes.
- [`references/trace-rubric.md`](./references/trace-rubric.md) — how to walk the stack with rigor (invoked-block detection, side-effect classification, picking the one risk, deferred-branch enumeration, depth check).

Read both before Phase 3 on first invocation in a session.

## When to invoke

Auto-discovery fires this skill when the user's latest prompt contains any of the substrings listed in the frontmatter description. The slash form `/codewalk` is the explicit handle.

**Invoke** when the user names an entry point and wants to see how it works end-to-end — a route, a handler, a CLI command, a queue job, a UI action. Typical phrasings: "walk me through what happens when this route fires", "trace the call stack from `POST /signup`", "explain how the migration runner works".

**Do not invoke** for one-shot questions answered by a single grep ("where is X defined", "find usages of Y"). Those go through `Explore` or `Grep` directly. Codewalk produces a viewer artifact — that's overkill for a definition lookup.

## Workflow shape

```
Phase 1 (confirm entry) → Phase 2 (read repo conventions) → Phase 3 (walk + depth check)
                       → Phase 4 (emit data.json) → Phase 5 (materialize viewer)
                       → Phase 6 (launch) → Phase 7 (chat handoff)
                       → On re-run with same slug: diff against previous data.json
```

### Phase 1 — Confirm the entry point. Ambiguity stops the skill.

Parse the user's request for a single entry. Resolve it to one file + line. If ANY of the conditions in `references/trace-rubric.md` §1 apply (multiple matching definitions, runtime-conditional registration, tenant guards, DI token resolution, dynamic dispatch), STOP and ask the user which path to trace. Never guess.

When the user confirms a path, print one line to chat:

```
Tracing entry: <file>:<line> for <entry_point>
slug: <derived-slug>
```

Slug derivation rules live in `references/data-schema.md` ("Slug convention"). HTTP routes → `<method-lowercase>-<path-sanitized>`. CLI commands → `cli-<sanitized>`. Queue jobs → `job-<queue>-<job-name>`. UI actions → `ui-<component>-<action>`. Sanitization is lowercase ASCII alphanumeric + dash, runs of dashes collapsed, leading/trailing dashes stripped, truncated to 80 chars.

### Phase 2 — Read the repo's conventions before annotating.

Spend 60-90 seconds on the surrounding repo before opening the entry function. The trace must annotate in the repo's own idiom. Specifically look at framework signature (NestJS / Express / Rails / Django / FastAPI / Spring / Phoenix), DI patterns, module boundaries, error model, and test convention. If a `README.md`, `CONTRIBUTING.md`, `ARCHITECTURE.md`, `CLAUDE.md`, or `.cursorrules` exists at the repo root, skim it. Details in `references/trace-rubric.md` §0.

### Phase 3 — Walk depth-first. Stop every 5 functions for a depth check.

For every function on the path, extract every field listed in `references/data-schema.md` "Nodes". The order is fixed:

1. `file` + `function_range` + `name`
2. `source` (raw, no normalization, no stripping)
3. Identify `invoked_range` + `invoked_lines` (§3 of the rubric — this is the hardest field to get right)
4. `call_sites` for outgoing calls ON THE PATH only
5. `docblock` (5 keys: purpose, inputs, outputs, side_effects, ownership)
6. `data_in` + `data_out` (typed pseudocode, not prose)
7. `risk` — exactly ONE concrete risk, smell, or load-bearing assumption
8. `branches_not_taken` — listed BY NAME with a one-line trigger condition, never expanded
9. `git_blame` — `git log -1 --pretty=format:'%an|%ad|%s' --date=short -- <file>`
10. `layer` — one of `controller`, `service`, `repository`, `external`, `other`

After every 5 functions added to the trace, print the depth-check block from `references/trace-rubric.md` §8 verbatim to chat (filled in) and wait for the user to choose `continue` / `switch branch` / `stop`. This block is the only safeguard against runaway DFS — it is not optional.

If the user picks `stop` mid-walk, the trace finalizes at the current state. The viewer renders whatever was collected.

### Phase 4 — Emit `data.json`.

Build `data.json` matching `references/data-schema.md` exactly. Field names are strict. Validate before writing:

- `nodes[0]` is the entry node, `order: 0`, `depth: 0`.
- Every `edges[i].from` and `edges[i].to` resolves to a `nodes[*].id`.
- Every `nodes[*].call_sites[*].callee_id` resolves to a `nodes[*].id`.
- `invoked_lines` for each node is a subset of line numbers in `function_range`.
- `source` line count equals `function_range[1] - function_range[0] + 1`.
- `slug` matches `/^[a-z0-9-]{1,80}$/`.
- Layer names in `diagrams.sequence_mermaid` capitalize to `Controller`, `Service`, `Repository`, `External`, `Other`.

Build the Mermaid sources for `sequence_mermaid` and `module_deps_mermaid` from the collected nodes. Lift every node's `branches_not_taken` into top-level `deferred_branches` with `parent_id` attached.

### Phase 5 — Materialize the viewer.

Create `.codewalk/<slug>/` at the repo root. Copy the four asset files from this skill's `assets/` directory into the trace folder, then write `data.json`:

```bash
mkdir -p .codewalk/<slug>
cp <skill-dir>/assets/index.html .codewalk/<slug>/index.html
cp <skill-dir>/assets/viewer.js  .codewalk/<slug>/viewer.js
cp <skill-dir>/assets/viewer.css .codewalk/<slug>/viewer.css
cp <skill-dir>/assets/serve.js   .codewalk/<slug>/serve.js
# write data.json
```

**Resolving `<skill-dir>`.** The Skill tool's invocation surfaces a line of the form `Base directory for this skill: <abs-path>` in the system context when this skill loads. That path is `<skill-dir>`. Read it from the invocation context — do not hard-code, do not guess. If for any reason the path is absent from context, fall back to discovery:

```bash
find "$HOME/.claude" "$HOME/Code" "$HOME/dev" "$HOME/Projects" \
  -type f -path "*/skills/codewalk/SKILL.md" 2>/dev/null | head -1 | xargs dirname
```

After the copy, verify each of the four files exists in `.codewalk/<slug>/`. If any is missing, stop and report — the viewer is unusable without all four.

**`.gitignore`.** If `.gitignore` exists at the repo root and does NOT already contain `.codewalk/`, append the line. If `.gitignore` does not exist, print this one-liner for the user:

```
echo '.codewalk/' >> .gitignore
```

`.codewalk/` is an ephemeral artifact — it doesn't belong in commits.

### Phase 6 — Launch.

Run from inside `.codewalk/<slug>/`:

```bash
cd .codewalk/<slug> && node serve.js
```

`serve.js` prints the URL on its own line and opens the default browser. Print that URL line into chat so the user can click it.

If `node` is not installed, fall back in this exact order, picking the first that exists. State which one was used:

1. `python3 -m http.server 8765`
2. `python -m http.server 8765`
3. `npx --yes serve -l 8765`
4. `php -S 127.0.0.1:8765`
5. `ruby -run -e httpd . -p 8765`

If none of these exist on PATH, stop and tell the user. The viewer is static — any HTTP file server works.

### Phase 7 — Chat handoff (5 questions + decisions checklist).

After the URL is printed, print TWO things to chat. NOT to the HTML.

**Five comprehension questions** answerable only by someone who internalized the flow. Examples and intent are in `references/trace-rubric.md` §9. Each question targets a specific layer boundary, side-effect, branch-not-taken, or data-shape transition observed in this trace.

**Decisions checklist** sorted into three buckets — `Safe to change`, `Load-bearing`, `Chesterton's fence (don't touch until you ask)`. One short line per item. Empty buckets get `- (none on this path)`. The point is to let the user end the session with action, not a feeling of being informed.

### Cache and diff (re-run with the same slug)

If `.codewalk/<slug>/data.json` already exists when Phase 4 starts, load the previous version into memory, run the new trace, then compute `diff_vs_previous`:

- `added_nodes` — node IDs present in new, absent in old.
- `removed_nodes` — node IDs present in old, absent in new.
- `signature_drift` — for each node present in both, compare `data_in`/`data_out` and `docblock.inputs`/`docblock.outputs`. Record before/after when they differ.
- `new_side_effects` — for each node present in both, compare `docblock.side_effects`. Record additions only (removals are noise).

Empty arrays in `diff_vs_previous` are fine. The viewer renders an amber callout when the object is non-null and at least one array has entries.

## Anti-rationalizations

| Tempting shortcut | Why it breaks the deliverable |
|---|---|
| "I'll mark every line as invoked since the function ran on this path." | The green-highlight is the viewer's primary signal. Marking every line green means the `else` arm with 30 dead lines looks like it fired. The user can't see what didn't run. |
| "I'll expand the branches-not-taken to show what they would have done." | The brief bans expansion explicitly. A trace that recurses into every conditional is no longer a trace of ONE path — it becomes a static call graph, and the green-highlight collapses. List by name, attach a one-line trigger. |
| "The entry has a feature flag, but I'll trace the on-path and note it in chat." | Wrong. Print the ambiguity, stop, ask. The user named an entry point; they did not name a flag state. Guessing produces a viewer the user can't act on because they don't know which world it modeled. |
| "Three risks for this node — they're all real." | The risk field is the most-read piece of metadata in the right rail. Three risks means the reader skims. Pick the one that meets the highest bar in `references/trace-rubric.md` §6. If genuinely none, write `"none observed on this path"`. |
| "I'll skip the 5-function depth check on a fast walk." | The depth check is the only safeguard against runaway DFS. On a short path it fires once at the end. On a long path it gates the user's choice to pivot. Skipping it produces 20-node walks where the user wanted 5. |
| "I'll regenerate `index.html` from scratch instead of copying the asset." | The skill bundles a tested viewer. Regenerating drifts: same skill, different viewer quality across runs. Copy the asset; only `data.json` varies. |
| "I'll mark `req.user` reads as `auth` side effect." | Side-effect classification is for ACTIONS, not reads. `req.user` is already-populated input; the auth side effect lives upstream in the guard that set it. Mis-classifying inflates the chips and makes the trust signal noise. |
| "The user said `walk through this PR` — close enough." | A PR is a diff, not an entry point. Codewalk traces ONE execution path from ONE entry. If the user means a PR review, that routes through `hackify:hackify` Phase 5 or `code-review`, not here. |

## File map

```
skills/codewalk/
├── SKILL.md                       ← this file
├── assets/
│   ├── index.html                 ← viewer shell (Tailwind + Alpine + Prism + Mermaid + marked, all CDN)
│   ├── viewer.js                  ← Alpine component (load/render/navigate/diagrams)
│   ├── viewer.css                 ← Prism overrides + invoked-line highlight + tooltip
│   └── serve.js                   ← Node stdlib HTTP server (port pick + browser open)
└── references/
    ├── data-schema.md             ← the exact JSON contract the viewer consumes
    └── trace-rubric.md            ← how to walk the stack (invoked block / side effects / risk / branches / depth check)
```

The viewer per-trace lives at `.codewalk/<slug>/` in the target repo (not in this skill folder):

```
<repo-root>/.codewalk/<slug>/
├── index.html         ← copied from skills/codewalk/assets/
├── viewer.js          ← copied
├── viewer.css         ← copied
├── serve.js           ← copied
└── data.json          ← generated this run (the only file that varies per trace)
```

## Expected non-issues in the browser console

- **"cdn.tailwindcss.com should not be used in production"** — Tailwind Play CDN prints this on every page load. The viewer is a local development tool, not production. The warning is informational; it is not a bug.
- A 404 for `/favicon.ico` on older copies of the viewer (pre-favicon-fix) is also harmless. The current `index.html` inlines a data-URI favicon, so this should not appear on fresh traces.

## What this skill does NOT do

- It does not modify the traced repo's source code. Every output lives under `.codewalk/<slug>/`.
- It does not perform code review or suggest refactors. The `risk` field flags one concern per node — it does not propose a fix.
- It does not generate tests, types, or documentation. Those are downstream of the walk, not part of it.
- It does not navigate cross-process call stacks (RPC, queues across services). External calls are leaves on the trace; if the user wants to follow them, that's a fresh `/codewalk` rooted in the downstream service.
- It does not replace `Explore` or `Grep` for one-off lookups. Those tools answer `where is X`. Codewalk answers `what happens when Y fires`.

## One-line summary

`/codewalk <entry-point>` → depth-first walk with stop-and-ask on ambiguity → `.codewalk/<slug>/{index.html, viewer.js, viewer.css, serve.js, data.json}` → `node serve.js` → browser viewer + 5 comprehension questions + decisions checklist.
