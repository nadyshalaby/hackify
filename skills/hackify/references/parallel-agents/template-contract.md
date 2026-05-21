# Parallel Agents — Template Contract

User preference (default): **always spawn foreground parallel agents to speed development, code reviews, spec self-reviews, and verification.** When 2+ pieces of work are independent, dispatch them in parallel in **one message** so they run concurrently.

This file is the canonical 7-section contract every per-task template in this directory conforms to. Load it alongside any per-phase template file (`phase-2.5-spec-review-*.md`, `phase-3-implementation.md`, `phase-3b-debug-evidence.md`, `phase-5-multi-review.md`) to verify the dispatched prompt carries every required anchor.

---

## When to fan out (yes)

- **Phase 1 research** — different parts of the codebase, different reference docs, different open questions. One agent per question.
- **Phase 2.5 spec self-review** — three reviewers in parallel scrutinize the work-doc for inconsistent / conflicting logic before code is written (consistency / architectural risk / dependency-and-parallelism). MANDATORY before Phase 3.
- **Phase 3 implementation waves** — group tasks by dependency, dispatch each wave's tasks to one agent each in a single message. **Tasks in the same wave MUST NOT share files.** This is what makes parallel implementation safe.
- **Phase 4 verification across packages** — backend + frontend + shared package; one agent per package runs `test && lint && typecheck` in parallel.
- **Phase 5 multi-reviewer** — three foreground reviewers in parallel: security/correctness, quality/layering, plan-consistency/scope. MANDATORY for any non-trivial diff.
- **Phase 3b debug evidence** — multi-component bug; one agent per boundary instruments + logs.
- **Multi-project work** — task touches multiple sibling projects (e.g. a backend repo AND a frontend repo); one agent per repo runs the same investigation or implementation wave in its own scope.

## When NOT to fan out

- **Tasks that share a file** — concurrent edits cause conflicts. The wave planner MUST split same-file tasks across waves.
- **Tightly-coupled investigations** — when finding A informs question B, run sequentially.
- **Tasks that need shared state** — they'll race.
- **One-line typo / config-only diffs** — multi-reviewer is overkill. Self-review is enough.
- **When a single agent is sufficient** — don't fan out for theatre. Two parallel agents have overhead.

---

## Dispatch pattern (one message, multiple Agent tool calls)

When firing N agents in parallel, put N `Agent` tool calls in **one assistant message**. Don't fire one, wait, fire another.

Foreground (default): the parent (hackify) waits for all N to complete before continuing. **This is what we want** — not background.

Use **`run_in_background: false`** explicitly if you want to be sure. Foreground is also the default.

---

## Template Contract

### Purpose

Every per-task template in this directory conforms to a single canonical 7-section structure. This contract exists so a dispatching agent can author a sub-agent prompt without inventing structure on the fly, so a sub-agent (even a Haiku-class model) sees the same shape every time, and so structural validators can grep for required headings. If a template in a sibling file does not match the contract, the template is wrong — not the contract.

### The 7 sections (mandatory + conditional)

Sections 1, 2, 3, 4, 5, and 7 are MANDATORY in every template. Section 6 (SEVERITY) is CONDITIONAL — present in review/audit templates only, omitted entirely from build/research templates (not present as an empty section).

**1. ROLE (mandatory, every template)**

Five elements, all mandatory:

(a) Identity + seniority — "You are a senior `<discipline>` engineer with 15+ years of experience in `<domain>`."

(b) Domain expertise — specific systems / patterns / stacks the role has lived in. 2-4 concrete items.

(c) Standards the role follows — cite by name, version-pinned where applicable. Allowed tokens are listed in the Framework citation allowlist below. Cite 1-3 that genuinely apply. Citations outside the allowlist must be added to the allowlist with a justification comment.

(d) Rejected anti-patterns — "You reject `<X>`, `<Y>`, `<Z>`." Three to five concrete things this role refuses to ship.

(e) Behavioral bias — "Bias to: `<verb>`. Bias against: `<verb>`." Two lines, concrete actions. No "you are paid to ..." stylistic line.

**2. INPUTS (mandatory)**

Numbered list. Each input names a `{{placeholder}}` and the type (e.g. "`{{work_doc_path}}` — absolute filesystem path"). Placeholders are instructions to the DISPATCHING AGENT (the parent), NOT the sub-agent. The dispatching agent MUST replace every `{{placeholder}}` with a concrete value before sending the prompt. A sub-agent receiving literal `{{...}}` text is a dispatch bug — the sub-agent should refuse and report "unfilled placeholder: `<name>`".

**3. OBJECTIVE (mandatory)**

One sentence. Exactly one noun phrase deliverable. If the template produces more than one deliverable, split into multiple templates.

**4. METHOD (mandatory)**

Numbered steps, minimum three. Each step is one concrete action with a verifiable outcome ("read X then grep for Y" — not "investigate Z"). For templates that touch user-facing prose across multiple files, METHOD MUST contain a step naming the canonical sentence (or canonical fact) the agent will replicate verbatim, with the source file path. Generic "be consistent with related files" is forbidden.

**5. VERIFICATION (mandatory — two shapes; pick the one that fits)**

See "VERIFICATION shapes" below for the picker.

**6. SEVERITY (review/audit templates ONLY — omit on non-review templates)**

Anchored examples per level. Minimum 2 examples per level. Critical example anchors should reference real failure modes (e.g. "schema field cannot be verified against live docs" = Critical, not Important). Mandatory line, verbatim:

> If you cannot verify a claim against live docs or live code, mark the finding Critical, not Important.

**7. OUTPUT (mandatory)**

Word cap shape depends on template type:

- Review/audit/research templates: single global word cap with reasoning ("≤300 words — terse review beats long review").
- Implementation/build templates: per-section sub-budget ("Files touched: 1 line each; RED→GREEN: 1 line per test; Deviations: ≤80 words; Self-review: compact ✓/✗ table").

Exact report format with named sections. What to omit if nothing relevant (still report explicitly: "No findings." — never go silent).

#### ROLE worked example (Phase 5 security reviewer)

```
You are a senior application security engineer with 15+ years of experience
auditing server-side and typed-language backends, OAuth/OIDC implementations,
multi-tenant data isolation, and CI/CD supply chains.

Your domain expertise covers: HTTP request lifecycles across router /
service / middleware module layers, schema-driven migration tooling,
session-token and cookie issuance, key-value session stores, relational
row-level security, and CI runner secrets handling.

You apply OWASP Top 10 (2021), SANS CWE-25, NIST SP 800-63B, and the
relevant clauses of RFC 6749 and RFC 7519.

You reject: silent error fallbacks, broad CORS allowlists, secrets in
source, unparameterized SQL, session tokens stored in browser-accessible
storage, missing rate limits on auth endpoints.

Bias to: flagging.
Bias against: deferring to author intent on "it works in practice".
```

### Framework citation allowlist

Cite frameworks and standards by name, version-pinned where applicable. The allowed tokens are:

- OWASP Top 10 (2021)
- SANS CWE-25
- NIST SP 800-63B
- RFC 6749
- RFC 7519
- RFC 9110
- WCAG 2.2 AA
- ARIA 1.2
- Clean Code (Martin)
- SOLID
- 12-Factor App
- Conventional Commits 1.0.0
- Semantic Versioning 2.0.0
- Keep a Changelog 1.1.0
- RFC 2119 keywords
- ISO 8601
- Postel's law
- expand-then-contract migrations

Cite 1-3 that genuinely apply to the role. Citations outside this list MUST be added to the allowlist with a justification comment — the structural validator greps against this allowlist.

### Placeholder convention

All runtime values use `{{snake_case}}` placeholders inside the template body. Placeholders are documentation to the DISPATCHING AGENT (the parent), not to the sub-agent. There is no runtime interpolation engine — substitution happens when the parent writes the actual sub-agent call. Sub-agents always receive concrete values, never literal `{{...}}` text.

If a sub-agent encounters literal `{{...}}` text in its prompt, that is a dispatch bug. The sub-agent MUST refuse to proceed and MUST report `unfilled placeholder: <name>` so the parent can fix the dispatch.

Zero literal absolute paths (`/Users/`, `/home/`, `/tmp/`) appear inside template bodies — paths resolve from placeholders at dispatch time.

### VERIFICATION shapes

Pick exactly one of two shapes per template:

**Shape A — Executable.** For templates that touch the filesystem or produce an auditable artifact (Implementation, Cross-package verification, structural rewrites): inline bash script that exits 0 on success, non-zero on failure. The agent runs it before reporting "done"; if non-zero, the agent loops back to METHOD.

**Shape B — Self-checklist.** For prose-producing templates that have no filesystem artifact (Research, Spec-review, Multi-reviewer, Code-review escalation, Debug evidence — Phase 3b is read-only investigation, no filesystem artifact): a numbered yes/no list the agent MUST paste into its report under a "Verification" heading. If any answer is NO, the agent loops back to METHOD, not OUTPUT. Every checklist item is a single question with a yes/no answer — no "evaluate the X."

---

## Per-task templates

These templates use **relative reference paths** like `references/review-and-verify.md`. The plugin's skill layout puts every reference file in `<plugin>/skills/hackify/references/`, so relative refs travel cleanly across machines. For project-specific rule files (a workspace or project `CLAUDE.md`), pass the **absolute path** dynamically — let hackify substitute the actual path at dispatch time.
