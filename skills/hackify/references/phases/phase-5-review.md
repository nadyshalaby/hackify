# Phase 5, Review (five-agent panel, mandatory)

Loaded by `SKILL.md` when this phase opens. The phase's entry conditions, hard gates and exit artifact are stated in `SKILL.md`; this file is the protocol.

**Ledger, at phase open.** Set the phase ledger's `Phase 5. Review (decision table empty)` to in-progress in the work-doc's `## 0. Phase ledger` block, with frontmatter `status: reviewing` in the same edit, and re-print the whole block after that edit is saved. Never open it while `Phase 4. Verify` is still open. That is the **phase** ledger, distinct from the scope ledger you build below. Contract: [../phase-ledger.md](../phase-ledger.md).

### The route: the five-agent panel

**The five-agent panel is Phase 5's default reviewer route in both quick and full mode, and the merged all-lens reviewer (`hackify:reviewer`) is the explicit, named, lower-cost opt-out.** The parent dispatches A, B, D, F and E-on-UI in one message exactly as the rest of this file describes, and nothing else about the round moves: the same refuter behind it, the same one-round cap.

**Dispatch by registered agent type, and a panel round in ONE message.** On Claude Code the merged reviewer and every panel prompt below is already installed as a subagent type, so you dispatch the type and pass ONLY its INPUTS. **Do not open the template file to paste the prompt**, the agent already carries it and reading it charges you the same text twice. The type-to-INPUTS table is `references/parallel-agents/README.md`; open a template only when authoring one, or on a runtime with no agent registry, where pasting is the only path (`references/runtime-adapters.md`).

**Build the dispatcher inputs BEFORE the message goes out.** Each is the parent's job; a reviewer that receives an unfilled placeholder refuses and reports it, which costs a whole round. The table is written for the panel, and the merged reviewer takes the same artifacts under the names its own INPUTS list uses; `{{review_scope}}` is the single row with no counterpart on the opt-out route.

| Input | Goes to | Built from |
|---|---|---|
| `{{law_scout_report}}` | Reviewer B | law-scout re-run on the whole sprint diff (`references/law-scout.md`) |
| `{{perf_scout_report}}` | Reviewer D | perf-scout re-run on the whole sprint diff (`references/perf-scout.md`) |
| `{{task_file_index}}` | Reviewers B **and** F | the work-doc's Execution waves block plus each task's file allowlist, keyed `W<n>/T<m>`. Build it once and pass the same map to both: F reads the `W<n>` prefix to tell which seams cross a wave boundary, B matches on `T<m>` to map each touched file back to its authorizing task |
| `{{repo_brief}}` | every reviewer | the `### Repo Brief` block you built at the end of Phase 2 (`references/repo-brief.md`), passed verbatim. Reviewers that get it stop rediscovering the stack, the test command, and the layering rules one agent at a time |
| `{{review_scope}}` | Reviewers A, D, E and F | the scope manifest you build below. Each lens gets the pathspecs it can actually act on. **B is never sliced and takes no `{{review_scope}}` at all**, it applies the semantic tier to every touched file, so there is no scope to hand it and none for it to echo back. An absent value means the whole diff, so a forgotten slice costs tokens and never coverage (`references/review-scope.md`) |
| `{{metrics_table}}` | Reviewer B | the project's own linter plus an AST pass over the touched files: function length, parameter count, nesting depth, file length. B judges the rows instead of counting them by reading. Pass the literal `unavailable` when the project's tooling cannot produce it, and B counts them itself |

Surviving candidates from both scouts enter the decision table beside reviewer findings.

### The merged all-lens reviewer, when the user asks for it

**`hackify:reviewer`, one agent carrying every lens over one read of the diff as five gated passes** (`references/parallel-agents/phase-5-multi-review-merged.md`), **stays registered and dispatchable, and the user reaches it by asking.** "Use the merged reviewer", "single reviewer round", or any plain request naming it is enough, symmetric with how the panel used to be requested. On such a request the parent dispatches `hackify:reviewer` alone in place of the panel, and nothing else about the round moves: the same refuter behind it, the same one-round cap. What choosing it costs against the panel's reach is measured and stated under **The merged all-lens reviewer, and what routing to it costs** below, rather than left implied.

**That is a request the user makes, never a demotion the parent applies on its own.** No diff size, no file count, no touched surface and no severity moves a round off the panel. Reading a diff's shape as an implied request for the cheaper route is precisely the auto-demotion this decision rules out.

**Its INPUTS, filled for FULL mode.** Fourteen, every one required, none of them blank, and the agent refuses the dispatch on a blank or on an unfilled placeholder: `project_root`, `base_sha`, `head_sha`, `work_doc_path`, `project_rules_path`, `changelog_path`, `law_scout_report`, `perf_scout_report`, `task_file_index`, `metrics_table`, `design_spec_path`, `reference_images`, `repo_brief` and `plugin_root`. **`plugin_root` is the absolute filesystem path to the installed hackify plugin root**, the directory holding `rules/` and `skills/`, and it is the anchor every REQUIRED READING path in that template is built from, so it never takes `none` or a blank. Fill it from a path you ALREADY HOLD, never by searching the filesystem: the absolute path carried in any always-on rule injection you received this session, or your own skill's base directory. It replaced the retired `plugin_refs_dir` one-for-one, which is why the count is still fourteen. There is no `review_scope`, and its absence is the design: the agent carries lens B, which is never sliced, so no subset of the diff is safe to withhold from it. **`work_doc_path` is the live path to this sprint's work-doc**, because full mode has one. Quick's instruction to write an in-chat goal anchor out to a temp file is quick's own workaround for having no work-doc, and it does not apply here. `design_spec_path` and `reference_images` take the literal `NONE` where the project has neither, and `metrics_table` takes the literal `unavailable` only when the recipe below cannot produce it. The two scout tables and `task_file_index` are the same artifacts the dispatcher table above describes, built once by the parent on either route.

### Slice the diff before you dispatch

**This section applies by default, because the panel is the default route.** Slicing runs before every panel dispatch. The merged reviewer, the named opt-out, is unsliced by construction: choosing it instead leaves nothing to slice, and the scope ledger still gets its row per changed path, naming that one reviewer as what read it.

The panel reading the same whole diff in full, once per lens in its own context, is the largest single line item in a sprint, and most of what each lens reads is a file it cannot act on. Build the manifest once, off the file list the scouts already walked, so the classification costs no extra reads:

1. `git diff --name-only <base>..HEAD -- . ':(exclude)docs/work/*'`. The exclusion is mandatory and its reason is in [references/review-scope.md](../review-scope.md).
2. Assign each path to every lens whose surface it touches. Most paths get two or three.
3. **Anything you cannot confidently classify goes to B**, which is reading everything anyway, so an unclassifiable file is never an uncovered file.
4. Write the scope ledger into the work-doc Sprint Review, one row per path: the path, the lenses assigned to it, and the verdict each lens returned. That table is what makes "every file was covered" checkable instead of asserted.
5. Pass each sliced reviewer its own pathspec list. **A lens whose list comes out empty has nothing to review**, so do not dispatch it, and write that down in the Sprint Review with the reason.

Every reviewer that takes a scope echoes it as its report's first line. B takes none and echoes nothing, because B is never sliced. An echo proves a sliced lens got the scope it names, which is not the same thing as coverage; the scope ledger above, one row per path, is what makes coverage checkable instead of asserted. Classification table and value grammar: [references/review-scope.md](../review-scope.md).

### Build `{{metrics_table}}` before you dispatch B

B used to establish function length, parameter count and nesting depth by reading each touched function and counting. That is the most expensive way to obtain a number the project's own tooling already has. Build the table once, in the parent:

1. **File length.** `git diff --name-only <base>..HEAD -- . ':(exclude)docs/work/*' | tr '\n' '\0' | xargs -0 wc -l`.
2. **Function length, parameter count, nesting depth.** From the project's linter, using the lint command the Repo Brief already recorded. These are stock rules, not custom ones: ESLint ships `max-lines-per-function`, `max-params` and `max-depth`, and most other linters ship equivalents. Enable them for this run if the project's config leaves them off.
3. **One row per touched function the tooling reported, plus one row per touched file:** `| file | function | lines | params | depth |`. Rows under every cap may be dropped, B only needs the rows it has to judge.

**When the project's linter has no such rule and no AST pass is available, pass the literal `unavailable`.** B then counts them itself, exactly as it did before this input existed. Never pass a half-built table: a row that is silently missing reads to B as a row that passed, which turns a token saving into deleted coverage.

### Who is on the panel

**When the panel is the round's reviewer, A, B, D and F each run on every non-trivial diff, and E joins on a UI-bearing one.** There is no evidence gate and no folding. A lens either runs, or, in E's case alone, has no surface to run on and is omitted.

| Reviewer | Runs on |
|---|---|
| **B** quality, layering, engineering law, plan consistency, scope & goal drift | every non-trivial diff |
| **A** security & correctness | every non-trivial diff |
| **D** performance | every non-trivial diff |
| **F** cross-module coherence | every non-trivial diff |
| **E** design conformance | a UI-bearing diff; omitted, never folded, when the diff has no UI surface |

**E is the only conditional lens.** It is omitted rather than folded because design conformance leaves no residual for anyone else to carry: with no UI surface there is no token to check, no state to miss and no contrast ratio to measure, so there is nothing to hand on. Every other lens has a residual on any diff, which is why none of them is conditional any more.

**Why the gate went.** It was built to save reviewer contexts by folding A, D or F into B whenever the diff showed no surface for their lens, with B running the folded lens's residual checklist so nothing was dropped. The saving was real and the cost turned out to be larger: on the diff that retired it, the un-gated panel returned 41 findings where the gated one had returned 15. A checklist run by the reviewer that already read the diff for a different purpose is not the same as a reviewer whose whole context is that lens. Folding moved the words and lost the attention.

**What un-gating costs, stated plainly.** Two more reviewer contexts on a diff that genuinely has no auth surface and no hot path, every time. That is the bill, it is paid on every non-trivial wave, and it is not recovered anywhere. It buys the finding rate above, and B stops carrying a checklist for a lens it was never dispatched as.

### The lenses

- **Reviewer A. Security & correctness.** Auth, permissions, injection, CORS, cookies, secrets, PII, migrations, crypto, race conditions. Adversarial intent.
- **Reviewer B. Quality, layering & engineering law.** DRY, named types, layering, file/function caps, lint suppressions, `!` non-null, empty catches, bare `Error` throws, dead code. Consumes the law-scout table and re-judges every row, then applies the semantic tier no grep reaches: one-construct-per-file, folder conformance, controller purity, single responsibility, reuse, SOLID/YAGNI, and test coverage of what this diff added. Cites lawkeeper `rule_id`s (`references/law-scout.md`).
- **Reviewer D. Performance.** Consumes the scout report, judges every staged candidate, and hunts what greps cannot. N+1 shapes, algorithmic complexity, unbounded growth, wasted parallelism, blocking I/O on request paths, render storms. Cites `perf.<domain>.<slug>` IDs from `rules/performance.md` and sets final severity. A hot path is hot until proven cold.
- **Reviewer E. Design conformance** *(the one conditional lens, UI-bearing diffs)*. Audits the diff against the project's committed `docs/design/DESIGN.md`: hardcoded literals where a token exists, off-ramp type sizes, missing hover/focus/press/disabled states, the spec's own Don'ts, WCAG AA contrast and focus regressions, physical properties where logical are required. Names the exact replacement token per finding, and compares against reference frames when they exist. With no spec it falls back to `references/frontend-design.md` and reports the missing spec. Template: `references/parallel-agents/phase-5-multi-review-e-design.md`.
- **Reviewer F. Cross-module coherence.** The only lens that asks whether the pieces agree with each other. Per boundary-crossing symbol it names producer and every consumer, then checks shape (fields, optionality, nullability, enum sets), semantics (units, timezones, identifier space, ordering, bounds), error contract (throw vs null vs result object), duplicate concepts, and wiring completeness (route registered, handler subscribed, component mounted, column read). Cites file:line for BOTH sides. It exists because a wave's implementer is blind to the waves that ran before it and to all pre-existing code, which is where a producer and its consumers drift apart. Template: `references/parallel-agents/phase-5-multi-review-f-coherence.md`.

Cap at 5. Beyond the five lenses, a second-concern specialist may take a free slot (`references/parallel-agents/phase-5-escalation.md`). **Self-review still happens** by you, against `references/review-and-verify.md`'s checklist, reviewers are *additive* defense, not replacement.

**The merged all-lens reviewer, and what routing to it costs.** `references/parallel-agents/phase-5-multi-review-merged.md` (agent type `hackify:reviewer`) carries the same lenses in ONE agent as five gated passes, and it is what a user can ask for instead of the panel, whose roster is unchanged and which stays the instrument the merged agent is measured against. **The cost of choosing it is measured rather than argued, and the decision was taken with the number in view:** run head to head on `9d0961e..51ecd00`, the merged agent returned 16 findings and 1 Critical where this panel returned 29 and 4. That is the same shape as **Why the gate went** above, one layer up: the panel's reach is measured and known-larger, and the user has chosen to pay for that reach every round by making the panel the default. The merged reviewer is not being actively strengthened against the panel; it remains unchanged as the named opt-out, and the gap stated above is the known, accepted cost of choosing it.

**Carve-out (skill optional).** A diff that is *purely* a one-line typo / comment / config-only change can skip multi-reviewer. When in doubt, dispatch.

**Acting on feedback, address ALL findings (lawkeeper-style loop).** Build a decision table (Finding / Severity / Decision / Evidence) covering EVERY finding, **refute before you fix**, work the survivors in severity order, and **re-run review + verify to prove zero remaining**. No finding is left un-addressed.

**Refute before you fix.** A reviewer's finding is a claim, not a fact. Before spending an edit on it, dispatch ONE refuter for the round (`references/parallel-agents/phase-5-refute.md`, agent type `hackify:finding-refuter`), judging every finding at every severity and carrying both lenses itself, reproduction first and then authority. Pass it **each finding verbatim plus the hunk it names**, not the whole diff range. **The default is to KEEP the finding**, uncertainty is never a refutation, and a Critical dies only when BOTH lenses refute it, each with its own file:line counter-citation, and not even both lenses refuting closes the row; an Important or Minor dies on one. Dropping a real defect costs more than fixing a phantom, so the bias runs the opposite way from a content-generation refuter. Its verdicts are what let a `push-back` carry the evidence this workflow already demands. On a Critical the verdict is only that evidence and never the Decision itself: both lenses refuting earns an adjudication escalation, and the row stays `accept`, and out of the fix dispatch, until that reviewer rules and the user signs off.

| Severity | Action |
|---|---|
| Critical | Fix immediately, before merging. |
| Important | Fix before claiming Phase 6 done. |
| Minor | Fix too, defer to Retrospective ONLY with explicit user sign-off, never by default. |

### The address-all loop runs once, and the phase ends

Non-trivial fixes go through a batched approval wizard (propose 2-3 options, ask before writing); trivial fixes applied directly. Every fix is a dispatched edit, the parent still writes no diff.

**Phase 5 dispatches exactly ONE review and ONE refuter, and the phase ends when the surviving findings are fixed.** The round's reviewer reads `<base>..HEAD`, the refuter judges its whole batch at every severity, the fix waves address every finding that survived refutation, and Phase 5 is over. There is no second review, no second refuter and no re-scan, however much the fixes changed. A defect a fix introduces is fixed in the same fix sequence and reported in the Sprint Review; it does not open a new round. Anything still unresolved when the fixes are done goes to the user as a written list, never as another round.

**The reviewed diff is `git diff <base>..HEAD -- . ':(exclude)docs/work/*'`**, because the work-doc is the ruler the diff is measured against and cannot also be the measured. Reviewer B still reads the work-doc in full as an INPUT, so its accuracy stays enforced by every lens that measures the diff against it. Push back only with **technical evidence**, never performative agreement. Full loop + response pattern: [references/review-and-verify.md](../review-and-verify.md).

**What the cap gives up, stated plainly.** The rule it replaces was right about the mechanics. A clean review result describes the diff as it stood when the reviewer read it, not the diff after the fixes, so the last fixes ship without the reviewer ever having seen them. That risk is real and this cap does not remove it; it prices it. The evidence is the sprint that shipped the cap: one task took 14 review rounds and 32 waves, and each extra round bought less than the one before. Ten defects did surface after the panel closed, 3 created by fixes and 7 the panel had missed, and all 7 were one family, a summary restating a canonical fact that had since moved. That is narrow, real and known, and it is a better trade than a loop with no way to stop.

**Ledger, at phase exit.** The decision table is empty, every surviving finding is fixed and the verify triad is green on the touched scope, then one line of reflection (what changed, did it pass, what is next), then tick the phase ledger's `Phase 5. Review` and open `Phase 6a. Re-verify + land choice (Steps A, B, C)` in the work-doc's section 0, saved before the re-print. An omitted E, an undispatched empty-scope lens, or the one-line-typo carve-out is recorded with its reason in the Sprint Review, never dropped in silence.
