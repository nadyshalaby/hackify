# Parallel Agents (Template Contract)

User preference (default): **always spawn foreground parallel agents to speed development, code reviews, spec self-reviews, and verification.** When 2+ pieces of work are independent, dispatch them in parallel in **one message** so they run concurrently.

This file is the canonical 8-section contract every per-task template in this directory conforms to. Load it alongside any per-phase template file (`investigation.md`, `phase-2.5-spec-reviewer.md`, `phase-3-implementation.md`, `phase-5-multi-review-a-security.md`, `phase-5-multi-review-b-quality-plan.md`) to verify the dispatched prompt carries every required anchor.

---

## When to fan out (yes)

- **Phase 1 research**, different parts of the codebase, different reference docs, different open questions. One agent per question.
- **Phase 2.5 spec self-review**, one reviewer, three lenses over one read of the work-doc, checking it for inconsistent / conflicting logic before code is written (internal consistency + execution-wave plan + architectural risk). MANDATORY before Phase 3.
- **Phase 3 implementation waves**, group tasks by dependency, then dispatch each wave to ONE agent that carries the whole wave. How many waves go out at once is decided by the three-condition partition test, and that rule is canonical in [`../contention-dispatch.md`](../contention-dispatch.md), named here rather than restated. This line used to state the one-agent rule without conditions while its own justification carried one, which is the shape a pointer exists to prevent. **Tasks in the same wave MUST NOT share files.** That is why waves are partitioned: every task keeps its own file allowlist, and the wave is bounded by their union, which never widens what one task may touch.
- **Phase 4 verification across packages**, backend + frontend + shared package; one agent per package runs `test && lint && typecheck` in parallel.
- **Phase 5 multi-reviewer**, one panel dispatched in parallel, capped at five, with A, B, D and F on every non-trivial diff and E on a UI-bearing one. Quality, layering, engineering law plus plan consistency and scope is one lens on one read; security/correctness, performance and cross-module coherence each run unconditionally beside it; design conformance is the one conditional lens and runs on UI-bearing diffs. MANDATORY for any non-trivial diff.
- **Phase 5 adversarial refuter**, ONE per phase, judging every finding at every severity and carrying both lenses itself (reproduction, then authority), dispatched before any fix is applied. MANDATORY for any non-trivial diff.
- **Phase 3b debug evidence**, multi-component bug; one agent per boundary instruments + logs. Same prompt as Phase 1 research, `investigation.md`, run in `debug` mode.
- **Multi-project work**, task touches multiple sibling projects (e.g. a backend repo AND a frontend repo); one agent per repo runs the same investigation or implementation wave in its own scope.

## When NOT to fan out

- **Tasks that share a file**, the file stops mapping to exactly one task, so a wave that stops early cannot be read back as a set of task IDs. The wave planner MUST split same-file tasks across waves.
- **Tightly-coupled investigations**, when finding A informs question B, run sequentially.
- **Tasks that need shared state**, they'll race.
- **One-line typo / config-only diffs**, multi-reviewer is overkill. Self-review is enough.
- **When a single agent is sufficient**, don't fan out for theatre. Two parallel agents have overhead.

---

## Dispatch pattern (one message, multiple Agent tool calls)

When firing N agents in parallel, put N `Agent` tool calls in **one assistant message**. Don't fire one, wait, fire another.

Foreground (default): the parent (hackify) waits for all N to complete before continuing. **This is what we want**, not background.

Use **`run_in_background: false`** explicitly if you want to be sure. Foreground is also the default.

---

## Template Contract

### Purpose

Every per-task template in this directory conforms to a single canonical 8-section structure. This contract exists so a dispatching agent can author a sub-agent prompt without inventing structure on the fly, so a sub-agent (even a Haiku-class model) sees the same shape every time, and so structural validators can grep for required headings. If a template in a sibling file does not match the contract, the template is wrong, not the contract.

### The 8 sections (mandatory + conditional)

Sections 1, 2, 3, 4, 5, 6, and 8 are MANDATORY in every template. Section 7 (SEVERITY) is CONDITIONAL, present in review/audit templates only, omitted entirely from build/research templates (not present as an empty section).

**1. ROLE (mandatory, every template)**

Five elements, all mandatory:

(a) Identity + seniority, "You are a senior `<discipline>` engineer with 15+ years of experience in `<domain>`."

(b) Domain expertise, specific systems / patterns / stacks the role has lived in. 2-4 concrete items.

(c) Standards the role follows, cite by name, version-pinned where applicable. Allowed tokens are listed in the Framework citation allowlist below. Cite 1-3 that genuinely apply. Citations outside the allowlist must be added to the allowlist with a justification comment.

(d) Rejected anti-patterns, "You reject `<X>`, `<Y>`, `<Z>`." Three to five concrete things this role refuses to ship.

(e) Behavioral bias, "Bias to: `<verb>`. Bias against: `<verb>`." Two lines, concrete actions. No "you are paid to ..." stylistic line.

**2. INPUTS (mandatory)**

Numbered list. Each input names a `{{placeholder}}` and the type (e.g. "`{{work_doc_path}}`, absolute filesystem path"). Placeholders are instructions to the DISPATCHING AGENT (the parent), NOT the sub-agent. The dispatching agent MUST replace every `{{placeholder}}` with a concrete value before sending the prompt. A sub-agent receiving literal `{{...}}` text is a dispatch bug, the sub-agent MUST refuse to proceed and MUST report `unfilled placeholder: <name>`.

EVERY template carries `{{plugin_root}}`, absolute filesystem path to the installed hackify plugin root, the directory holding `rules/` and `skills/`. It is the anchor every REQUIRED READING path below is built from, so a template that omits it can name no file its agent is able to open. The parent fills it from a path it ALREADY HOLDS and never by searching the filesystem: the absolute path carried in any always-on rule injection it received this session, or its own skill's base directory. A parent that searches is a parent guessing, and one wrong guess hands every agent in the wave the same unreadable tree. `{{plugin_root}}` REPLACES the two ad-hoc anchors that preceded it, `{{rules_dir_path}}` (carried by the implementer template alone) and `{{plugin_refs_dir}}` (by the merged-reviewer template alone), both now retired: one anchor concept, not three. No validator pins either retired name, so a template swapping them satisfies no gate and trips none either, which is exactly why the retirement is written down here rather than left to be noticed.

**3. REQUIRED READING (mandatory)**

The plugin files this role MUST open before it starts, each one anchored to `{{plugin_root}}`. It sits after INPUTS because it consumes one, and before OBJECTIVE because it binds before any work starts. Nothing else injects hackify's rules into a sub-agent: the always-on hook fires on a USER prompt and a dispatch is not one, so a rule file reaches an agent only because this section names it. A template that cites a canonical file and never lists it here has told its agent about a rule it never told that agent to read.

Carry this skeleton verbatim, the canonical text every per-task template copies:

```
**REQUIRED READING**.
Open every file below IN FULL before METHOD step 1. Each path is absolute, built
from `{{plugin_root}}`.
1. `{{plugin_root}}/<path>`, <one clause naming what it governs for THIS role>.

This list is EXHAUSTIVE and CLOSED. Every plugin file hackify requires of this
role is on it. Do not infer that another plugin file applies to you, do not
substitute a file you found by searching the tree, and do not treat a path cited
elsewhere in this prompt as required reading unless it also appears above: a
citation gives a finding its wording, this list is what binds you.

A path above that does not resolve is a dispatch bug and never a file to route
around. STOP before METHOD step 1, report `missing canon: <path>`, and produce no
other output.
```

One numbered entry per file, in the order the agent should read them, each clause naming what that file governs for THIS role rather than what the file is about in general.

**Step-bound entries, for a gated METHOD only.** Every entry binds before METHOD step 1, and the skeleton above states that verbatim. This section sanctions exactly TWO departures from that default, this one and the CONDITIONAL form below, and no third: a form not written here is not a form. The first of them: a template whose METHOD is explicitly GATED MAY bind an individual entry to a NAMED step instead. GATED means a rule inside that template FORBIDS opening the file before its step, because opening it earlier collapses a property that METHOD exists to keep. `phase-5-multi-review-merged.md` is the case this exception was written for: it runs five sealed passes, a pass that has already read another lens's catalog has stopped being separate, and loading every lens's files up front would destroy both the gating and the low-cost premise that reviewer exists to serve. **LONG IS NOT GATED.** A template that merely does not NEED a file until step 7 binds it at step 1 like every other template. The condition is a stated prohibition inside the template, not a convenient reading order, and without that reading the exception is a general escape hatch from this section rather than a clause of it.

A gated template varies ONE sentence of the skeleton and nothing else. Its opening line is reworded to say that each file is opened at the point its own entry names, with the entries that still bind up front marked *before step 1*; the `{{plugin_root}}` sentence, the EXHAUSTIVE-and-CLOSED paragraph and the missing-canon paragraph are carried byte-for-byte, exactly as every other template carries them. The binding is written into the entry itself, after the path and before the clause: `` `{{plugin_root}}/<path>`, at <named step>; <what it governs for THIS role>. `` and `` `{{plugin_root}}/<path>`, before step 1; <same>. `` One grammar, so a reader and a validator find the binding in the same place on every entry.

Step-binding moves WHEN a file is read, never WHETHER. The list stays EXHAUSTIVE and CLOSED, the dangling-citation rule below binds a step-bound entry exactly as it binds any other, and every path is still RESOLVED before METHOD step 1 even where it is read later, which is what keeps the missing-canon paragraph true for a gated template.

**Conditional entries, for a file a whole class of dispatch must not open.** The two forms above move WHEN a file is read. A CONDITIONAL entry moves WHETHER, and that is the whole of what separates it from them. It exists for a file that is canonical on SOME dispatches of a template and dead weight on the rest: `rules/test-scenarios.md` binds an implementer authoring tests and no other; `rules/security.md` binds an escalation reviewer whose lens is security and no other. Forcing those templates into a gating they do not have buys the contract nothing and costs their agents a read with no use, and the honest form is cheaper than the pretence.

A conditional entry carries its condition FIRST, ahead of the path, so a reader the condition excludes stops before the path rather than after the clause. One grammar, so a reader and a validator find the condition in the same place on every entry:

`` CONDITIONAL, read WHEN <predicate>: `{{plugin_root}}/<path>`, <what it governs for THIS role>. ``

A template carrying one or more conditional entries varies ONE sentence of the skeleton and nothing else, its opening line, which becomes *Open every file below IN FULL before METHOD step 1, a CONDITIONAL entry only when its condition holds.* The `{{plugin_root}}` sentence, the EXHAUSTIVE-and-CLOSED paragraph and the missing-canon paragraph are carried byte-for-byte, exactly as every other template carries them.

**What stops CONDITIONAL from swallowing this section.** A list is worth something because it is exhaustive and closed, and a condition an agent weighs for itself is one step from "read whatever you judge applies", which is the defect this section exists to remove. Three constraints hold that line. An entry failing any one of them is not conditional; it is an unconditional entry written wrong, and the repair is to bind it outright.

1. **The predicate names a `{{token}}` that template declares as a numbered input.** The parent filled that value at dispatch time, so the agent READS its condition instead of judging it, and two agents handed the same dispatch skip the same entries. "Read WHEN a task touches auth" names no input and is therefore a judgment; "read WHEN `{{test_mode}}` is `test-authoring`" names one and is therefore a fact. This is the constraint that does the work, and it is the one a validator can check.
2. **It is settled ONCE, before METHOD step 1, off the dispatch alone**, never off something the agent discovers while working. That is what stops a conditional entry becoming a mid-work hatch to go and read something, and it is why every path on the list is still RESOLVED before METHOD step 1, a skipped one included: a path is resolved whether or not it is opened, which keeps the missing-canon paragraph true for a conditional template exactly as it stays true for a gated one.
3. **Ambiguity resolves toward READING.** Where a predicate admits a borderline dispatch, the agent opens the file. A conditional entry may only ever remove a read that is certainly useless to this dispatch; it may never be the reason a file that mattered went unread.

**CONDITIONAL narrows WHO opens a listed file. It never widens WHAT may be opened.** The list stays EXHAUSTIVE and CLOSED on every dispatch: an agent may still not infer that another plugin file applies to it, not substitute one found by searching the tree, and not treat a path cited elsewhere in its prompt as required reading. The dangling-citation rule below binds a conditional entry exactly as it binds any other, so a file earns its citations by being LISTED, whether or not this particular dispatch opens it.

**The dangling-citation rule.** Inside a template's FENCED BLOCK, a plugin file may be CITED only if that same file also appears on that template's REQUIRED READING list. A citation to a file the agent is never told to open is a dangling pointer, and the repair is one of two things, never a third: bind the file or drop the citation. The rule binds the fenced block ALONE, because that block is the text the sub-agent actually receives. Prose outside it, the file's own framing and the tail beneath `<!-- parent-side: not mirrored -->`, is addressed to the parent and to whoever maintains the file, and may cite freely.

**Two rule files bind nobody, by decision.** `rules/phase-discipline.md` and `rules/plugin-map.md` are deliberately on NO agent's REQUIRED READING list, each for its own reason, and neither for want of one. Phase discipline governs the orchestrating parent's phase ledger, and a dispatched agent owns no phase. The plugin map is a MAP and not a law, as its own opening says: it is injected once per session to the parent by the `SessionStart` hook, it restates no rule by design, and it names entry points a sub-agent never chooses between, having been dispatched into one already. Both decisions are recorded here because a file binding nobody by decision and a file binding nobody by rot look identical from the outside, and only the written decision tells the two apart. A third rule file joining this paragraph silently is the rot it exists to catch, so a rule file that binds nobody is either named here with its reason or is a defect.

**4. OBJECTIVE (mandatory)**

One sentence. Exactly one noun phrase deliverable. If the template produces more than one deliverable, split into multiple templates.

**5. METHOD (mandatory)**

Numbered steps, minimum three. Each step is one concrete action with a verifiable outcome ("read X then grep for Y", not "investigate Z"). For templates that touch user-facing prose across multiple files, METHOD MUST contain a step naming the canonical sentence (or canonical fact) the agent will replicate verbatim, with the source file path. Generic "be consistent with related files" is forbidden.

**6. VERIFICATION (mandatory, two shapes; pick the one that fits)**

See "VERIFICATION shapes" below for the picker.

One item is mandatory in EVERY template whichever shape that template picked. It takes one of three wordings, settled by the picker below rather than by preference. The DEFAULT, carried verbatim by every template whose list earns no variant, is:

> Did you open every REQUIRED READING path in full before METHOD step 1? (yes / no)

Shape A carries it as a reported line beside the script's exit code, Shape B as one more numbered checklist item. A template that lists required reading and never asks whether it was read has stated a rule it does not check, which is the shape this contract exists to refuse.

**The gated variant.** A template GATED under §3 carries this line in place of the universal one, worded verbatim:

> Did every REQUIRED READING path resolve before METHOD step 1, and did you open every entry in full at the step its own entry names? (yes / no)

It asks the same question a gated METHOD can answer honestly. Step-binding moves WHEN a file is read and never WHETHER, so resolution still binds before METHOD step 1 and the reading binds at the step the entry names, and both halves are checked here rather than one being dropped.

**The conditional variant.** A template carrying one or more CONDITIONAL entries under §3 carries this line in place of the universal one, worded verbatim:

> Did every REQUIRED READING path resolve before METHOD step 1, and did you open in full, before METHOD step 1, every entry whose condition your dispatch met? (yes / no)

This line is a repair, not a tidying, and the defect it repairs is worth stating because it is invisible until traced. The universal line asks whether EVERY listed path was opened. An agent that correctly SKIPPED a conditional entry must answer no. Where a template loops on a no, which Shape B's "if ANY answer is no, loop back to METHOD" makes the norm, METHOD opens no required-reading file, so the answer cannot change on the next pass either: the agent buys termination only by answering untruthfully, by opening the very file its list told it to skip, or by quietly reading "every path" as "every path that applied to me", which converts a verification into one that cannot fail. Each of the three is a defect, and the template offering only those three is the bug. The conditional line keeps both halves that matter, resolution before step 1 for every path on the list and reading before step 1 for every entry this dispatch met, and asks the agent for neither a lie nor a loop.

**EXACTLY ONE of the three lines appears in a template, never two and never none.** Which one is not a choice, it is read off the list the template actually carries:

- a list of plain entries only, the universal line;
- a list carrying any step-bound entry, the gated variant;
- a list carrying any CONDITIONAL entry, the conditional variant.

Whichever line a template carries, it is carried exactly as the universal line is, Shape A as a reported line beside the script's exit code and Shape B as one more numbered checklist item, and on ONE unwrapped physical line so a reader and a matcher see the same item. A template whose line does not match its own list has broken this rule in one of two directions and both are defects: the universal line over a conditional list demands a read the template forbids, which is the loop traced above, and a variant over a list that earns neither has widened its own bar into one it passes by construction, which is the same defect as omitting the line. **A list mixing step-bound and CONDITIONAL entries is out of contract.** No template needs both, the two variants cannot be merged into one honest sentence, and the repair is to pick one shape rather than to invent a fourth line.

**7. SEVERITY (review/audit templates ONLY, omit on non-review templates)**

Anchored examples per level. Minimum 2 examples per level. Critical example anchors should reference real failure modes (e.g. "schema field cannot be verified against live docs" = Critical, not Important). Mandatory line, verbatim:

> If you cannot verify a claim against live docs or live code, mark the finding Critical, not Important.

**8. OUTPUT (mandatory)**

Word cap shape depends on template type:

- Review/audit/research templates: single global word cap with reasoning ("≤300 words, terse review beats long review").
- Implementation/build templates: per-section sub-budget ("Files touched: 1 line each; Test mode + gates: 1 line per test; Deviations: ≤80 words; Self-review: compact ✓/✗ table").

Exact report format with named sections. What to omit if nothing relevant (still report explicitly: "No findings.", never go silent).

#### ROLE worked example (Phase 5 security reviewer)

```
You are a senior application security engineer with 15+ years of experience
auditing server-side and typed-language backends, OAuth/OIDC implementations,
multi-tenant data isolation, and CI/CD supply chains.

Your domain expertise covers: HTTP request lifecycles across router /
service / middleware module layers, schema-driven migration tooling,
session-token and cookie issuance, key-value session stores, relational
row-level security, and CI runner secrets handling.

You apply OWASP Top 10 (2025), SANS CWE-25, NIST SP 800-63B, and the
relevant clauses of RFC 6749 and RFC 7519.

You reject: silent error fallbacks, broad CORS allowlists, secrets in
source, unparameterized SQL, session tokens stored in browser-accessible
storage, missing rate limits on auth endpoints.

Bias to: flagging.
Bias against: deferring to author intent on "it works in practice".
```

### Framework citation allowlist

Cite frameworks and standards by name, version-pinned where applicable. The allowed tokens are:

- OWASP Top 10 (2025)
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

Cite 1-3 that genuinely apply to the role. Citations outside this list MUST be added to the allowlist with a justification comment, the structural validator greps against this allowlist.

### Placeholder convention

All runtime values use `{{snake_case}}` placeholders inside the template body. Placeholders are documentation to the DISPATCHING AGENT (the parent), not to the sub-agent. There is no runtime interpolation engine, substitution happens when the parent writes the actual sub-agent call. Sub-agents always receive concrete values, never literal `{{...}}` text.

If a sub-agent encounters literal `{{...}}` text in its prompt, that is a dispatch bug. The sub-agent MUST refuse to proceed and MUST report `unfilled placeholder: <name>` so the parent can fix the dispatch.

Zero literal absolute paths (`/Users/`, `/home/`, `/tmp/`) appear inside template bodies, paths resolve from placeholders at dispatch time.

### VERIFICATION shapes

Pick exactly one of two shapes per template:

**Shape A. Executable.** For templates that touch the filesystem or produce an auditable artifact (Implementation, Cross-package verification, structural rewrites): inline bash script that exits 0 on success, non-zero on failure. The agent runs it before reporting "done"; if non-zero, the agent loops back to METHOD.

**Shape B. Self-checklist.** For prose-producing templates that have no filesystem artifact (Research, Spec-review, Multi-reviewer, Code-review escalation, Debug evidence. Phase 3b is read-only investigation, no filesystem artifact): a numbered yes/no list the agent MUST paste into its report under a "Verification" heading. If any answer is NO, the agent loops back to METHOD, not OUTPUT. Every checklist item is a single question with a yes/no answer, no "evaluate the X."

### What the forward validator must recognise, check `[41]`

`scripts/validate-dod.d/41-required-reading.sh` enforces the forward direction of §3, and it knows two of the three entry forms above. This subsection is the specification for teaching it the third, written down here so that fragment is changed against a stated rule rather than against somebody's memory of the round that found the gap. Three things it must be taught, one it must keep.

**1. The three VERIFICATION lines are canonical now, so pin them verbatim.** Its assertion (g) accepts any line that names REQUIRED READING and carries `(yes / no)`, and its header gives the reason: it must not encode a sentence it would have to guess, because a wrong guess reds a correct file. That reason is spent. §6 above states all three sentences word for word, so the fragment compares against three literals instead of guessing at one, and reds a template whose line matches none of them. Its planted controls carry approximations of the gated wording, so they must be re-planted on the canonical sentences or they stop proving what they claim to prove, and the control-count equality must rise with every control added.

**2. The picker is the real check, and nothing performs it today.** Classify every numbered entry of a list by its grammar: plain, step-bound (carrying `, at <named step>;` after the path), or conditional (opening `CONDITIONAL, read WHEN`). Classify the template's verification line as one of the three literals. Red unless the pairing §6 sets out holds. **A list carrying a CONDITIONAL entry beside the universal line is the exact defect this specification exists to catch**, and (g) as written passes it in silence, because the universal line does name REQUIRED READING and does carry `(yes / no)`. Red also on a list mixing step-bound and conditional entries, which §6 places out of contract.

**3. A conditional predicate must name a declared input.** For every entry opening `CONDITIONAL, read WHEN`, require at least one `{{token}}` in the text ahead of the colon, and require that token to be a numbered input of that same fenced prompt. The fragment already parses those input names for its `{{plugin_root}}` assertion, so the set is in hand and this costs it no new parser. That is §3's first constraint made mechanical, and it is the whole of what keeps a condition a fact the parent decided rather than a judgment the agent makes. §3's other two constraints are review-time obligations on a template's author, not grep-shaped, and asserting on them would mean guessing at prose.

**The controls that make the three teachable, named rather than left to invention.** Nothing above is proven until a planted defect has made the real check red, which is the fragment's own standard, so it grows four probes: a CONDITIONAL entry sitting beside the universal line MUST red, which is the live defect and the reason this whole subsection exists; a CONDITIONAL entry whose predicate names no `{{token}}` declared as an input of that same prompt MUST red; a CONDITIONAL entry carrying a declared-token predicate beside the conditional line MUST pass clean, so the check is shown to be strict rather than merely hostile; and the two probes already planted on approximations of the gated wording are re-planted on the canonical sentence, which is the one place pinning verbatim changes an existing control's meaning. The control-count equality rises by the number of probes added, or the new ones can go missing as quietly as the defect they catch.

**What it must keep.** The opening line's wording stays unasserted. Its header already argues that for the gated case, and the conditional case needs the same room: three legal openings now exist and the fragment reads none of them. Floors move with new assertions, or a grammar that stops matching prints a confident green over nothing.

---

## Per-task templates

Every path an agent is REQUIRED to open is written as `{{plugin_root}}/...` and is therefore absolute by the time that agent reads it. A relative path travels nowhere here: a sub-agent's working directory is the USER's project, so a pointer written `references/review-and-verify.md` resolves against that tree and finds nothing, and the agent is left holding a rule it cannot read. For project-specific files (a workspace or project `CLAUDE.md`, a design spec), keep the existing treatment, pass the **absolute path** dynamically and let hackify substitute the actual path at dispatch time, because those live in the user's tree and no plugin anchor reaches them. Either way zero literal absolute paths appear inside a template body, the Placeholder convention's rule above: both `{{plugin_root}}` and the project-path placeholders are filled by the parent at dispatch time.
