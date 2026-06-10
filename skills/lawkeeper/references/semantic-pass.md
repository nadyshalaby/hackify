# Semantic pass — subagent prompts for the judgment rules

Phase 3 fans out one subagent per concern (dispatch them in a single message so they run
concurrently). Each reads the code, applies a rule the scanner cannot match precisely, and
returns findings in the SHARED OUTPUT shape below so Phase 4 can merge them with the scanner's
JSON. Scope every subagent to the same root (or the user's chosen subtree). Hand each one the
relevant carve-out floors from `carve-outs.md` — a subagent that flags an exempt construct is
producing noise.

Prefer the project's own linter for the structure caps: if ESLint/Biome is configured, run it
with `max-lines-per-function` / `max-params` / `max-depth` and trust that over an estimate.
Only fall back to the `caps` subagent when no linter cap is available.

## Reuse the project's installed agents first (DRY)

If the project has review agents installed under `.claude/agents/`, USE
them instead of re-deriving their concern — they already encode the project's exact rules:
- `security-auditor` → the **security** concern (dispatch the agent; skip the built-in prompt).
- `performance-auditor` → the **performance** concern.
- `cleanup-scout` → the **cleanup** concern (dead code, unused deps/files, dead flags, debt).
- `code-reviewer` → the **DRY / SOLID / layering / naming** concerns.

Those agents are diff-scoped by default (`git diff`); for a full-codebase audit, dispatch them
per top-level module or per changed-set so each stays within a sane context. Fall back to the
built-in concern prompts below ONLY when the matching agent is absent. Either way, normalize
their output into the SHARED OUTPUT shape so Phase 4 merges everything uniformly.

## Shared OUTPUT contract (every subagent returns this)

Return ONLY a JSON object — no prose:

```json
{
  "findings": [
    {
      "rule_id": "style.dry",
      "category": "code-style",
      "severity": "high",
      "confidence": "judgment",
      "file": "src/users/users.service.ts",
      "line": 42,
      "end_line": 58,
      "message": "Pagination math duplicated from listProducts (products.service.ts:30); reuse paginate().",
      "evidence": "the duplicated snippet + the existing helper it should use"
    }
  ]
}
```

Rules: cite `file:line` for every finding; quote the offending code and (for DRY/layering) the
existing thing it should use; assign severity from `rule-catalog.md`; emit nothing you cannot
point at. Prefer false negatives over false positives — a noisy auditor gets ignored.

## Concern prompts

Give each subagent its concern block plus: the resolved rule set summary (Phase 1), the
relevant carve-out floors, and the OUTPUT contract.

### caps (only if no linter cap available)
> Find functions/methods over the caps: body > {FN_LINES} lines, > {FN_PARAMS} parameters, or
> > {FN_NESTING} levels of control-flow nesting. Count a destructured/object param as one.
> Ignore object-literal braces — only control-flow blocks (if/for/while/switch/try) count as
> nesting. rule_id `cap.fn-lines` / `cap.fn-params` / `cap.fn-nesting`.

### dry
> Find duplicated logic — the same 3+ lines of behavior in two places, or new code that
> reimplements an existing helper/service/util. For each, name the existing canonical home it
> should use. Search before asserting: a thing is only a DRY violation if the reusable target
> actually exists. rule_id `style.dry`.

### layering
> Find clean-architecture layer leaks against the documented tiers: presentation
> (controllers/guards/middleware/routes) holding business logic or reaching data access;
> services importing the HTTP framework or reading request/response objects; features reaching
> into another feature's internals; infrastructure making business decisions. rule_id
> `scope.layer`. Also flag controllers that do more than one service call or any
> conditional/response-shaping/try-catch/transformation as `scope.controller-purity`.

### naming-explicitness
> Find code that needs a comment to be understood, names that describe what-a-thing-IS rather
> than what-it-DOES, nested or chained ternaries, and nesting that should be guard clauses.
> rule_id `style.naming` (or `style.ternary` for ternary chains). Low severity; do not nitpick
> well-named code.

### single-responsibility
> Find units that do more than one thing — a function/service/command whose description needs
> "and", or a command that silently runs its own prerequisite instead of validating it. rule_id
> `style.srp`.

### dead-code
> Find methods, exported symbols, and module/provider registrations with zero callers across
> the codebase. Confirm zero references before flagging (grep the symbol). rule_id
> `scope.dead-code`. Also flag re-exports from a non-canonical source as `scope.re-export`.

### folder-structure (only if a topology is documented)
> Given the documented topology {TOPOLOGY}, find files placed in the wrong tier/directory,
> types/enums/constants not in their dedicated home, and duplicate entity/model class names.
> rule_id `folder.placement` / `folder.type-home` / `folder.entity-uniqueness`. If no topology
> is documented, return an empty findings list — do not invent a structure.

### magic-literals
> Find un-named magic strings/numbers that should be a named constant in the module's
> constants file. HONOR THE FLOORS: leave inline all identity values (0,1,-1,'',true,false),
> Tailwind/CSS classes, Zod-builder args, object keys, SQL fragments, template literals with
> `${…}`, import specifiers, regex, union-type members, Drizzle defaults. `**/schema.ts` and
> `**/migrations/**` are entirely off-limits. On a frontend, TanStack typed paths stay inline.
> rule_id `style.magic-literal`. Low severity.

### security (fallback when no `security-auditor`)
> Find: string-concatenated/interpolated SQL or shelled-out commands built from input
> (`sec.injection`); any state-changing operation — a write/update/**delete** at the route,
> handler, OR service/domain layer — reachable with no authorization, permission, or
> resource-ownership check on the path to it (`sec.authz`). A destructive data op
> (`DELETE`, `db.delete(...)`, a service method that removes/overwrites a record) with no
> visible guard is the canonical case — do NOT assume an upstream caller checks; flag it and
> name where the guard belongs. Also: external input reaching logic without validation at the
> boundary (`sec.input-validation`);
> deserialization of untrusted data or SSRF on outbound requests (`sec.unsafe-op`); migrations
> that are not idempotent / not guarded by existence checks (`sec.migration`); PII or secrets
> written to logs (`sec.pii-log`). Cite the standard (OWASP/CWE) where one applies. Critical for
> exploitable risk, Important for weakened posture. Hardcoded secrets are already covered by the
> deterministic scanner — do not re-report them.

### performance (fallback when no `performance-auditor`)
> Find: a query inside a loop over rows / missing index (`perf.n-plus-1`); nested iteration that
> turns O(n) into O(n²) or repeated work that should be hoisted (`perf.algorithmic`); blocking or
> synchronous I/O on a request/render path (`perf.blocking-io`); unbounded caches/accumulators or
> whole-file buffers held in memory (`perf.memory`); frontend re-render thrash from unstable
> references or missing memoization (`perf.render`). Severity scales with data/traffic: Critical
> when cost grows with user data, Minor for cold-path constant factors. Flag a real cost with a
> trigger condition; do not speculate about micro-optimizations.

### testing (fallback when no test-coverage tooling)
> Find: public service methods, guards, and significant branching logic with NO co-located or
> referenced test (`test.untested`); behavior with happy-path-only tests missing the edge cases
> the principles demand — null/undefined, empty, concurrent, partial failure (`test.edge-cases`).
> Confirm absence by searching for a test that exercises the symbol before flagging. Medium
> severity. Do not demand tests for trivial getters or framework glue.

### solid (fallback when no `code-reviewer`)
> Beyond SRP (covered separately), find: stable code edited with a new conditional where an
> extension point exists (`solid.ocp`); a subtype narrowing inputs or surprising callers who hold
> the base type (`solid.lsp`); a consumer forced to depend on a fat interface whose methods it
> never calls (`solid.isp`); a unit depending on a concretion where the project injects an
> abstraction (`solid.dip`); speculative abstraction, unused config knobs, or
> fallback-for-hypothetical-future code — YAGNI (`solid.yagni`). These are judgment calls: flag
> only a concrete instance you can point at, not a stylistic preference. Medium severity.

### cleanup-extras (fallback when no `cleanup-scout`)
> Cross-file cleanup the single-file scanner cannot see: dependencies declared in the manifest but
> imported nowhere (`clean.unused-dep`); modules/files imported by nothing (`clean.unref-file`);
> feature flags defined but never read (`clean.dead-flag`); env vars validated in the schema but
> never used, or used but never validated (`clean.orphan-env`); blocks of commented-out CODE — not
> prose — that belong in git history (`clean.commented-code`). Use the project's depcheck/knip-style
> tool when present. Confirm zero references before flagging. Low–medium severity.
