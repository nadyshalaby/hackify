---
name: codewalk
description: DEEP-BY-DEFAULT browser-based interactive call-stack viewer for code the user did not write — a senior-peer walkthrough of one execution path from a single entry point (route, handler, CLI command, queue job, UI action), rendered as a GitHub-PR-style three-pane app under `.codewalk/<slug>/` at the repo root. Auto-discovery triggers (case-insensitive substring match on the user's latest prompt) — `/codewalk`, `walk this code`, `walk me through`, `walk through this`, `trace this call stack`, `trace this flow`, `trace from`, `explain this flow`, `explain how this works`, `what happens when`, `onboard me to`, `call-stack viewer`, `code walkthrough`. Workflow shape — Phase 1 confirm entry (clarify ONLY on ambiguity) → Phase 2 read repo conventions → Phase 3 deep depth-first walk to LEAVES (controller → service → repository/external + every type/interface/DTO/Zod schema crossed on the path, emitted as separate `layer: "type"` nodes hyperlinked from the function nodes that reference them) → Phase 4 emit `data.json` → Phase 5 materialize the viewer by copying assets and writing `data.json` → Phase 6 launch `node serve.js` (with a fallback chain when Node is missing) → Phase 7 chat handoff (5 comprehension questions + decisions checklist). Locked contract — **the trace is deep-by-default, types are first-class nodes, and re-invokes UPDATE rather than overwrite**: walk to leaves regardless of size, emit a `layer: "type"` node for EVERY interface / type alias / class / enum / Zod schema / NestJS DTO / TypeORM entity referenced on the path, cross-link with `call_sites[].callee_id` that MUST resolve to a `nodes[].id` (no dangling links); on re-invoke for the same slug, LOAD the existing `.codewalk/<slug>/data.json`, preserve manual edits to docblock.purpose/risk/branches_not_taken when function_range is unchanged, replace the live fields (source/invoked_lines/call_sites/data_in/data_out/git_blame), set previous_generated_at, and compute `diff_vs_previous` so the viewer's amber callout shows added_nodes / removed_nodes / signature_drift / new_side_effects; the user must type "regenerate" or "fresh" to opt INTO a blind overwrite; never collapse a sub-path because "it's a service / repo / external client"; the viewer is the deliverable, not chat narration; branches not taken are listed BY NAME and never expanded; on ambiguity (env flags, feature gates, tenant guards, DI tokens, dynamic dispatch) the skill STOPS and asks rather than guessing; **the viewer defaults to light mode** (`?theme=dark` or the header toggle switches to dark); `.codewalk/` is added to `.gitignore`. Self-contained — never calls other skills.
---

# codewalk — interactive call-stack viewer for code you didn't write

> ## ⚑ Locked Contract — read this BEFORE anything else
>
> 1. **Deep-by-default.** Walk every entry to its leaves (external SDK call, raw SQL emitted to driver, fs syscall, queue enqueue, pure mapper with no further outgoing calls). A 1-node trace for a non-trivial endpoint is a **bug**, not a feature. Reject and redo.
> 2. **Types are nodes.** Every `interface` / `type` alias / `class` / `enum` / Zod schema / NestJS DTO / TypeORM entity referenced on the path → its own node with `layer: "type"`. Function nodes hyperlink to type nodes via `call_sites` whose `callee_id` resolves to the type's node id. If the type is named in `data_in`/`data_out`/a parameter signature, the type node MUST exist.
> 3. **No dangling links.** Every `call_sites[i].callee_id` MUST appear in `nodes[].id`. The viewer logs a warning and renders the cw-call as plain text on dangling refs — the user sees a dead name they can't click. Either include the node or drop the call_site.
> 4. **Update existing, never blind-overwrite.** Before writing `data.json`, check if it already exists. If yes, load it, run the fresh trace, preserve manual edits to `docblock.purpose`/`risk`/`branches_not_taken` where `function_range` is unchanged, replace the live fields, set `previous_generated_at`, and populate `diff_vs_previous` (added/removed nodes, signature drift, new side effects). Only "regenerate" or "fresh" from the user opts INTO a blind overwrite. See Phase 4 Step 4.0.
> 5. **Light mode is default.** The viewer boots in light mode (since v0.3.2). `?theme=dark` URL param or the header ☾ toggle switches to dark; `localStorage["codewalk-theme"]` persists the choice. Do not override the default in chat narration.
> 6. **Stop on ambiguity. Never guess.** Multiple matching definitions, runtime-conditional registration, tenant guards, DI-token resolution, dynamic dispatch — STOP and ask which path the user wants. See `references/trace-rubric.md` §1.
>
> ### Acceptance — your trace is REJECTED if any of these are true
>
> - `nodes.length === 1` for an endpoint with ≥1 outgoing call.
> - Any `call_sites[*].callee_id` does not appear in `nodes[].id`.
> - A type named in any `data_in` / `data_out` / docblock.inputs.shape / docblock.outputs has no `layer: "type"` node.
> - The trace stops at the controller, the service, or any other "convenient" layer instead of recursing to a true leaf.
> - `source` line count for any node ≠ `function_range[1] - function_range[0] + 1`.
> - `order` is not strictly increasing across `nodes[]`.
>
> Re-run the trace if any of the above hits. Half-done is worse than not done.

The deliverable is a browser viewer the user opens to make decisions. Posture is senior peer walking the code with the user, not a tutor reciting it back. Every annotation the trace produces — purpose, side effects, risk, branches not taken, data shape — exists to let the user pick what to change and what to leave alone.

This skill is self-contained. It never calls other skills. Two reference files carry the heavy detail and are read on-demand:

- [`references/data-schema.md`](./references/data-schema.md) — the exact JSON contract the viewer consumes.
- [`references/trace-rubric.md`](./references/trace-rubric.md) — how to walk the stack with rigor (invoked-block detection, side-effect classification, picking the one risk, deferred-branch enumeration, depth check).

Read both before Phase 3 on first invocation in a session.

## Depth & Completeness Mandate (read once per session — non-negotiable)

**A codewalk is deep-by-default.** When the user asks for a trace, they are paying for the full call stack. The viewer's value collapses if the trace stops at the controller boundary and gestures at "calls `service.foo`" without recursing into `foo` and its own callees.

| Rule | Meaning |
|---|---|
| **Walk to leaves.** | A leaf is (a) an external API client method (`fetch`/`axios`/SDK call), (b) a raw SQL string emitted to a driver, (c) a filesystem syscall, (d) a queue enqueue/dequeue, (e) a pure mapper with no further outgoing calls. Stop ONLY at one of these. Stopping at "the next service method" because it's "below the surface" is the failure mode this mandate exists to ban. |
| **Cover every reachable callee on the path.** | If line 47 of the controller calls `this.search.search(...)` and line 51 of `SearchService.search` calls `this.resolveAnchor(...)`, BOTH are on the path. Recurse into both. The fact that one is in the same class does not exempt it. |
| **Type-defs are nodes too.** | Every `interface`, `type`, `class`, `enum`, Zod schema, NestJS DTO, TypeORM entity, and similar shape referenced by a `data_in` / `data_out` / parameter signature on the path becomes a separate node with `layer: "type"`. Function nodes hyperlink into them via `call_sites` whose `callee_id` resolves to the type node. The viewer renders type bodies in the same way as function bodies (greyed `invoked_lines: []` is fine — the type isn't "executed", it's referenced). |
| **No surface-only summaries.** | A trace whose `nodes.length === 1` for a non-trivial endpoint is a bug, not a feature. If the trace agent produces only the controller method, redo it. |
| **No size cap.** | If the trace ends up with 40 nodes for a complex hot-path query, that is the correct trace. Do not arbitrarily truncate. The viewer is paginated by the file-tree + breadcrumb — it handles depth fine. |
| **Hyperlinks must resolve.** | Every `call_sites[i].callee_id` MUST appear in `nodes[].id`. If you mention a callee but don't include its node, you've left the user staring at a dead link. Either include the node or omit the `call_site`. |

The 5-function depth-check pause from `references/trace-rubric.md` §8 is for **interactive single-entry mode only**. In playbook mode, batch mode, or any invocation that includes the phrase "all", "every", "deep", "end to end", "full", or "complete", the depth check is **disabled** — the agent runs to leaves without pausing. The user has already pre-approved depth by asking for completeness.

### What a complete trace looks like (size reference)

| Endpoint complexity | Expected `nodes.length` (rough) |
|---|---|
| `GET /health` returning `{ ok: true }` | 1–3 (controller + maybe one service ping) |
| `GET /api/users/:id` standard CRUD read | 5–10 (controller, service, repo, entity type, DTO type) |
| `GET /api/search` blended pgvector + tsvector + PostGIS hot-path | 20–40 (controller, validation schema, service, three resolvers, repo, raw SQL leaf, scoring helpers, embedding/external clients, entity types, DTO types) |
| `POST /api/admin/bootstrap-taxonomy` long-running pipeline | 30+ (controller, service, repo writes, Inngest event emissions, LLM call site, prompt + Zod schema types) |

If the actual `nodes.length` is far below these ranges for a similar endpoint, the trace is shallow — fix before shipping.

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

### Phase 3 — Walk depth-first to leaves. Include every type referenced on the path.

For every function on the path, extract every field listed in `references/data-schema.md` "Nodes". The order is fixed:

1. `file` + `function_range` + `name`
2. `source` (raw, no normalization, no stripping)
3. Identify `invoked_range` + `invoked_lines` (§3 of the rubric — this is the hardest field to get right)
4. `call_sites` for outgoing calls ON THE PATH only — INCLUDING `call_sites` whose target is a type/interface/DTO/Zod schema referenced in the signature or body
5. `docblock` (5 keys: purpose, inputs, outputs, side_effects, ownership)
6. `data_in` + `data_out` (typed pseudocode, not prose) — name the actual types; do not paraphrase
7. `risk` — exactly ONE concrete risk, smell, or load-bearing assumption
8. `branches_not_taken` — listed BY NAME with a one-line trigger condition, never expanded
9. `git_blame` — `git log -1 --pretty=format:'%an|%ad|%s' --date=short -- <file>`
10. `layer` — one of `controller`, `service`, `repository`, `external`, `other`, **`type`** (for interface/type-alias/class/Zod-schema/enum nodes)

**Recurse into every non-leaf callee.** A leaf is defined in the Mandate above. Anything else — same class, same module, different file, decorator-attached middleware that runs on this path — gets its own node and its own depth-first walk.

**Emit type nodes for every named shape on the path.** When `data_in: "SearchQuery"` references a Zod schema, that schema becomes a node (`layer: "type"`, `source` = the `z.object({ ... })` declaration verbatim, `invoked_lines: []`, `call_sites: []`, `branches_not_taken: []`, `risk: "none observed on this path"` is acceptable). The function node's `call_sites` includes an entry whose `callee_id` targets this type node, so the viewer renders the type name as a clickable hyperlink in the source pane. Apply this to: Zod schemas, NestJS DTOs, TypeORM entities, plain `interface` / `type` declarations, `enum` declarations, response envelopes, and class declarations whose constructor is invoked on the path.

**Depth check is OFF when the user pre-approved depth.** In interactive single-entry mode, the 5-function depth check from `references/trace-rubric.md` §8 still fires. In playbook mode, batch mode, or any invocation that includes "all", "every", "deep", "end to end", "full", or "complete", the agent walks to leaves without pausing.

If the user picks `stop` mid-walk (single-entry, depth-check active), the trace finalizes at the current state. The viewer renders whatever was collected.

### Phase 4 — Emit `data.json`. **Update-by-default, never blind-overwrite.**

**Step 4.0 (mandatory) — Check for an existing trace at `.codewalk/<slug>/data.json`.**

```bash
test -f .codewalk/<slug>/data.json && echo EXISTS || echo NEW
```

If `EXISTS`: load the file into memory as `previous_data`. The new trace is an **update**, not a replacement. Default mode is *merge-and-diff*; full overwrite requires the user to type "regenerate" or "fresh" explicitly. Without that signal:

1. Take the fresh node/edge graph you built in Phase 3.
2. For every node whose `id` (file:symbol) also appears in `previous_data.nodes[]` AND whose `function_range` is unchanged: **preserve the previous node's manual edits** to `docblock.purpose`, `docblock.ownership`, `risk`, and `branches_not_taken[].name`. Replace `source`, `invoked_lines`, `call_sites`, `data_in`, `data_out`, and `git_blame` with the freshly-extracted values. If `function_range` moved (the function was edited), drop the manual edits — they're stale.
3. Set `previous_generated_at = previous_data.generated_at`.
4. Build `diff_vs_previous`:
   - `added_nodes` — node IDs present in new, absent in previous.
   - `removed_nodes` — node IDs present in previous, absent in new.
   - `signature_drift` — for each node present in both, compare `data_in`/`data_out` and `docblock.inputs`/`docblock.outputs`. Record `{node_id, before, after}` per drift.
   - `new_side_effects` — for each node present in both, compare `docblock.side_effects`. Record additions only (removals are noise).
5. The viewer renders an amber callout in the Diagrams tab when `diff_vs_previous` has any non-empty array — that callout is the **whole point** of update-mode. If you blind-overwrite, the user loses the diff and any manual edits they made to the previous trace.

If `NEW`: fresh trace, `previous_generated_at: null`, `diff_vs_previous: null`. Print one line to chat: `creating new trace at .codewalk/<slug>/data.json`.

If `EXISTS`: print `updating existing trace at .codewalk/<slug>/data.json (last run: <previous_generated_at>)` plus a one-line diff summary (e.g. `+3 nodes, -1 removed, 2 signature_drift, 1 new side-effect`).

**Step 4.1 — Build the full JSON.** Match `references/data-schema.md` exactly. Field names are strict. Validate before writing:

- `nodes[0]` is the entry node, `order: 0`, `depth: 0`.
- Every `edges[i].from` and `edges[i].to` resolves to a `nodes[*].id`.
- Every `nodes[*].call_sites[*].callee_id` resolves to a `nodes[*].id` — no dangling links.
- `invoked_lines` for each node is a subset of line numbers in `function_range`.
- For `layer: "type"` nodes, `invoked_lines: []` is the norm (types aren't executed, only referenced).
- `source` line count equals `function_range[1] - function_range[0] + 1`.
- `slug` matches `/^[a-z0-9-]{1,80}$/`.
- Layer names in `diagrams.sequence_mermaid` capitalize to `Controller`, `Service`, `Repository`, `External`, `Type`, `Other`.
- `layers` object includes a `type` key (array of type-node IDs).

Build the Mermaid sources for `sequence_mermaid` and `module_deps_mermaid` from the collected nodes. Lift every node's `branches_not_taken` into top-level `deferred_branches` with `parent_id` attached.

### Phase 5 — Materialize the viewer.

Create `.codewalk/<slug>/` at the repo root. Copy the four asset files from this skill's `assets/` directory into the trace folder, then write `data.json`:

```bash
mkdir -p .codewalk/<slug>
cp <skill-dir>/assets/viewer.html .codewalk/<slug>/index.html   # per-trace HTML — renamed on copy
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

### Re-run behavior — see Phase 4 Step 4.0

The default for `/codewalk <same-entry-point>` is **update**, not regenerate. Phase 4 Step 4.0 above documents the merge-and-diff contract. Only when the user explicitly types "regenerate" or "fresh" does the trace overwrite without preserving manual edits or computing `diff_vs_previous`.

## Playbook mode — multi-entry codewalks (since v0.3.1)

**Single-entry mode is the default.** Switch to playbook mode only when the user wants a top-level index of *every* entry point in a service, each trace openable individually. Trigger phrases: "all endpoints", "every endpoint", "index playbook", "browse all routes", "playbook of <thing>".

In playbook mode the deliverable is the same per-slug viewer, *plus* a top-level `.codewalk/index.html` that lists every traced entry, grouped by domain, with a live filter and method-color chips. Each row links into its sibling slug folder's viewer in a new tab.

### Workflow shape (playbook mode)

```
Phase 1' (survey + classify entries) → Phase 2' (light mode check) →
Phase 3' (author _catalog.json) → Phase 4' (optional: gather _traces.json) →
Phase 5' (copy assets + run build-playbook.mjs) → Phase 6' (launch) →
Phase 7' (chat handoff)
```

**Phase 1' — survey the service.** Enumerate every endpoint / handler / job worth tracing. For an HTTP API this usually means every `@Controller`-decorated method, every CLI command, and every queue-job registration. Group entries into 4-10 domains (Search, Ingest, Admin, Health, etc.).

**Phase 2' — light or dark.** Ask the user once: dark (default, matches single-entry mode) or light (recommended for mixed audience / projector demos). The viewer ships both and honors `?theme=light` URL param + a `localStorage` preference. Pass through to the builder via the catalog title or in chat — the build itself doesn't take a flag; the viewer toggles at runtime.

**Phase 3' — author `_catalog.json`** at `.codewalk/_catalog.json`. Schema is in `references/data-schema.md` § "Playbook mode". Required fields per entry: `slug`, `method`, `route`, `domain`, `summary`, `controller` (or `entry`). The `slug` derives by the same rules as single-entry mode.

**Phase 4' — optional `_traces.json`** at `.codewalk/_traces.json`. When present, each entry's rich nodes/edges populate that slug's `data.json` directly. When absent, the builder writes a stub per slug — the user can deepen any specific slug later with `/codewalk <entry>`.

**Phase 5' — materialize.** Copy `assets/build-playbook.mjs` to `.codewalk/_build.mjs`, then run it:

```bash
cp <skill-dir>/assets/build-playbook.mjs .codewalk/_build.mjs
node .codewalk/_build.mjs --out .codewalk
```

The builder copies `playbook.html` (renamed to `index.html`), `playbook.js`, `playbook.css`, `serve.js` to `.codewalk/`. For each catalog entry, it creates `.codewalk/<slug>/` and copies the per-trace viewer assets + writes `data.json` (rich if `_traces.json` had it, stub otherwise).

**Phase 6' — launch.** Same `node .codewalk/serve.js` as single-entry mode — the server serves the playbook at `/` and every slug folder at `/<slug>/`.

**Phase 7' — chat handoff.** Print: total entries, how many got rich traces vs stubs, the playbook URL, and instructions to deepen any individual slug with `/codewalk <entry>`. Skip the 5 comprehension questions (they're per-trace, not per-playbook). Skip the decisions checklist.

### When to use playbook mode

| Signal | Mode |
|---|---|
| "Walk me through `POST /signup`" | single-entry |
| "How does the migration runner work?" | single-entry |
| "Trace every endpoint in this API" | playbook |
| "I want an index of all our background jobs, each clickable" | playbook |
| "Build a navigable map of all routes" | playbook |
| One specific bug to debug | single-entry |
| Onboarding doc for the entire service | playbook |

When in doubt, ask. Playbook mode is heavier — it touches every entry, not one.

## Anti-rationalizations

| Tempting shortcut | Why it breaks the deliverable |
|---|---|
| "I'll just overwrite the existing data.json — it's faster than diffing." | Wrong. The user's manual edits to docblock.purpose / risk / branches_not_taken get silently destroyed; the amber diff callout that surfaces "what changed since the last trace" disappears. Re-run is the most common invocation pattern for codewalk. Update-by-default is non-negotiable — see Phase 4 Step 4.0. |
| "The user can re-run if they want a diff." | They DID re-run. That's the invocation that triggered this trace. `diff_vs_previous` exists precisely so the second-and-later run shows what moved. Skipping it ships a worse viewer for no token savings. |
| "Stopping at the controller is fine — the user knows what services do." | No they don't. Stopping at the controller means the trace shows a method call and a `// → calls service.foo` comment. The user wants to follow `foo` into the repository, into the SQL, into the type that the row maps onto. The Mandate above bans this. Recurse. |
| "Tracing into the type definitions would bloat the trace." | The type definition IS the contract. Without it, `data_in: "SearchQuery"` is a name with no schema. Type nodes are cheap (no `invoked_lines`, no recursion); they cost the user nothing and pay them the actual shape. Include them. |
| "I'll list `service.foo(...)` as a call_site but skip the node — they can grep." | Then the cw-call link is dead. The viewer logs a console warning and the user clicks a name that goes nowhere. Either include the node or drop the call_site. No half-links. |
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
│   ├── viewer.html                ← per-trace viewer shell, copied to <slug>/index.html (Tailwind + Alpine + Prism + Mermaid + marked, all CDN)
│   ├── viewer.js                  ← Alpine component (load/render/navigate/diagrams/theme)
│   ├── viewer.css                 ← Prism overrides + invoked-line highlight + light-mode block
│   ├── serve.js                   ← Node stdlib HTTP server (port pick + browser open)
│   ├── playbook.html              ← multi-entry index page (since v0.3.1, light-mode-first)
│   ├── playbook.js                ← Alpine component for the index (catalog filter + theme)
│   ├── playbook.css               ← light/dark base styles for the playbook
│   └── build-playbook.mjs         ← catalog-driven multi-entry builder (since v0.3.1)
└── references/
    ├── data-schema.md             ← the exact JSON contract the viewer + catalog consume
    └── trace-rubric.md            ← how to walk the stack (invoked block / side effects / risk / branches / depth check)
```

The per-trace viewer (single-entry mode) lives at `.codewalk/<slug>/` in the target repo:

```
<repo-root>/.codewalk/<slug>/
├── index.html         ← copied from skills/codewalk/assets/viewer.html (renamed)
├── viewer.js          ← copied
├── viewer.css         ← copied
├── serve.js           ← copied
└── data.json          ← generated this run (the only file that varies per trace)
```

In playbook mode the same `.codewalk/<slug>/` folders exist for every catalog entry, plus a top-level index:

```
<repo-root>/.codewalk/
├── index.html         ← playbook (copied from skills/codewalk/assets/playbook.html)
├── playbook.js        ← copied
├── playbook.css       ← copied
├── serve.js           ← copied
├── _build.mjs         ← copied from build-playbook.mjs (re-runnable)
├── _catalog.json      ← authored by the skill in Phase 3'
├── _traces.json       ← optional; authored by the skill in Phase 4'
└── <slug>/            ← one per catalog entry (same layout as single-entry mode)
    └── …
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

`/codewalk <entry-point>` → **deep depth-first walk to leaves** (controller → service → repo → external + every type/interface/DTO/Zod schema as a `layer: "type"` node) → stop-and-ask only on ambiguity → `.codewalk/<slug>/{index.html, viewer.js, viewer.css, serve.js, data.json}` → `node serve.js` → browser viewer (light or dark, toggle in header) with every `call_sites` hyperlink resolving to a real node + 5 comprehension questions + decisions checklist. **Playbook mode** (since v0.3.1): when the user asks for "all endpoints" / "index playbook", author `_catalog.json` + optional `_traces.json`, run `build-playbook.mjs`, and ship a top-level light-mode index with every entry linkable into its own viewer — every per-slug trace inherits the same deep-by-default contract.
