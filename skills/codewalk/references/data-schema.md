# data.json — the trace-to-viewer contract

`data.json` is the only file that varies between traces. Everything else in `.codewalk/<slug>/` is a static viewer asset copied from `skills/codewalk/assets/`. If `data.json` is well-formed, the viewer renders. If a field is missing, the viewer degrades gracefully (empty section, neutral state) but never throws.

The schema below is normative. Field names are exact. The order of array elements matters in two places, called out inline.

## Top-level shape

```json
{
  "version": 1,
  "entry_point": "GET /api/users/:id",
  "slug": "get-api-users-id",
  "language": "typescript",
  "generated_at": "2026-05-22T09:14:00Z",
  "previous_generated_at": null,
  "repo_root": "/abs/path/to/repo",
  "nodes": [ ... ],
  "edges": [ ... ],
  "layers": { ... },
  "diagrams": { ... },
  "deferred_branches": [ ... ],
  "diff_vs_previous": null
}
```

| Field | Type | Required | Meaning |
|---|---|---|---|
| `version` | int | yes | Schema version. Currently `1`. |
| `entry_point` | string | yes | The exact entry point as the user named it. Free-form. Verbatim. |
| `slug` | string | yes | Filesystem-safe slug derived from `entry_point`. See "Slug convention" below. |
| `language` | string | yes | Primary language of the traced code. Lowercase. One of: `typescript`, `javascript`, `python`, `ruby`, `go`, `rust`, `java`, `kotlin`, `csharp`, `php`, `swift`, `other`. Drives Prism grammar selection. |
| `generated_at` | ISO 8601 string | yes | Timestamp when this trace was produced. |
| `previous_generated_at` | ISO 8601 string \| null | yes | Timestamp of the prior trace at the same slug, or `null` if this is the first run. |
| `repo_root` | string | yes | Absolute path of the repo the trace targets. Used by the viewer to render relative paths and `git blame` link targets. |
| `nodes` | array | yes | One entry per function on the path. Order is visit order (DFS). Length ≥ 1. |
| `edges` | array | yes | One entry per call edge taken on the path. Order is invocation order. |
| `layers` | object | yes | Bucketing of node IDs by architectural layer. Keys: `controller`, `service`, `repository`, `external`, `other`. Values are arrays of node IDs. Empty arrays allowed. |
| `diagrams` | object | yes | Pre-rendered Mermaid sources plus structured invariants and failure modes. Schema below. |
| `deferred_branches` | array | yes | Branches not taken at any node, lifted to top level so the viewer can show them on the Diagrams tab. Empty array if none. |
| `diff_vs_previous` | object \| null | yes | `null` on first run. On re-run, summarizes what changed. Schema below. |

## Nodes

Each node is one function on the traced path. The node ID is `<file>:<function_name>` — globally unique within `data.json`. If the same function appears twice on the path (recursion or repeated dispatch), append `#<order>` to disambiguate.

```json
{
  "id": "src/controllers/user.controller.ts:getUser",
  "name": "getUser",
  "file": "src/controllers/user.controller.ts",
  "depth": 0,
  "order": 0,
  "layer": "controller",
  "language": "typescript",
  "function_range": [42, 68],
  "invoked_range": [42, 65],
  "source": "<full function body, EXACTLY as it appears on disk between function_range[0] and function_range[1] inclusive, joined by '\\n'>",
  "invoked_lines": [42, 43, 44, 47, 48, 60, 61, 65],
  "call_sites": [
    {
      "line": 47,
      "fragment": "userService.findById(userId)",
      "callee_id": "src/services/user.service.ts:findById"
    }
  ],
  "docblock": {
    "purpose": "Resolve and return a single user by id.",
    "inputs": [
      { "name": "req.params.id", "shape": "string (uuid)" },
      { "name": "req.user", "shape": "AuthContext { id, tenantId }" }
    ],
    "outputs": "PublicUser",
    "side_effects": ["http", "db"],
    "ownership": "Controllers translate transport (HTTP) to domain calls. Auth + tenant scoping live in middleware above this layer."
  },
  "data_in": "{ id: string, requester: AuthContext }",
  "data_out": "PublicUser",
  "risk": "Returns `null` from service as 404, but `null` from a downstream DB error also looks like 404. Logging hides the case.",
  "branches_not_taken": [
    { "name": "soft-deleted user path", "trigger": "req.query.includeDeleted === 'true'" },
    { "name": "admin override path", "trigger": "req.user.role === 'admin'" }
  ],
  "git_blame": {
    "last_author": "Jane Doe",
    "last_date": "2025-12-03",
    "last_pr": "#1234"
  }
}
```

| Field | Type | Required | Meaning |
|---|---|---|---|
| `id` | string | yes | Globally unique. `<file>:<name>` or `<file>:<name>#<order>` for repeats. |
| `name` | string | yes | Function/method name as declared. |
| `file` | string | yes | Path RELATIVE to `repo_root`. Forward slashes on all platforms. |
| `depth` | int | yes | DFS depth from entry point. Entry node is `depth: 0`. |
| `order` | int | yes | Visit order across the whole trace. Entry node is `order: 0`. Strictly increasing across `nodes[]`. |
| `layer` | string | yes | One of `controller`, `service`, `repository`, `external`, `other`. Determines layer column on the Mermaid sequence diagram. |
| `language` | string | yes | Per-node language override. Same enum as top-level `language`. Lets a polyglot trace highlight each file correctly. |
| `function_range` | `[int, int]` | yes | `[start_line, end_line]` of the full function declaration, 1-indexed, inclusive. |
| `invoked_range` | `[int, int]` | yes | The narrowest contiguous line range that contains every line that fires on this path. May equal `function_range` if the whole body fires. |
| `source` | string | yes | The raw text of `function_range`, joined with `\n`. The viewer renders this directly; do NOT re-fetch from disk at view time. |
| `invoked_lines` | `int[]` | yes | Exact absolute line numbers (within `function_range`) that fire on this path. The viewer paints these green and dims every other line in `source`. |
| `call_sites` | array | yes | One entry per outgoing call ON THIS PATH. Used to render clickable anchors in the code viewer. Empty array if leaf. |
| `docblock` | object | yes | Five required keys: `purpose`, `inputs`, `outputs`, `side_effects`, `ownership`. Schema below. |
| `data_in` | string | yes | Human-readable payload shape entering this node. Free-form. Aim for a typed-pseudocode look. |
| `data_out` | string | yes | Human-readable payload shape leaving this node. `void` is acceptable. |
| `risk` | string | yes | ONE concrete risk, smell, or load-bearing assumption. Not a list. If genuinely none, write `"none observed on this path"`. |
| `branches_not_taken` | array | yes | Listed BY NAME with a one-line trigger condition. Never expanded into nodes. Empty array allowed. |
| `git_blame` | object \| null | yes | `last_author`, `last_date` (ISO date), `last_pr` (string or null). `null` if blame is unavailable (e.g., file is untracked). |

### call_sites

```json
{ "line": 47, "fragment": "userService.findById(userId)", "callee_id": "src/services/user.service.ts:findById" }
```

- `line` — absolute line number within the file where the call appears.
- `fragment` — short string snippet of the call expression. The viewer searches the source line for this substring to wrap it in an anchor. If the substring is not found, the viewer falls back to wrapping the whole line.
- `callee_id` — must match a `nodes[].id`. The viewer validates this and warns in the console if dangling.

### docblock

```json
{
  "purpose": "One sentence.",
  "inputs": [ { "name": "argName", "shape": "type pseudocode" } ],
  "outputs": "type pseudocode",
  "side_effects": ["db", "queue", "http", "cache", "auth", "fs"],
  "ownership": "One or two sentences explaining why THIS layer owns this responsibility."
}
```

`side_effects` is an array of zero or more of the fixed set: `db`, `queue`, `http`, `cache`, `auth`, `fs`. The viewer renders these as colored chips. Anything outside the set is silently dropped — keep classification consistent.

## Edges

```json
[
  { "from": "src/controllers/user.controller.ts:getUser", "to": "src/services/user.service.ts:findById", "call_site_line": 47, "order": 0 }
]
```

| Field | Type | Required | Meaning |
|---|---|---|---|
| `from` | string | yes | Caller node ID. |
| `to` | string | yes | Callee node ID. |
| `call_site_line` | int | yes | Absolute line in `from`'s file where the call happens. |
| `order` | int | yes | Edge order across the whole trace. Strictly increasing. Drives the Mermaid sequence diagram. |

## diagrams

```json
{
  "sequence_mermaid": "sequenceDiagram\n  participant Controller\n  participant Service\n  participant Repository\n  Controller->>Service: findById(userId)\n  Service->>Repository: query(...)\n  Repository-->>Service: row | null\n  Service-->>Controller: PublicUser | null",
  "module_deps_mermaid": "graph LR\n  controllers/user --> services/user\n  services/user --> repositories/user",
  "data_evolution": [
    { "node_id": "...", "shape": "{ id: string }" },
    { "node_id": "...", "shape": "UserRow | null" },
    { "node_id": "...", "shape": "PublicUser" }
  ],
  "invariants": [
    { "boundary": "Controller → Service", "must_hold": "AuthContext is present and tenant-scoped" },
    { "boundary": "Service → Repository", "must_hold": "Transaction is open OR caller is read-only" }
  ],
  "failure_modes": [
    { "node_id": "...", "modes": ["DB connection lost", "user-not-found"], "blast_radius": "Single request fails; no cascade" }
  ]
}
```

All five sub-fields are required. Empty array allowed for `data_evolution`, `invariants`, `failure_modes` when the trace is too shallow to warrant them. Empty string allowed for the two Mermaid sources but discouraged — the viewer will render an empty diagram placeholder.

Layer names in `sequence_mermaid` MUST be `Controller`, `Service`, `Repository`, `External`, or `Other` — matching `layers` keys, capitalized. This keeps the diagram architectural rather than class-named.

## deferred_branches

A flat list lifted from every node's `branches_not_taken`, with parent context attached. The Diagrams tab renders this so the viewer surfaces the road-not-traveled in one place.

```json
[
  { "parent_id": "src/controllers/user.controller.ts:getUser", "name": "soft-deleted user path", "trigger": "req.query.includeDeleted === 'true'" }
]
```

## diff_vs_previous

`null` on first trace at this slug. Otherwise:

```json
{
  "added_nodes": ["src/services/user.service.ts:invalidateCache"],
  "removed_nodes": [],
  "signature_drift": [
    { "node_id": "src/services/user.service.ts:findById", "before": "(id: string) => User | null", "after": "(id: string, tx?: Transaction) => User | null" }
  ],
  "new_side_effects": [
    { "node_id": "src/services/user.service.ts:findById", "added": ["cache"] }
  ]
}
```

All four keys are required. Empty arrays allowed. The Diagrams tab renders an amber callout when this object is non-null.

## Slug convention

The slug derives from `entry_point` by exactly these rules. Document the rule in chat after the first run so the user can override if they want:

| Entry-point shape | Slug rule | Example |
|---|---|---|
| HTTP route | `<method-lowercase>-<path-sanitized>` | `GET /api/users/:id` → `get-api-users-id` |
| CLI command | `cli-<command-sanitized>` | `migrate users:backfill` → `cli-migrate-users-backfill` |
| Queue job | `job-<queue>-<job-name>` | `email.send-welcome` → `job-email-send-welcome` |
| UI action | `ui-<component>-<action>` | `LoginButton onSubmit` → `ui-loginbutton-onsubmit` |
| Other | `<sanitized-name>` | free-form | `do-something` |

Sanitization: lowercase ASCII alphanumeric + dash. Collapse runs of dashes. Strip leading/trailing dashes. Truncate to 80 chars.

## What the viewer assumes

- `nodes[0]` is the entry. Always.
- `nodes` are sorted by `order` (== visit order). The left rail uses this directly.
- Every `call_sites[i].callee_id` resolves to some `nodes[j].id`, or the viewer logs a console warning and renders the call site as un-clickable.
- `invoked_lines` is a subset of the line numbers between `function_range[0]` and `function_range[1]` inclusive.
- `source` line count equals `function_range[1] - function_range[0] + 1`.

Violating any of these is not a crash, but is a visible bug in the rendered viewer. The trace agent is the only validator.
