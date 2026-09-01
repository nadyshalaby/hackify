# Review scope, slicing the diff

Loaded from Phase 5. This file defines `{{review_scope}}`, the one input that decides **which part of the sprint diff each reviewer reads**. A reviewer only reads the files its lens can judge.

**Slicing belongs to the panel, and the panel is what a user asks for by name.** A review round dispatches the merged all-lens reviewer, which takes no `{{review_scope}}` at all, because it carries Reviewer B's lens and B is never sliced. So on the route a round takes on its own there is nothing here to resolve, and the one part of this file that still runs is the scope ledger at the bottom, carrying its row per changed path with that single reviewer named as what read it. Everything else below is addressed to the panel. The route, and the measured cost of taking it: [phases/phase-5-review.md](phases/phase-5-review.md).

The saving is coverage-neutral by construction. A file no reviewer claims goes to Reviewer B. Nothing is dropped; the reading is redistributed.

## Why this exists

Six reviewers each ran `git diff <base>..<head>` and read the whole thing, in six separate contexts, and then read it again to close the loop. The panel is narrower now and B carries two lenses, but the arithmetic that motivated slicing is unchanged. The security reviewer read stylesheets. The design reviewer read migrations. The diff was the single largest line item in a sprint and most of it was being read by someone who could not act on it.

## The grammar

`{{review_scope}}` is a single string. It is one of two forms:

| Value | Means |
|---|---|
| `.` | the whole diff is yours |
| `<pathspec list>` | your assigned slice, space-separated git pathspecs relative to `{{project_root}}` |

## Resolving a scope into a diff command

The value is not a pathspec you can paste. Resolve it in two steps, in this order.

1. **If the value was absent or empty, use `.`.** A reserved word is not part of this grammar any more, and neither is a bare `all`: handed to git it matches a directory called `all/`, and in a repo without one it matches nothing at all, so empty output, exit 0, no error, a reviewer that read nothing and a report that says clean. Anything that is not a pathspec list is a dispatch defect, and the reviewer reports it rather than guessing.
2. **Append the `docs/work/` exclusion pathspec unconditionally**, whatever step 1 produced. It is the same literal the manifest step below builds with; copy it from there, quotes included. A bare `.` carries no exclusion of its own, so the append is never optional.

Every reviewer therefore runs one shape, `git diff {{base_sha}}..{{head_sha}} -- <resolved pathspec> <exclusion>`, where the exclusion is step 2's literal and never varies. Only the middle term moves:

| Value received | Resolved pathspec |
|---|---|
| `.` | `.` |
| `src/auth/ src/db/` | `src/auth/ src/db/` |
| absent or empty | `.` |

**Resolution rewrites the diff command and never the echo.** The echoed line is the value as received, byte for byte. A reviewer that echoes what it resolved to turns a slice it was handed into a bare `.`, and the parent can no longer tell a sliced lens from an unscoped one.

**A resolved command that returns no paths is an empty scope, not a clean one.** A dispatcher can hand a lens a slice that turns out to hold nothing, a scope naming only paths the exclusion then removes being the obvious one. Say so in the report. Zero findings over zero files is not a verdict and must never be counted as one.

**An absent or empty value means `.`.** This is deliberate and it is the safe direction: a dispatcher that forgets to slice buys nothing and loses nothing, because the reviewer falls back to the whole diff. A missing slice is recoverable. A silently narrowed one is not.

**Every reviewer that takes a scope echoes the value it received**, verbatim, on the first line of its report:

```
Scope: src/auth/ src/db/migrations/
```

That echo is what lets the parent prove each lens got the scope it was assigned instead of taking its own word for it. **Reviewer B has no scope to echo**, because B is never sliced; the paragraph at the bottom of this file says what B's silence does and does not prove.

## Reading outside your scope

The scope bounds what you **diff**, not what you may **read**. When a finding needs the contract around a change (the caller, the type it returns, the guard above it), open that file even if it sits outside your pathspecs, and say in the finding why you opened it. Never widen the diff itself.

## Who gets sliced

| Reviewer | Sliced | Why |
|---|---|---|
| **A** security & correctness | yes | its lens is auth, network, storage, process and dependency surfaces, a stylesheet cannot carry a finding it can act on |
| **D** performance | yes | the perf catalog applies to code paths, not to docs or fixtures |
| **E** design conformance | yes | it already filtered the diff to UI-bearing files as its own step 1, so the dispatcher is doing that filter one context earlier, behaviour is unchanged |
| **F** cross-module coherence | yes | scoped to the boundary set, the files that export or import across a module edge, plus their counterparts |
| **B** quality, engineering law & plan consistency | **never** | B applies the semantic tier to *every* touched file and re-judges *every* law-scout row. There is no subset of the diff B does not need. B is the floor under this optimisation and pretending otherwise would delete coverage |

**Reviewer C used to be sliced and is not on this table any more.** v0.13.0 folded it into B, so its lens inherited B's terms: it now sees the whole diff instead of a task-mapped slice. Coverage goes up, the wave drops a diff read, and the slicing saving on that lens is what the merge gave back. That trade is written down here rather than left to be rediscovered from the table's missing row.

## Building the manifest

Do this once, at Phase 5 dispatch, before the message goes out. The scouts already walked the whole diff to build their tables, so the classification costs no extra reads.

1. List every changed path: `git diff --name-only <base>..<head> -- . ':(exclude)docs/work/*'`. The exclusion is load-bearing, not housekeeping; the paragraph below says why.
2. Assign each path to every lens whose surface it touches, using the table above. A path may go to several. Most go to at least two.
3. **Any path you cannot confidently classify goes to B**, which is already reading everything, so an unclassifiable file is never an uncovered file.
4. Write the scope ledger (below) into the work-doc Sprint Review.
5. Pass each sliced reviewer its own pathspec list as `{{review_scope}}`. B takes no `{{review_scope}}` at all, so there is nothing to pass it.

**When a lens's list comes out empty, that lens has nothing to review.** Do not dispatch it, and write that down in the Sprint Review with the reason. There is no evidence gate and no folding left to record it against, so the empty slice is itself the whole reason that lens did not run.

### Why `docs/work/` is excluded

The work-doc is the ruler the diff is measured against and cannot also be the measured. Phase 5 writes its scope ledger and its decision table into the work-doc while its reviewer is reading, so a lens that graded the work-doc would be grading the record of its own grading, and every entry the phase makes would file a finding against the phase. One sprint rewrote its work-doc 25 times. Nothing about the work-doc's accuracy goes unchecked, because Reviewer B still reads it in full as an INPUT and still flags any file with no authorizing task entry. The precedent is `CAP_SEARCH_PATHS` in `scripts/validate-dod.d/80-file-size-caps.sh`, which leaves `docs/` out. Read it as what it is, an allowlist of the six primitive directories rather than a carve-out aimed at work logs: `dist/` (generated) and `LICENSE` sit outside it too, the shared reason being the general one, none of them is a primitive the caps govern, and a work log is only the nearest instance of it. `CHANGELOG.md` and `README.md` are no longer in that company, and that changed in this same sprint: a second `find -maxdepth 1` in that file's `cap_file_list` reaches the repo root, so both are scanned. The exemption `CHANGELOG.md` carries through `CAP_APPEND_ONLY` is from the CAP and never from the SCAN, it is still opened, counted and reported through `cap_exempt`, and `CAP_ROOT_WITNESS` names `README.md` as the witness that reddens the check the day the root scan stops reaching it.

## The scope ledger

One row per changed path. This is the artifact that makes "every file was covered" checkable instead of asserted.

```
| path | lenses | verdict |
|---|---|---|
| src/auth/session.ts | A B F | clean |
| src/ui/Button.tsx   | B E   | 2 findings |
```

**The ledger is written once, at dispatch, and its verdict column is filled once, when the reports come back.** It used to carry a blob hash too, because a verdict could be carried from one round into the next and a path-keyed carry-over is unsound. Nothing carries now: the round's reviewer runs once, so a verdict is only ever about the bytes it read.

## One review, one refuter

Phase 5 dispatches exactly ONE review and ONE refuter, and the phase ends when the surviving findings are fixed. There is no second review, no second refuter and no re-scan, however much the fixes changed. Nothing carries over, which is why the grammar above has two forms rather than four and why the ledger has three columns rather than five. The rule, the cost it accepts and the evidence behind it are canonical in [phases/phase-5-review.md](phases/phase-5-review.md).

**That cap counts ROUNDS, not lenses, and the route underneath it has moved.** Phase 5 reaches for the merged all-lens reviewer on its own now, and the panel is what a user asks for instead; either way the count is one review and one refuter, which is the whole of what the cap fixes. Both of its sentences are held identical at the four files that state the cap in full, this one plus `SKILL.md`, `phases/phase-5-review.md` and `review-and-verify.md`, and that is checked rather than asserted. `SB_CAP_SITES` in `scripts/validate-dod.d/75-ship-bar.sh` pins the closing clause at each of the four, scans the sentence carrying it for softeners, and reds when a fifth file under `skills` picks that clause up; `PLS_CAP` in `scripts/validate-dod.d/96-review-scope-sites.sh` pins the opening sentence over a set it discovers rather than a set written down. A file that only refers to the cap in passing states it in its own words and sends the reader here, which is why the pinned set is the four that state it in full rather than every file that mentions it. The cap names neither route on purpose, so read it as the round cap it is rather than as a claim about which reviewer a round reaches for.

**Reviewer B is exempt from the SCOPE echo, and that exemption is structural rather than a
courtesy.** B takes no `{{review_scope}}` at all: B is never sliced, so there is no scope for it to
echo. An earlier gate demanded a scope echo from every lens, which made it unsatisfiable, because
`72-diff-slicing-pins.sh` fails the build the moment B's prompt gains a `{{review_scope}}`
placeholder. One rule required exactly what another forbade, and no dispatch could satisfy both.

**The validator pin is not a stronger proof than the echo, it is a proof of something else**, and an
earlier draft of this file got that backwards. The pin is a universal over TEMPLATES: no copy of B's
prompt may carry the placeholder, so no B can ever be sliced through its inputs. An echo is an
existential over RUNS: this particular instance read what it says it read. Neither implies the
other. A dispatcher can narrow B in prose without touching the placeholder, and one has, handing B a
17-path weighting that was compliant with the pin and a narrowing all the same. So B's silence was
never coverage, and reading it as coverage was the defect.

**B used to open its report with a round marker in the echo's place, and that marker is retired
with the rounds it named.** It was never coverage evidence: a B that read every path and a B
narrowed in prose emitted the identical string, because it recorded the round the dispatch NAMED
and nothing about what B was handed. The gap it left is closed by the ledger, one row per changed
path, which is what makes coverage checkable instead of asserted. If B ever gains a scope
placeholder, this exemption has to be reconsidered rather than patched around.
