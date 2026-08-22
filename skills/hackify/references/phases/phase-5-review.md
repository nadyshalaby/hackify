# Phase 5, Review (parallel multi-reviewer, mandatory)

Loaded by `SKILL.md` when this phase opens. The phase's entry conditions, hard gates and exit artifact are stated in `SKILL.md`; this file is the protocol.

**Dispatch the wave in ONE message, by registered agent type.** On Claude Code every reviewer prompt below is already installed as a subagent type, so you dispatch the type and pass ONLY its INPUTS. **Do not open the template file to paste the prompt**, the agent already carries it and reading it charges you the same text twice. The type-to-INPUTS table is `references/parallel-agents/README.md`; open a template only when authoring one, or on a runtime with no agent registry, where pasting is the only path (`references/runtime-adapters.md`).

**Build the dispatcher inputs BEFORE the message goes out.** Each is the parent's job; a reviewer that receives an unfilled placeholder refuses and reports it, which costs a whole round.

| Input | Goes to | Built from |
|---|---|---|
| `{{law_scout_report}}` | Reviewer B | law-scout re-run on the whole sprint diff (`references/law-scout.md`) |
| `{{perf_scout_report}}` | Reviewer D | perf-scout re-run on the whole sprint diff (`references/perf-scout.md`) |
| `{{task_file_index}}` | Reviewers C **and** F | the work-doc's Execution waves block plus each task's file allowlist, keyed `W<n>/T<m>`. Build it once and pass the same map to both: F reads the `W<n>` prefix to find same-wave seams, C matches on `T<m>` |
| `{{folded_lenses}}` | Reviewer B | your gate decision below, one line per folded lens naming the lens and the evidence that let it fold. `none` when the full panel ran. B runs each folded lens's residual checklist, so a gated-off lens is carried, not dropped. B refuses if this input is absent |
| `{{repo_brief}}` | every reviewer | the `### Repo Brief` block you built at the end of Phase 2 (`references/repo-brief.md`), passed verbatim. Reviewers that get it stop rediscovering the stack, the test command, and the layering rules one agent at a time |
| `{{review_scope}}` | Reviewers A, D, E and F | the scope manifest you build below. Each lens gets the pathspecs it can actually act on. **B is never sliced and gets `.`**, it applies the semantic tier to every touched file. An absent value means the whole diff, so a forgotten slice costs tokens and never coverage (`references/review-scope.md`) |
| `{{metrics_table}}` | Reviewer B | the project's own linter plus an AST pass over the touched files: function length, parameter count, nesting depth, file length. B judges the rows instead of counting them by reading. Pass the literal `unavailable` when the project's tooling cannot produce it, and B counts them itself |

**Every dispatch of Reviewer B carries `{{folded_lenses}}`, in every round, with `none` as the value when the full panel ran.** B refuses on an absent value on purpose, an absent value cannot be told apart from "the dispatcher never decided". Re-dispatch B in a middle round with the same value the first round used, the gate decision belongs to the wave, not to the round.

Surviving candidates from both scouts enter the decision table beside reviewer findings.

### Slice the diff before you dispatch

Six reviewers reading the same whole diff in six separate contexts is the largest single line item in a sprint, and most of what they read is a file their lens cannot act on. Build the manifest once, off the file list the scouts already walked, so the classification costs no extra reads:

1. `git diff --name-only <base>..HEAD`.
2. Assign each path to every lens whose surface it touches. Most paths get two or three.
3. **Anything you cannot confidently classify goes to B**, which is reading everything anyway, so an unclassifiable file is never an uncovered file.
4. Write the scope ledger into the work-doc Sprint Review, one row per path: the path, its blob hash (`git rev-parse HEAD:<path>`), the lenses assigned to it, and each round's verdict. The hash is what makes a carried-over verdict checkable; a path-keyed ledger would carry a verdict across a file that changed twice.
5. Pass each reviewer its own pathspec list. **A lens whose list comes out empty has nothing to review**, so do not dispatch it, and record why on the gate line exactly as you would for a folded lens.

Every reviewer echoes the scope it received as its report's first line. That echo is what lets you prove the wave covered the diff instead of asserting it. Classification table, value grammar and the carry-over rules: [references/review-scope.md](../review-scope.md).

### Build `{{metrics_table}}` before you dispatch B

B used to establish function length, parameter count and nesting depth by reading each touched function and counting. That is the most expensive way to obtain a number the project's own tooling already has. Build the table once, in the parent:

1. **File length.** `git diff --name-only <base>..HEAD | tr '\n' '\0' | xargs -0 wc -l`.
2. **Function length, parameter count, nesting depth.** From the project's linter, using the lint command the Repo Brief already recorded. These are stock rules, not custom ones: ESLint ships `max-lines-per-function`, `max-params` and `max-depth`, and most other linters ship equivalents. Enable them for this run if the project's config leaves them off.
3. **One row per touched function the tooling reported, plus one row per touched file:** `| file | function | lines | params | depth |`. Rows under every cap may be dropped, B only needs the rows it has to judge.

**When the project's linter has no such rule and no AST pass is available, pass the literal `unavailable`.** B then counts them itself, exactly as it did before this input existed. Never pass a half-built table: a row that is silently missing reads to B as a row that passed, which turns a token saving into deleted coverage.

### Who is on the panel (evidence-gated, never silently absent)

**B is the standing member of every wave.** A, D and F are gated on evidence that their lens has something to look at, because the scouts already know what surface the diff touched. **E joins on UI-bearing diffs.** B used to share the standing slot with Reviewer C, and v0.13.0 merged them: two lenses that both ran every time and never folded were paying for two reads of one diff, and no evidence gate could ever have taken that saving.

| Reviewer | Runs when | When it does not run |
|---|---|---|
| **B** quality, layering, engineering law, plan consistency, scope & goal drift | always | never |
| **F** cross-module coherence | the diff crosses a module boundary: two or more modules, packages or layers are touched, **OR** any one touched file is imported by a file outside its own module | its residual checklist is handed to B via `{{folded_lenses}}` and B runs it |
| **A** security & correctness | the diff touches auth / session / token / permission / crypto, a network boundary, a database or migration, the filesystem or a shell, deserialization of untrusted input, or a dependency manifest **OR** the law-scout staged any `sec.*` row | its residual checklist is handed to B via `{{folded_lenses}}` and B runs it |
| **D** performance | the perf-scout staged any candidate **OR** the diff touches a loop over a collection, a query or ORM call, a cache, a fan-out, a list endpoint, or a render path | its residual checklist is handed to B via `{{folded_lenses}}` and B runs it |
| **E** design conformance | the diff is UI-bearing | omitted |

**F is gated because it is the one lens that needs two things to compare.** F asks whether a
producer and its consumers still agree. On a diff confined to one module there is no second
side: nothing crossed a boundary, so F spends a full reviewer's budget proving a negative it
was never given the material to prove. That is different from A and D, which fold when the
diff has no risky surface; F folds when the diff has no SEAM.

**The bar is deliberately low, and errs toward running F.** Two touched modules is enough. So
is one touched file that anything outside its module imports, because that import IS the seam
even when only one side of it moved. A diff you cannot classify in one sentence is a diff that
crosses a boundary, and F runs. The failure this gate must never produce is a half-built
feature shipping because both halves looked fine alone, which is the exact defect F exists to
catch.

**A gate decision is written down, never assumed.** One line in the work-doc Sprint Review names any lens that folded and the evidence that let it fold ("A folded into B, no auth/network/db/fs/crypto hunks, law-scout `sec.*` empty"). That same line is what you pass to B as `{{folded_lenses}}`, so the decision and the mechanism are one artifact and a fold can never quietly become a drop. **When the evidence is ambiguous, the reviewer runs.** A folded lens you cannot justify in one sentence is a lens you owed the diff.

**Folding moves a lens, it never removes one.** B's report carries a `## Folded lenses` section confirming it ran each inherited checklist, and every finding from one is tagged `[folded: A]`, `[folded: D]` or `[folded: F]`. A B report that names a folded lens without that section is an incomplete round, dispatch the real reviewer and re-run. A folded-lens finding that contradicts your evidence line means the gate decision was wrong, and B reports it Critical.

### The lenses

- **Reviewer A. Security & correctness.** Auth, permissions, injection, CORS, cookies, secrets, PII, migrations, crypto, race conditions. Adversarial intent.
- **Reviewer B. Quality, layering & engineering law.** DRY, named types, layering, file/function caps, lint suppressions, `!` non-null, empty catches, bare `Error` throws, dead code. Consumes the law-scout table and re-judges every row, then applies the semantic tier no grep reaches: one-construct-per-file, folder conformance, controller purity, single responsibility, reuse, SOLID/YAGNI, and test coverage of what this diff added. Cites lawkeeper `rule_id`s (`references/law-scout.md`).
- **Reviewer D. Performance.** Consumes the scout report, judges every staged candidate, and hunts what greps cannot. N+1 shapes, algorithmic complexity, unbounded growth, wasted parallelism, blocking I/O on request paths, render storms. Cites `perf.<domain>.<slug>` IDs from `rules/performance.md` and sets final severity. A hot path is hot until proven cold.
- **Reviewer E. Design conformance** *(UI-bearing diffs)*. Audits the diff against the project's committed `docs/design/DESIGN.md`: hardcoded literals where a token exists, off-ramp type sizes, missing hover/focus/press/disabled states, the spec's own Don'ts, WCAG AA contrast and focus regressions, physical properties where logical are required. Names the exact replacement token per finding, and compares against reference frames when they exist. With no spec it falls back to `references/frontend-design.md` and reports the missing spec. Template: `references/parallel-agents/phase-5-multi-review-e-design.md`.
- **Reviewer F. Cross-module coherence** *(gated on a cross-module diff)*. The only lens that asks whether the pieces agree with each other. Per boundary-crossing symbol it names producer and every consumer, then checks shape (fields, optionality, nullability, enum sets), semantics (units, timezones, identifier space, ordering, bounds), error contract (throw vs null vs result object), duplicate concepts, and wiring completeness (route registered, handler subscribed, component mounted, column read). Cites file:line for BOTH sides. It exists because Phase 3's parallel waves build each half blind to the other. Template: `references/parallel-agents/phase-5-multi-review-f-coherence.md`.

Cap at 5. Beyond the gate table, a second-concern specialist may take a free slot (`references/parallel-agents/phase-5-escalation.md`). **Self-review still happens** by you, against `references/review-and-verify.md`'s checklist, reviewers are *additive* defense, not replacement.

**Carve-out (skill optional).** A diff that is *purely* a one-line typo / comment / config-only change can skip multi-reviewer. When in doubt, dispatch.

**Acting on feedback, address ALL findings (lawkeeper-style loop).** Build a decision table (Finding / Severity / Decision / Evidence) covering EVERY finding, **refute before you fix**, work the survivors in severity order, and **re-run review + verify to prove zero remaining**. No finding is left un-addressed.

**Refute before you fix.** A reviewer's finding is a claim, not a fact. Before spending an edit on it, dispatch the adversarial refuters in one message (`references/parallel-agents/phase-5-refute.md`, agent type `hackify:finding-refuter`): two independent refuters with distinct lenses (reproduction, authority) per Critical, one batched refuter for the whole Important+Minor set. Pass each refuter **the finding verbatim plus the hunk it names**, not the whole diff range. **The default is to KEEP the finding**, uncertainty is never a refutation, and a Critical dies only when BOTH refuters refute it with a file:line counter-citation. Dropping a real defect costs more than fixing a phantom, so the bias runs the opposite way from a content-generation refuter panel. Their verdicts are what let a `push-back` carry the evidence this workflow already demands.

| Severity | Action |
|---|---|
| Critical | Fix immediately, before merging. |
| Important | Fix before claiming Phase 6 done. |
| Minor | Fix too, defer to Retrospective ONLY with explicit user sign-off, never by default. |

### The address-all loop, and what each round costs

Non-trivial fixes go through a batched approval wizard (propose 2-3 options, ask before writing); trivial fixes applied directly. Every fix is a dispatched edit, the parent still writes no diff. Rounds are **not** all the same size:

| Round | Panel | Diff range scanned |
|---|---|---|
| **First** | the full gated panel | each lens's slice of `<base>..HEAD` |
| **Middle** (after each fix batch) | only the reviewers whose findings that batch fixed, **plus F** | the fix diff only, `<pre-batch-sha>..HEAD` |
| **Final settle** | the full gated panel again | each lens's slice of `<base>..HEAD` minus the paths still holding a live verdict, passed with a `settle ` prefix |

F rides every middle round because a fix is exactly the kind of change that puts a producer and its consumer out of step. Re-run both scouts before the first and the final round; a middle round re-runs them scoped to the fix diff.

**Exit only on a settled diff:** a round that changed any code mandates another round, because that round's clean result describes the pre-fix diff, not the one on disk. **The loop may only end on a FULL round** (the full gated panel, the same gate decision and the same `{{folded_lenses}}` value as round one, and every lens dispatched with a `settle `-prefixed scope) that finds nothing AND leaves every byte of `git diff <base>..HEAD` covered by a live verdict.

**What a FULL round covers, now that verdicts carry.** The old rule was "the panel re-read every byte". The rule now is **every byte is covered by a live verdict, and F re-read its whole boundary set**. A verdict is live while the file's blob hash still matches the hash the ledger recorded beside it; the moment a file changes, its verdict dies and the path goes back into that lens's scope. This is a different guarantee from the old one, not a weaker one, but it is only as good as the ledger, so the ledger is mandatory the moment you carry anything. **F never carries over** and its settle value is always `settle all`: every other lens judges a file against itself, F judges it against its counterparts, and a counterpart moving breaks coherence while both files' own hashes sit still. A middle round can never close the loop, no matter how clean. Push back only with **technical evidence**, never performative agreement. Full loop + response pattern: [references/review-and-verify.md](../review-and-verify.md).
