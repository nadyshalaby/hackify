# Review scope, slicing the diff and carrying verdicts

Loaded from Phase 5. This file defines `{{review_scope}}`, the one input that decides **which part of the sprint diff each reviewer reads**. It carries two savings at once: a reviewer only reads the files its lens can judge, and the settle round only re-reads what actually moved.

Both savings are coverage-neutral by construction. A file no reviewer claims goes to Reviewer B, and a verdict is only carried when the file's bytes are provably unchanged. Nothing is dropped; the reading is redistributed.

## Why this exists

Six reviewers each ran `git diff <base>..<head>` and read the whole thing, in six separate contexts, twice (first round and settle round). The panel is narrower now and evidence-gated, and B carries two lenses, but the arithmetic that motivated slicing is unchanged. The security reviewer read stylesheets. The design reviewer read migrations. Then both read them again to close the loop. The diff was the single largest line item in a sprint and most of it was being read by someone who could not act on it.

## The grammar

`{{review_scope}}` is a single string. It is one of four forms:

| Value | Means |
|---|---|
| `.` | the whole diff is yours |
| `<pathspec list>` | your assigned slice, space-separated git pathspecs relative to `{{project_root}}` |
| `settle all` | settle round, nothing carried over, re-read the whole reviewed diff; `all` resolves to `.`, never to a path |
| `settle <pathspec list>` | settle round, review only these, the rest hold a live verdict |

## Resolving a scope into a diff command

The value is not a pathspec you can paste. Resolve it in three steps, in this order.

1. **Strip a leading `settle `.** It marks the round, it is not a path. What is left is the pathspec part.
2. **If the pathspec part is `all`, or the value was absent or empty, use `.`.** `all` is a reserved word in this grammar and never a path; it names the whole reviewed diff, which is exactly what a settle round with nothing carried over has to read. A literal `all` handed to git matches a directory called `all/`, and in a repo without one it matches nothing at all: empty output, exit 0, no error, a reviewer that read nothing and a report that says clean.
3. **Append the `docs/work/` exclusion pathspec unconditionally**, whatever step 2 produced. It is the same literal the manifest step below builds with and the FULL-round definition below repeats; copy it from either, quotes included. A bare `.` carries no exclusion of its own, so the append is never optional.

Every reviewer therefore runs one shape, `git diff {{base_sha}}..{{head_sha}} -- <resolved pathspec> <exclusion>`, where the exclusion is step 3's literal and never varies. Only the middle term moves:

| Value received | Resolved pathspec |
|---|---|
| `.` | `.` |
| `src/auth/ src/db/` | `src/auth/ src/db/` |
| `settle all` | `.` |
| `settle src/auth/` | `src/auth/` |
| absent or empty | `.` |

**Resolution rewrites the diff command and never the echo.** The echoed line is the value as received, byte for byte, `settle ` prefix and `all` included. A reviewer that echoes what it resolved to reports `Scope: settle .`, and the parent can no longer tell a settle round from an unscoped one, which is the gate at the bottom of this file failing quietly.

**A resolved command that returns no paths is an empty scope, not a clean one.** It stays reachable after step 2: a dispatcher can hand a lens a slice that turns out to hold nothing, a scope of `settle docs/work/notes.md` being the obvious one. Say so in the report. Zero findings over zero files is not a verdict and must never be counted as one.

**An absent or empty value means `.`.** This is deliberate and it is the safe direction: a dispatcher that forgets to slice buys nothing and loses nothing, because the reviewer falls back to the whole diff. A missing slice is recoverable. A silently narrowed one is not.

**On a settle round the value is never absent.** The `settle` prefix is what makes a carried-over round distinguishable from a round the dispatcher simply did not scope. Without it, "narrowed on purpose" and "never set" look identical, and a round with no scope at all could call itself FULL.

**Every reviewer echoes the value it received**, verbatim, on the first line of its report:

```
Scope: settle src/auth/ src/db/migrations/
```

That echo is what lets the parent prove the settle round was properly scoped instead of taking its own word for it.

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

**Reviewer C used to be sliced and is not on this table any more.** v0.13.0 folded it into B, so its lens inherited B's terms: it now sees the whole diff every round instead of a task-mapped slice. Coverage goes up, the wave drops a diff read, and the settle-round saving on that lens is what the merge gave back. That trade is written down here rather than left to be rediscovered from the table's missing row.

## Building the manifest

Do this once, at Phase 5 dispatch, before the message goes out. The scouts already walked the whole diff to build their tables, so the classification costs no extra reads.

1. List every changed path: `git diff --name-only <base>..<head> -- . ':(exclude)docs/work/*'`. The exclusion is load-bearing, not housekeeping; the paragraph below says why.
2. Assign each path to every lens whose surface it touches, using the table above. A path may go to several. Most go to at least two.
3. **Any path you cannot confidently classify goes to B**, which is already reading everything, so an unclassifiable file is never an uncovered file.
4. Write the scope ledger (below) into the work-doc Sprint Review.
5. Pass each reviewer its own pathspec list as `{{review_scope}}`. Pass B `.`.

**When a lens's list comes out empty, that lens has nothing to review.** Do not dispatch it, and record why in the gate line, exactly as you would for a folded lens. An empty slice is a gate decision and it is written down like one.

### Why `docs/work/` is excluded

The work-doc is the ruler the diff is measured against and cannot also be the measured. Every round writes its result into the work-doc, which changes its bytes, which kills its own verdict, which mandates another round whose result lands in the work-doc again. That loop provably cannot close; one sprint rewrote its work-doc 25 times. Nothing about the work-doc's accuracy goes unchecked, because Reviewer B still reads it in full as an INPUT and still flags any file with no authorizing task entry. The precedent is `scripts/validate-dod.d/80-file-size-caps.sh:13`, whose `CAP_SEARCH_PATHS` leaves `docs/` out for the same reason: a work log is not a primitive the caps govern.

## The scope ledger

One row per changed path. This is the artifact that makes "every file was covered" checkable instead of asserted.

```
| path | blob | lenses | round 1 | settle |
|---|---|---|---|---|
| src/auth/session.ts | a3f91c2 | A B F | clean | carried |
| src/ui/Button.tsx   | 7d20e14 | B E   | 2 findings | re-read |
```

**`blob` is `git rev-parse <head>:<path>`, the content hash, not the path.** Keying on the path alone is unsound: a file touched in round 1, fixed in round 2 and touched again would carry a verdict that was never about the bytes now on disk. The hash is the only thing that proves the reviewed content and the shipped content are the same content.

## Carrying verdicts into the settle round

A file carries its verdict into the settle round when **all** of these hold:

- a lens gave it a verdict in an earlier round of this same wave, and
- its blob hash is identical to the hash recorded with that verdict, and
- the lens is not F.

**F never carries over.** Every other lens judges a file against itself, so an unchanged file means an unchanged judgement. F judges a file against its counterparts, and a counterpart moving is enough to break coherence while both files' own hashes stay put. F re-reads its whole boundary set on every settle round, which is why `settle all` is F's normal value: `all` resolves to the whole reviewed diff, a superset of any boundary set, so no counterpart can move outside what F re-reads.

Everything that fails any of the three conditions goes back into `{{review_scope}}` and is read again.

## What a FULL round now means

The old definition was "the panel re-read every byte". The new one is:

> **every byte of the reviewed diff is covered by a live verdict, and F re-read the boundary set.**

**The reviewed diff is `git diff <base>..<head> -- . ':(exclude)docs/work/*'`**, because the work-doc is the ruler the diff is measured against and cannot also be the measured.

A verdict is live when the blob hash it was recorded against still matches the file on disk. This is a different guarantee from the old one, not a weaker one, but it is only as good as the ledger, so the ledger is mandatory whenever carry-over is used.

The parent may only declare a round FULL when every dispatched lens echoed a scope beginning with `settle `, and F's echo was `settle all`. A lens that echoed a bare pathspec list was running a middle round, and **a middle round can never close the loop** no matter how clean it came back.
